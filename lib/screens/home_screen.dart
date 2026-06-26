import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Warna tema
  static const orange = Color(0xFFE85D00);
  static const orangeLight = Color(0xFFFF8C00);
  static const gold = Color(0xFFC2A06A);
  static const dark = Color(0xFF111111);
  static const darkCard = Color(0xFF1A1A1A);
  static const darkOrange = Color(0xFF1C0800);

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
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
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
    );
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
                  _powerBtn('🔴', 'Keluar', const Color(0xFFDC2626), () {
                    Navigator.pop(context);
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
      body: Column(
        children: [
          // ── TOP BAR ──
          _buildTopBar(isTV),

          // ── HOME CONTENT ──
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Logo tengah
                  _buildCenterLogo(isTV),
                  const SizedBox(height: 28),
                  // Quick buttons
                  _buildQuickButtons(isTV),
                  const SizedBox(height: 20),
                  // Tag cloud
                  _buildTagCloud(isTV),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isTV) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isTV ? 10 : 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1C0800), Color(0xFF111111)],
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFE85D00), width: 2)),
      ),
      child: Row(
        children: [
          // Logo kecil + nama
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('assets/logo.png',
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
                  Text('RaRa Cafe',
                    style: TextStyle(
                      color: orange,
                      fontSize: isTV ? 16 : 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    )),
                  Text('KARAOKE',
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

          // Nav pills
          ..._navButtons.map((btn) => Padding(
            padding: const EdgeInsets.only(left: 6),
            child: _navPill(btn['label']!, btn['url']!, isTV),
          )),

          const SizedBox(width: 10),

          // Power button
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
    final logoSize = isTV ? 160.0 : 120.0;
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (_, child) {
        return Column(
          children: [
            Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: orange.withOpacity(_glowAnimation.value * 0.6),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: orangeLight.withOpacity(_glowAnimation.value * 0.3),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: darkOrange,
                    child: Icon(Icons.local_cafe,
                      color: orange, size: logoSize * 0.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'RaRa Cafe\n',
                    style: TextStyle(
                      color: orange,
                      fontSize: isTV ? 40 : 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      height: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: 'Karaoke',
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
            Text('✦ Nyanyikan Hati Anda ✦',
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
