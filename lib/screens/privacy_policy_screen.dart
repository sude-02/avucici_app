import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: AppTheme.text(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Gizlilik Politikası',
          style: TextStyle(
              color: AppTheme.text(context), fontWeight: FontWeight.bold),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: _LegalContent(sections: _privacySections),
      ),
    );
  }
}

const _privacySections = [
  _Section(
    title: 'Son Güncelleme: Haziran 2025',
    body:
        'PalmPay olarak gizliliğinize saygı duyuyor ve kişisel verilerinizi korumayı önceliğimiz olarak kabul ediyoruz. Bu politika, uygulamanın hangi verileri nasıl işlediğini açıklar.',
    isIntro: true,
  ),
  _Section(
    title: '1. Toplanan Veriler',
    body:
        'Uygulama yalnızca aşağıdaki verileri işler:\n\n'
        '• Avuç içi görüntüleri (kayıt sırasında kamera ile alınan)\n'
        '• Bu görüntülerden türetilen matematiksel özellik vektörleri (embedding)\n'
        '• Kayıt sırasında girdiğiniz isim bilgisi\n\n'
        'Konum, kimlik, ödeme bilgisi veya iletişim verisi toplanmaz.',
  ),
  _Section(
    title: '2. Verilerin Saklanması',
    body:
        'Tüm biyometrik veriler yalnızca cihazınızdaki yerel veritabanında (SQLite) saklanır. '
        'Hiçbir veri bulut sunucusuna, üçüncü taraf hizmetine veya başka bir cihaza gönderilmez. '
        'Görüntü dosyaları yalnızca cihazınızın dahili depolamasında tutulur.',
  ),
  _Section(
    title: '3. Verilerin Kullanım Amacı',
    body:
        'Toplanan veriler yalnızca şu amaçlarla kullanılır:\n\n'
        '• Avuç içi eşleştirmesi yaparak kimlik doğrulama\n'
        '• Kayıtlı kullanıcıları yönetme\n\n'
        'Veriler reklam, profilleme veya analiz amacıyla kullanılmaz.',
  ),
  _Section(
    title: '4. Veri Paylaşımı',
    body:
        'Kişisel ve biyometrik verileriniz kesinlikle üçüncü taraflarla paylaşılmaz, '
        'satılmaz veya kiralanmaz. Uygulama internet bağlantısı gerektirmez ve '
        'herhangi bir harici servise veri göndermez.',
  ),
  _Section(
    title: '5. Biyometrik Veri Güvenliği',
    body:
        'Ham görüntüler kayıt sonrasında işlenip matematiksel vektörlere dönüştürülür. '
        'Bu vektörlerden orijinal görüntüye geri dönmek mümkün değildir. '
        'Verileriniz cihazınızın işletim sistemi güvenlik katmanları tarafından korunur.',
  ),
  _Section(
    title: '6. Haklarınız',
    body:
        '6698 sayılı KVKK kapsamında aşağıdaki haklara sahipsiniz:\n\n'
        '• Verilerinizin işlenip işlenmediğini öğrenme\n'
        '• Verilerinize erişim talep etme\n'
        '• Verilerinizin silinmesini talep etme\n\n'
        'Verilerinizi silmek için: Ayarlar → Verilerimi Sil adımlarını izleyin.',
  ),
  _Section(
    title: '7. Uygulama İzinleri',
    body:
        'Uygulama yalnızca kamera iznine ihtiyaç duyar. '
        'Bu izin, avuç içi görüntüsü almak için zorunludur. '
        'Kamera izni olmadan uygulama çalışamaz. '
        'İzni istediğiniz zaman cihaz ayarlarından iptal edebilirsiniz.',
  ),
  _Section(
    title: '8. Değişiklikler',
    body:
        'Bu politika zaman zaman güncellenebilir. '
        'Önemli değişiklikler uygulama içi bildirimle duyurulacaktır. '
        'Uygulamayı kullanmaya devam etmeniz güncel politikayı kabul ettiğiniz anlamına gelir.',
  ),
  _Section(
    title: '9. İletişim',
    body:
        'Gizlilik politikamıza ilişkin sorularınız için uygulama geliştiricisiyle iletişime geçebilirsiniz.',
  ),
];

// ─────────────────────────────────────────────

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: AppTheme.text(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kullanım Koşulları',
          style: TextStyle(
              color: AppTheme.text(context), fontWeight: FontWeight.bold),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: _LegalContent(sections: _termsSections),
      ),
    );
  }
}

