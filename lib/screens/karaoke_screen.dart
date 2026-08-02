import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config.dart';
import '../services/queue_service.dart';
import '../widgets/queue_dialog.dart';

class KaraokeScreen extends StatefulWidget {
  final String url;
  const KaraokeScreen({super.key, required this.url});

  @override
  State<KaraokeScreen> createState() => _KaraokeScreenState();
}

class _KaraokeScreenState extends State<KaraokeScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _queueCount = 0;

  static const orange = AppConfig.orange;
  static const dark = AppConfig.dark;

  // ── Domain-lock: webview cuma boleh navigasi ke domain ini ──
  static const List<String> _allowedDomains = [
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'googlevideo.com',
    'ytimg.com',
    'ggpht.com',
    'consent.youtube.com',
    'accounts.google.com',
  ];

  bool _isAllowedDomain(String urlString) {
    try {
      final host = Uri.parse(urlString).host;
      if (host.isEmpty) return true; // about:blank dkk
      return _allowedDomains.any((d) => host == d || host.endsWith('.$d'));
    } catch (_) {
      return false;
    }
  }

  // Script yang disuntik ke setiap halaman YouTube: tombol mengambang
  // "+ Tambah ke Antrian" di halaman video, + deteksi video selesai
  // untuk auto-play lagu berikutnya di antrian.
  static const String _injectedJs = r'''
(function () {
  if (window.__raraInjected) return;
  window.__raraInjected = true;

  // ── Adblock: blokir fetch()/XHR ke domain iklan dari DALAM halaman ──
  // Ini bukan blokir level jaringan/OS (webview_flutter tidak menyediakan
  // hook ke situ tanpa fork plugin) -- ini "monkey-patch" fetch & XHR
  // milik JAVASCRIPT HALAMAN ITU SENDIRI, jadi permintaan ke domain
  // iklan gagal SEBELUM sempat dikirim. Efektif untuk sebagian besar
  // permintaan iklan berbasis fetch/XHR, meski tidak 100% (request lewat
  // <script src> atau <iframe src> langsung tidak tertangkap cara ini,
  // makanya dikombinasi dengan CSS hiding + auto-skip di bawah).
  var AD_DOMAINS = [
    "doubleclick.net", "googlesyndication.com", "googleadservices.com",
    "google-analytics.com", "adservice.google.com", "imasdk.googleapis.com",
    "googleads.g.doubleclick.net"
  ];
  function isAdUrl(url) {
    if (!url) return false;
    return AD_DOMAINS.some(function (d) { return url.indexOf(d) !== -1; });
  }
  try {
    var originalFetch = window.fetch;
    window.fetch = function (input) {
      var url = typeof input === "string" ? input : (input && input.url) || "";
      if (isAdUrl(url)) return Promise.reject(new Error("blocked-by-adblock"));
      return originalFetch.apply(this, arguments);
    };
    var originalOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function (method, url) {
      if (isAdUrl(url)) throw new Error("blocked-by-adblock");
      return originalOpen.apply(this, arguments);
    };
  } catch (e) {}

  // ── Sembunyikan elemen "Sponsored" / iklan tampilan ──
  function hideAdElements() {
    if (document.getElementById("__rara_adblock_style__")) return;
    var style = document.createElement("style");
    style.id = "__rara_adblock_style__";
    style.textContent =
      "ytd-display-ad-renderer,ytd-promoted-sparkles-web-renderer," +
      "ytd-promoted-video-renderer,ytd-in-feed-ad-layout-renderer," +
      "ytd-ad-slot-renderer,ytd-companion-slot-renderer," +
      "ytd-action-companion-ad-renderer,ytd-statement-banner-renderer," +
      "ytd-banner-promo-renderer,ytd-mealbar-promo-renderer,#masthead-ad," +
      ".ytp-ad-overlay-container,.ytp-ad-image-overlay{display:none !important;}";
    (document.head || document.documentElement).appendChild(style);
  }

  // ── Auto-skip iklan video begitu tombol "Skip Ad" muncul ──
  function autoSkipAds() {
    try {
      var skipBtn = document.querySelector(
        ".ytp-ad-skip-button, .ytp-skip-ad-button, .ytp-ad-skip-button-modern, .ytp-ad-skip-button-container button"
      );
      if (skipBtn) skipBtn.click();
      var overlayCloseBtn = document.querySelector(".ytp-ad-overlay-close-button");
      if (overlayCloseBtn) overlayCloseBtn.click();
    } catch (e) {}
  }

  function isWatchPage() {
    return location.pathname === "/watch";
  }

  function getVideoInfo() {
    var title = document.title.replace(/ - YouTube$/, "").trim();
    return { title: title || "Tanpa judul", url: location.href };
  }

  function injectQueueButton() {
    if (document.getElementById("__rara_queue_btn__")) return;
    var btn = document.createElement("button");
    btn.id = "__rara_queue_btn__";
    btn.textContent = "+ Tambah ke Antrian";
    btn.style.cssText = "position:fixed;bottom:24px;right:24px;z-index:999999;" +
      "padding:14px 22px;border-radius:30px;border:none;" +
      "background:linear-gradient(135deg,#e85d00,#ff8c00);color:#111;" +
      "font-size:14px;font-weight:700;font-family:sans-serif;cursor:pointer;" +
      "box-shadow:0 4px 20px rgba(232,93,0,0.6);";
    btn.addEventListener("click", function () {
      var info = getVideoInfo();
      RaraQueueBridge.postMessage(JSON.stringify({ type: "add-to-queue", title: info.title, url: info.url }));
      btn.textContent = "✓ Ditambahkan";
      setTimeout(function () { btn.textContent = "+ Tambah ke Antrian"; }, 1500);
    });
    document.body.appendChild(btn);
  }

  function attachVideoEndedListener() {
    var video = document.querySelector("video");
    if (!video || video.__raraEndedAttached) return;
    video.__raraEndedAttached = true;
    video.addEventListener("ended", function () {
      RaraQueueBridge.postMessage(JSON.stringify({ type: "video-ended" }));
    });
  }

  function checkAndInject() {
    var existing = document.getElementById("__rara_queue_btn__");
    if (isWatchPage()) {
      injectQueueButton();
      attachVideoEndedListener();
    } else if (existing) {
      existing.remove();
    }
  }

  var lastUrl = location.href;
  setInterval(function () {
    if (location.href !== lastUrl) {
      lastUrl = location.href;
      setTimeout(checkAndInject, 800);
    }
  }, 500);

  setInterval(function () {
    if (isWatchPage()) attachVideoEndedListener();
  }, 2000);

  setInterval(hideAdElements, 1000);
  setInterval(autoSkipAds, 800);
  hideAdElements();

  setTimeout(checkAndInject, 800);
})();
''';

  @override
  void initState() {
    super.initState();
    _refreshQueueCount();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        // User agent desktop agar YouTube tampil versi penuh
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/120.0.0.0 Safari/537.36',
      )
      ..addJavaScriptChannel(
        'RaraQueueBridge',
        onMessageReceived: _handleBridgeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (_isAllowedDomain(request.url)) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) {
            setState(() => _isLoading = false);
            _controller.runJavaScript(_injectedJs);
          },
          onWebResourceError: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _refreshQueueCount() async {
    final queue = await QueueService.getQueue();
    if (!mounted) return;
    setState(() => _queueCount = queue.length);
  }

  void _handleBridgeMessage(JavaScriptMessage message) async {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'add-to-queue') {
        await QueueService.addToQueue(QueueItem(
          title: data['title'] as String? ?? 'Tanpa judul',
          url: data['url'] as String? ?? '',
        ));
        await _refreshQueueCount();
      } else if (type == 'video-ended') {
        final queue = await QueueService.getQueue();
        if (queue.isNotEmpty) {
          final next = queue.first;
          await QueueService.removeAt(0);
          await _refreshQueueCount();
          _controller.loadRequest(Uri.parse(next.url));
        }
        // Kalau antrian kosong, biarkan YouTube lanjut normal (autoplay
        // bawaan dia) -- sama seperti perilaku versi Windows.
      }
    } catch (_) {
      // Diamkan -- pesan tidak valid, tidak perlu crash aplikasi
    }
  }

  void _openQueueDialog() {
    showQueueDialog(
      context,
      onPlay: (item) {
        _controller.loadRequest(Uri.parse(item.url));
        _refreshQueueCount();
      },
    ).then((_) => _refreshQueueCount());
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

                // Label brand
                Text(AppConfig.fullTitle,
                  style: TextStyle(
                    color: orange,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1,
                  )),

                const Spacer(),

                // Loading indicator
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                        color: orange,
                        strokeWidth: 2,
                      ),
                    ),
                  ),

                // Tombol antrian
                GestureDetector(
                  onTap: _openQueueDialog,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      border: Border.all(color: orange, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎵 Antrian',
                          style: TextStyle(color: orange, fontSize: 12, fontWeight: FontWeight.bold)),
                        if (_queueCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppConfig.orangeLight,
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
