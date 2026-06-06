import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class CaptureResult {
  final List<double> embedding;
  final List<double> flippedEmbedding;
  final String imagePath;

  CaptureResult({
    required this.embedding,
    required this.flippedEmbedding,
    required this.imagePath,
  });
}

class CameraService {
  CameraController? _controller;
  Interpreter? _interpreter;
  bool _isInitialized = false;
  bool _flashEnabled = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get flashEnabled => _flashEnabled;

  Future<void> initialize() async {
    await _initCamera();
    await _initModel();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);
      _isInitialized = true;
    } catch (e) {
      print('Kamera hatası: $e');
    }
  }

  Future<void> _initModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
          'assets/models/avucici_model.tflite');
    } catch (e) {
      print('Model yükleme hatası: $e');
    }
  }

  Future<void> toggleFlash() async {
    if (_controller == null || !_isInitialized) return;
    _flashEnabled = !_flashEnabled;
    await _controller!.setFlashMode(
      _flashEnabled ? FlashMode.torch : FlashMode.off,
    );
  }

  Future<void> setFlash(bool enabled) async {
    if (_controller == null || !_isInitialized) return;
    _flashEnabled = enabled;
    await _controller!.setFlashMode(
      enabled ? FlashMode.torch : FlashMode.off,
    );
  }

  Future<CaptureResult?> captureAndExtractEmbedding() async {
    if (!_isInitialized || _controller == null || _interpreter == null) {
      return null;
    }
    try {
      final xFile = await _controller!.takePicture();
      final bytes = await File(xFile.path).readAsBytes();

      img.Image? fullImage = img.decodeImage(bytes);
      if (fullImage == null) return null;

      // Merkez kare kırp → 224x224
      final roiImage = _cropCenter(fullImage, 224);

      // ROI kaydet
      final dir = await getApplicationDocumentsDirectory();
      final roiDir = Directory('${dir.path}/rois');
      if (!roiDir.existsSync()) roiDir.createSync(recursive: true);
      final roiPath =
          '${roiDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      File(roiPath).writeAsBytesSync(img.encodeJpg(roiImage, quality: 90));

      // Normal embedding
      final embedding = _runModel(roiImage);

      // Yatay çevrilmiş embedding (diğer el tespiti için)
      final flippedImage = img.flipHorizontal(roiImage);
      final flippedEmbedding = _runModel(flippedImage);

      return CaptureResult(
        embedding: embedding,
        flippedEmbedding: flippedEmbedding,
        imagePath: roiPath,
      );
    } catch (e) {
      print('Embedding hatası: $e');
      return null;
    }
  }

  List<double> _runModel(img.Image image) {
    final input = _imageToInput(image);
    final output = List.filled(512, 0.0).reshape([1, 512]);
    _interpreter!.run(input, output);
    return List<double>.from(output[0]);
  }

  img.Image _cropCenter(img.Image image, int size) {
    final minDim = image.width < image.height ? image.width : image.height;
    final x = (image.width - minDim) ~/ 2;
    final y = (image.height - minDim) ~/ 2;
    final cropped =
        img.copyCrop(image, x: x, y: y, width: minDim, height: minDim);
    return img.copyResize(cropped, width: size, height: size);
  }

  List<List<List<List<double>>>> _imageToInput(img.Image image) {
    return List.generate(1, (_) =>
      List.generate(224, (y) =>
        List.generate(224, (x) {
          final pixel = image.getPixel(x, y);
          return [
            (pixel.r / 255.0 - 0.485) / 0.229,
            (pixel.g / 255.0 - 0.456) / 0.224,
            (pixel.b / 255.0 - 0.406) / 0.225,
          ];
        })
      )
    );
  }

  void dispose() {
    _controller?.dispose();
    _interpreter?.close();
  }
}