const _termsSections = [
  _Section(
    title: 'Son Güncelleme: Haziran 2025',
    body:
        'PalmPay uygulamasını kullanmadan önce lütfen bu koşulları dikkatlice okuyun. '
        'Uygulamayı kullanarak bu koşulları kabul etmiş sayılırsınız.',
    isIntro: true,
  ),
  _Section(
    title: '1. Hizmetin Tanımı',
    body:
        'PalmPay, avuç içi damar izi biyometrisi kullanarak kimlik doğrulama ve ödeme simülasyonu yapan bir mobil uygulamadır. '
        'Uygulama gerçek finansal işlem gerçekleştirmez; kimlik doğrulama teknolojisini gösterme amacı taşır.',
  ),
  _Section(
    title: '2. Kullanım Koşulları',
    body:
        'Uygulamayı kullanmak için:\n\n'
        '• 18 yaşında veya daha büyük olmanız gerekmektedir\n'
        '• Kamera iznini açıkça vermiş olmanız gerekir\n'
        '• Kayıt ettiğiniz biyometrik verilerin size veya açık rızasını almış kişilere ait olması gerekir\n'
        '• Uygulamayı yalnızca yasal amaçlarla kullanmanız gerekmektedir',
  ),
  _Section(
    title: '3. Biyometrik Veri Onayı',
    body:
        'Uygulamayı kullanarak, avuç içi görüntülerinizin ve bu görüntülerden türetilen '
        'özellik vektörlerinin cihazınızda işlenmesine ve saklanmasına açıkça onay vermiş olursunuz. '
        'Bu onayı dilediğiniz zaman "Verilerimi Sil" özelliğini kullanarak geri alabilirsiniz.',
  ),
  _Section(
    title: '4. Yasaklı Kullanımlar',
    body:
        'Aşağıdaki eylemler kesinlikle yasaktır:\n\n'
        '• Başkasının biyometrik verisini rızası olmadan kaydetmek\n'
        '• Uygulamayı kimlik taklidi veya dolandırıcılık amacıyla kullanmak\n'
        '• Uygulamayı tersine mühendislik veya değiştirme girişimleri\n'
        '• Güvenlik mekanizmalarını devre dışı bırakmaya çalışmak',
  ),
  _Section(
    title: '5. Sorumluluk Reddi',
    body:
        'Uygulama "olduğu gibi" sunulmaktadır. Geliştirici şunlardan sorumlu değildir:\n\n'
        '• Biyometrik eşleştirme hataları veya yanlış tanıma\n'
        '• Cihaz kaybı veya çalınması durumunda veri erişimi\n'
        '• Üçüncü taraf yazılım veya donanım uyumsuzlukları\n'
        '• Kullanım kaynaklı dolaylı zararlar',
  ),
  _Section(
    title: '6. Fikri Mülkiyet',
    body:
        'Uygulamanın tüm kaynak kodu, tasarımı ve içeriği geliştiricisine aittir. '
        'İzinsiz kopyalama, dağıtma veya ticari kullanım yasaktır.',
  ),
  _Section(
    title: '7. Değişiklikler',
    body:
        'Bu koşullar önceden bildirim yapılarak değiştirilebilir. '
        'Güncel koşullar her zaman uygulama içinde erişilebilir olacaktır.',
  ),
  _Section(
    title: '8. Uygulanacak Hukuk',
    body:
        'Bu koşullar Türkiye Cumhuriyeti hukukuna tabidir. '
        'Anlaşmazlıklarda Türk mahkemeleri yetkilidir.',
  ),
];

// ─────────────────────────────────────────────

class _Section {
  final String title;
  final String body;
  final bool isIntro;

  const _Section({
    required this.title,
    required this.body,
    this.isIntro = false,
  });
}

class _LegalContent extends StatelessWidget {
  final List<_Section> sections;

  const _LegalContent({required this.sections});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((s) => _buildSection(context, s)).toList(),
    );
  }

  Widget _buildSection(BuildContext context, _Section s) {
    if (s.isIntro) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF7C3AED).withAlpha(51)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.title,
                style: const TextStyle(
                  color: Color(0xFF7C3AED),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.body,
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.title,
            style: TextStyle(
              color: AppTheme.text(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.body,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 14,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: AppTheme.border(context)),
        ],
      ),
    );
  }
}
