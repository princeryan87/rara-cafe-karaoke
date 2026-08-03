import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config.dart';
import '../services/queue_service.dart';
import '../services/kiosk_service.dart';
import '../widgets/queue_dialog.dart';
import 'karaoke_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  int _queueCount = 0;

  // Warna tema -- sumbernya dari config.dart, JANGAN edit di sini.
  // Ganti branding/warna lewat lib/config.dart.
  static const orange = AppConfig.orange;
  static const orangeLight = AppConfig.orangeLight;
  static const gold = AppConfig.gold;
  static const dark = AppConfig.dark;
  static const darkCard = AppConfig.darkCard;
  static const darkOrange = AppConfig.darkOrange;

  final List<Map<String, String>> _quickButtons = [
    {'label': '🔥 Karaoke Populer', 'url': 'https://www.youtube.com/results?search_query=karaoke+indonesia+terbaik+2024'},
    {'label': '🎵 Tanpa Vokal', 'url': 'https://www.youtube.com/results?search_query=karaoke+no+vocal+terpopuler'},
    {'label': '📀 Lagu Lawas', 'url': 'https://www.youtube.com/results?search_query=karaoke+pop+indonesia+lama'},
  ];

  final List<Map<String, String>> _navButtons = [
    {'label': '🇮🇩 Indonesia', 'url': 'https://www.youtube.com/results?search_query=karaoke+indonesia+terpopuler'},
    {'label': '🌍 English', 'url': 'https://www.youtube.com/results?search_query=karaoke+english+popular'},
    {'label': '🎶 Dangdut', 'url': 'https://www.youtube.com/results?search_query=karaoke+dangdut'},
  ];

  final List<String> _tags = [
    'Dewa 19', 'Noah', 'Sheila On 7', 'Westlife',
    'Ed Sheeran', 'Raisa', 'Avril Lavigne',
    'Coldplay', 'Judika', 'Queen',
  ];

  @override
  void initState() {
    super.initState();
    _refreshQueueCount();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  Future<void> _refreshQueueCount() async {
    final queue = await QueueService.getQueue();
    if (!mounted) return;
    setState(() => _queueCount = queue.length);
  }

  void _openQueueDialog() {
    showQueueDialog(
      context,
      onPlay: (item) => _openKaraoke(item.url),
    ).then((_) => _refreshQueueCount());
  }

  @override
  void dispose() {
    _glowController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openKaraoke(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => KaraokeScreen(url: url)),
    ).then((_) => _refreshQueueCount());
  }

  void _doSearch() {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    final url = 'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$q karaoke')}';
    _openKaraoke(url);
  }

  void _showPowerDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1C0800), Color(0xFF111111)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: orange, width: 2),
            boxShadow: [
              BoxShadow(color: orange.withOpacity(0.3), blurRadius: 40),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⏻', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('Pilih Opsi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Pilih tindakan yang ingin dilakukan',
                style: TextStyle(color: gold, fontSize: 13)),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Keluar App (Android tidak bisa shutdown langsung)
                  _powerBtn('🔴', 'Keluar', const Color(0xFFDC2626), () async {
                    Navigator.pop(context);
                    await KioskService.stopKiosk();
                    SystemNavigator.pop(); // Keluar dari app
                  }),
                  const SizedBox(width: 12),
                  // Batal
                  _powerBtn('✕', 'Batal', darkCard, () => Navigator.pop(context),
                    textColor: gold, border: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _powerBtn(String icon, String label, Color bg, VoidCallback onTap,
      {Color textColor = Colors.white, bool border = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: border ? Border.all(color: orange, width: 1.5) : null,
          boxShadow: border ? [] : [BoxShadow(color: bg.withOpacity(0.4), blurRadius: 16)],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTV = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: dark,
      body: Stack(
        children: [
          // ── Logo background fullscreen (cover, opacity 30%) ──
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                AppConfig.logoAssetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Konten utama (di atas background) ──
          Column(
            children: [
              // ── TOP BAR ──
              _buildTopBar(isTV),

              // ── HOME CONTENT ──
              // FittedBox (bukan scroll) -- seluruh konten didesain di
              // lebar acuan 900, lalu otomatis di-scale mengecil kalau
              // ruang layar lebih kecil (HP landscape kecil) supaya
              // SELALU pas dalam satu layar, tidak pernah kepotong dan
              // tidak pernah perlu digeser/scroll. Di layar besar (TV)
              // otomatis tidak diperbesar berlebihan (scaleDown = hanya
              // mengecil, tidak pernah membesar melebihi ukuran asli).
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 900,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 20),
                          // Branding tengah
                          _buildCenterLogo(isTV),
                          const SizedBox(height: 28),
                          // Quick buttons
                          _buildQuickButtons(isTV),
                          const SizedBox(height: 20),
                          // Tag cloud
                          _buildTagCloud(isTV),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isTV) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isTV ? 10 : 8),
      decoration: BoxDecoration(
        color: const Color(0xFF140A05).withOpacity(0.5),
        border: const Border(bottom: BorderSide(color: Color(0xFFE85D00), width: 2)),
      ),
      child: Row(
        children: [
          // Logo kecil + nama
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(AppConfig.logoAssetPath,
                  width: isTV ? 48 : 38,
                  height: isTV ? 48 : 38,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                    const Icon(Icons.local_cafe, color: orange, size: 38),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppConfig.brandName,
                    style: TextStyle(
                      color: orange,
                      fontSize: isTV ? 16 : 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    )),
                  Text(AppConfig.subBrand.toUpperCase(),
                    style: TextStyle(
                      color: gold,
                      fontSize: isTV ? 10 : 9,
                      letterSpacing: 3,
                    )),
                ],
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Search bar
          Expanded(
            flex: 2,
            child: Container(
              height: isTV ? 44 : 38,
              decoration: BoxDecoration(
                color: const Color(0xFF1C0800),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: orange, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Cari lagu karaoke...',
                        hintStyle: TextStyle(color: Color(0x66C2A06A)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _doSearch(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _doSearch,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE85D00), Color(0xFFFF8C00)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text('🔍 Cari',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: isTV ? 14 : 13,
                          )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Nav pills + Antrian -- dibungkus Flexible+FittedBox supaya
          // TIDAK PERNAH ke-clip/hilang di layar sempit (HP landscape).
          // Kalau tidak cukup ruang, semuanya otomatis mengecil bareng,
          // BUKAN kepotong keluar layar.
          Flexible(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._navButtons.map((btn) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _navPill(btn['label']!, btn['url']!, isTV),
                  )),
                  const SizedBox(width: 6),
                  // Tombol antrian
                  GestureDetector(
                    onTap: _openQueueDialog,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTV ? 14 : 10,
                        vertical: isTV ? 8 : 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: orange, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🎵 Antrian',
                            style: TextStyle(
                              color: orange,
                              fontSize: isTV ? 13 : 11,
                              fontWeight: FontWeight.w600,
                            )),
                          if (_queueCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: orangeLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('$_queueCount',
                                style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Power button -- SENGAJA di luar FittedBox, selalu ukuran
          // penuh & mudah dipencet (kontrol paling penting).
          GestureDetector(
            onTap: _showPowerDialog,
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade700, width: 2),
              ),
              child: const Center(
                child: Text('⏻', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navPill(String label, String url, bool isTV) {
    return GestureDetector(
      onTap: () => _openKaraoke(url),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTV ? 14 : 10,
          vertical: isTV ? 8 : 6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: orange, width: 1.5),
        ),
        child: Text(label,
          style: TextStyle(
            color: orange,
            fontSize: isTV ? 13 : 11,
            fontWeight: FontWeight.w600,
          )),
      ),
    );
  }

  Widget _buildCenterLogo(bool isTV) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (_, child) {
        return Column(
          children: [
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${AppConfig.brandName}\n',
                    style: TextStyle(
                      color: orange,
                      fontSize: isTV ? 40 : 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      height: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: AppConfig.subBrand,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTV ? 36 : 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 80, height: 3,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.transparent, orange, Colors.transparent],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            Text(AppConfig.tagline,
              style: TextStyle(
                color: gold,
                fontSize: isTV ? 14 : 12,
                letterSpacing: 3,
              )),
          ],
        );
      },
    );
  }

  Widget _buildQuickButtons(bool isTV) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: _quickButtons.map((btn) {
        final isPrimary = btn['label']!.startsWith('🔥');
        return GestureDetector(
          onTap: () => _openKaraoke(btn['url']!),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTV ? 28 : 20,
              vertical: isTV ? 14 : 12,
            ),
            decoration: BoxDecoration(
              gradient: isPrimary
                ? const LinearGradient(colors: [Color(0xFFE85D00), Color(0xFFFF8C00)])
                : null,
              color: isPrimary ? null : darkCard,
              borderRadius: BorderRadius.circular(30),
              border: isPrimary ? null : Border.all(color: orange, width: 1.5),
              boxShadow: isPrimary
                ? [BoxShadow(color: orange.withOpacity(0.4), blurRadius: 16)]
                : [],
            ),
            child: Text(btn['label']!,
              style: TextStyle(
                color: isPrimary ? Colors.black : orange,
                fontSize: isTV ? 15 : 13,
                fontWeight: FontWeight.bold,
              )),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTagCloud(bool isTV) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTV ? 60 : 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: _tags.map((tag) {
          return GestureDetector(
            onTap: () {
              _searchController.text = tag;
              _doSearch();
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTV ? 18 : 14,
                vertical: isTV ? 9 : 7,
              ),
              decoration: BoxDecoration(
                color: darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: Text(tag,
                style: TextStyle(
                  color: gold,
                  fontSize: isTV ? 14 : 12,
                )),
            ),
          );
        }).toList(),
      ),
    );
  }
}
