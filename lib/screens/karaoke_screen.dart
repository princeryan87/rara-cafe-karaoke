import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class KaraokeScreen extends StatefulWidget {
  final String url;
  const KaraokeScreen({super.key, required this.url});

  @override
  State<KaraokeScreen> createState() => _KaraokeScreenState();
}

class _KaraokeScreenState extends State<KaraokeScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  static const orange = Color(0xFFE85D00);
  static const dark = Color(0xFF111111);

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        // User agent desktop agar YouTube tampil versi penuh
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/120.0.0.0 Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dark,
      body: Column(
        children: [
          // ── Mini top bar saat di halaman video ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF1C0800),
            child: Row(
              children: [
                // Tombol kembali
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      border: Border.all(color: orange, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('← Kembali',
                      style: TextStyle(color: orange, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),

                const SizedBox(width: 12),

                // Label RaRa Cafe
                const Text('RaRa Cafe Karaoke',
                  style: TextStyle(
                    color: orange,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1,
                  )),

                const Spacer(),

                // Loading indicator
                if (_isLoading)
                  const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                      color: orange,
                      strokeWidth: 2,
                    ),
                  ),

                const SizedBox(width: 12),

                // Tombol refresh
                GestureDetector(
                  onTap: () => _controller.reload(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade700),
                    ),
                    child: const Text('🔄 Refresh',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),

          // ── WebView ──
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  Container(
                    color: dark,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: orange),
                          SizedBox(height: 16),
                          Text('Memuat YouTube...',
                            style: TextStyle(color: orange, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
