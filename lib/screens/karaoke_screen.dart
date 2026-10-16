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
  final TextEditingController _searchController = TextEditingController();

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

  // Script yang disuntik ke setiap halaman YouTube. Dipanggil di
  // onPageStarted DAN onPageFinished (dijaga flag __raraInjected supaya
  // tidak dobel) -- dipanggil sedini mungkin supaya adblock & hide-topbar
  // menang lomba lawan skrip iklan YouTube sendiri, bukan nyusul belakangan.
  static const String _injectedJs = r'''
(function () {
  if (window.__raraInjected) return;
  window.__raraInjected = true;

  // ══════════════════════════════════════════════════════════
  //  CSS INJECTION — YouTube Mobile UI Cleanup
  //  Satu blok CSS lengkap, tidak dipecah-pecah ke array.
  //  CSS-only = aman dari deteksi YouTube.
  // ══════════════════════════════════════════════════════════
  function injectCleanupStyles() {
    try {
      if (document.getElementById("__rara_cleanup__")) return;
      if (!document.head && !document.documentElement) return;
      var s = document.createElement("style");
      s.id = "__rara_cleanup__";
      s.textContent =

        // ── YouTube Mobile: header & search bar ──
        "ytm-mobile-topbar-renderer," +
        "ytm-searchbox," +
        ".mobile-topbar-header," +
        "header.mobile-topbar-header," +
        ".topbar-logo-badge," +
        ".searchbox," +
        "#search-input-form," +

        // ── YouTube Mobile: navbar bawah (Home, Shorts, You) ──
        "ytm-pivot-bar-renderer," +
        "ytm-bottom-bar-renderer," +
        ".pivot-bar-container," +
        ".bottom-bar," +
        "ytm-app > nav," +
        "nav.pivot-bar-container," +
        "ytm-app ytm-pivot-bar-renderer," +

        // ── YouTube Mobile: chip filter & mic button ──
        "ytm-chip-cloud-renderer," +
        ".chip-cloud," +
        ".searchbox-voice-button," +
        "ytm-button-renderer.searchbox-voice-button," +

        // ── YouTube Mobile: iklan ──
        "ytm-companion-ad-renderer," +
        "ytm-promoted-sparkles-renderer," +
        "ytm-promoted-video-renderer," +
        "ytm-banner-promo-renderer," +
        "ytm-statement-banner-renderer," +
        ".companion-ad-container," +
        "ytm-merch-shelf-renderer," +
        "ytm-reel-shelf-renderer," +

        // ── YouTube Desktop: masthead ──
        "ytd-masthead," +
        "#masthead-container," +
        "tp-yt-app-header#header," +
        "#masthead-ad," +

        // ── YouTube Desktop: iklan display ──
        "ytd-display-ad-renderer," +
        "ytd-promoted-sparkles-web-renderer," +
        "ytd-promoted-video-renderer," +
        "ytd-in-feed-ad-layout-renderer," +
        "ytd-ad-slot-renderer," +
        "ytd-merch-shelf-renderer," +
        "ytd-reel-shelf-renderer," +

        // ── Player ads overlay ──
        ".ytp-ad-player-overlay," +
        ".ytp-ad-player-overlay-instream-info," +
        ".ytp-ad-image-overlay," +
        ".ytp-ad-text-overlay," +
        ".ytp-suggested-action," +
        ".ytp-visit-advertiser-link" +

        // ── Tutup semua selector di atas ──
        "{ display: none !important; }" +

        // ── Fix margin/padding setelah elemen disembunyikan ──
        // Mobile: konten naik ke atas
        "ytm-app { padding-top: 0 !important; }" +
        ".page-container { padding-top: 0 !important; }" +
        "ytm-app > .app-container { padding-top: 0 !important; }" +

        // Desktop
        "ytd-app, #page-manager, ytd-page-manager { margin-top: 0 !important; padding-top: 0 !important; }" +
        "html { --ytd-masthead-height: 0px !important; }";

      (document.head || document.documentElement).appendChild(s);
    } catch (e) {}
  }

  // ── Auto-klik tombol Skip Ad ──
  function autoSkipAds() {
    try {
      var skipSelectors = [
        ".ytp-ad-skip-button",
        ".ytp-skip-ad-button",
        ".ytp-ad-skip-button-modern",
        ".ytp-ad-skip-button-container button",
        ".skip-button",
        "ytm-skip-button-renderer button"
      ];
      for (var i = 0; i < skipSelectors.length; i++) {
        var btn = document.querySelector(skipSelectors[i]);
        if (btn) { btn.click(); break; }
      }
      var overlayClose = document.querySelector(
        ".ytp-ad-overlay-close-button,.ytp-ad-feedback-dialog-container button"
      );
      if (overlayClose) overlayClose.click();
    } catch (e) {}
  }

  // ── Sembunyikan popup promosi berdasarkan teks ──
  var PROMO_TEXTS = [
    "YouTube Premium","YouTube Music","Try Premium",
    "No thanks","Music discovery","Check it out"
  ];
  function hidePromoDialogs() {
    try {
      var els = document.querySelectorAll(
        "tp-yt-paper-dialog,ytd-popup-container,[role='dialog']," +
        "ytm-mealbar-promo-renderer,.ytp-suggested-action,ytm-companion-ad-renderer"
      );
      for (var i = 0; i < els.length; i++) {
        var text = els[i].textContent || "";
        for (var j = 0; j < PROMO_TEXTS.length; j++) {
          if (text.indexOf(PROMO_TEXTS[j]) !== -1) {
            els[i].style.display = "none"; break;
          }
        }
      }
    } catch (e) {}
  }

  // ── Tombol "+ Tambah ke Antrian" di halaman video ──
  function isWatchPage() { return location.pathname === "/watch"; }

  function getVideoInfo() {
    var title = document.title.replace(/ - YouTube$/, "").trim();
    return { title: title || "Tanpa judul", url: location.href };
  }

  function injectQueueButton() {
    try {
      if (document.getElementById("__rara_queue_btn__")) return;
      var btn = document.createElement("button");
      btn.id = "__rara_queue_btn__";
      btn.textContent = "+ Tambah ke Antrian";
      btn.style.cssText =
        "position:fixed;top:16px;right:16px;z-index:999999;" +
        "padding:10px 18px;border-radius:24px;border:none;" +
        "background:linear-gradient(135deg,#e85d00,#ff8c00);color:#111;" +
        "font-size:13px;font-weight:700;font-family:sans-serif;cursor:pointer;" +
        "box-shadow:0 4px 16px rgba(232,93,0,0.6);";
      btn.addEventListener("click", function () {
        var info = getVideoInfo();
        RaraQueueBridge.postMessage(
          JSON.stringify({ type: "add-to-queue", title: info.title, url: info.url })
        );
        btn.textContent = "✓ Ditambahkan";
        setTimeout(function () { btn.textContent = "+ Tambah ke Antrian"; }, 1500);
      });
      document.body.appendChild(btn);
    } catch (e) {}
  }

  function attachVideoEndedListener() {
    try {
      var video = document.querySelector("video");
      if (!video || video.__raraEndedAttached) return;
      video.__raraEndedAttached = true;
      video.addEventListener("ended", function () {
        RaraQueueBridge.postMessage(JSON.stringify({ type: "video-ended" }));
      });
    } catch (e) {}
  }

  function checkAndInject() {
    try {
      var existing = document.getElementById("__rara_queue_btn__");
      if (isWatchPage()) {
        injectQueueButton();
        attachVideoEndedListener();
      } else if (existing) {
        existing.remove();
      }
    } catch (e) {}
  }

  // ── SPA navigation listener ──
  var lastUrl = location.href;
  setInterval(function () {
    if (location.href !== lastUrl) {
      lastUrl = location.href;
      var old = document.getElementById("__rara_cleanup__");
      if (old) old.remove();
      window.__raraInjected = false;
      setTimeout(function () {
        injectCleanupStyles();
        checkAndInject();
      }, 600);
    }
  }, 500);

  // ── Polling berkala ──
  setInterval(injectCleanupStyles, 800);
  setInterval(autoSkipAds, 800);
  setInterval(hidePromoDialogs, 1200);
  setInterval(function () {
    if (isWatchPage()) attachVideoEndedListener();
  }, 2000);

  // ── Jalankan langsung ──
  injectCleanupStyles();
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
        // UA Chrome Android — natural untuk WebView di Android & TV
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/120.0.6099.230 Mobile Safari/537.36',
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
          onPageStarted: (_) {
            setState(() => _isLoading = true);
            // Suntik sedini mungkin (adblock & hide-topbar balapan lawan
            // skrip YouTube sendiri) -- aman dipanggil di sini karena
            // seluruh isi script dibungkus try/catch & dicoba ulang
            // berkala kalau document belum siap.
            _controller.runJavaScript(_injectedJs);
          },
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
          // Ada lagu berikutnya → putar otomatis
          final next = queue.first;
          await QueueService.removeAt(0);
          await _refreshQueueCount();
          _controller.loadRequest(Uri.parse(next.url));
        } else {
          // Antrian kosong → kembali ke home screen
          if (mounted) Navigator.pop(context);
        }
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

  void _doSearch() {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    final url = 'https://www.youtube.com/results?search_query=' +
        Uri.encodeComponent('$q karaoke');
    setState(() => _isLoading = true);
    _controller.loadRequest(Uri.parse(url));
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
            color: AppConfig.darkOrange,
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

                const SizedBox(width: 10),

                // Search box -- gantinya search box YouTube yang kita
                // sembunyikan (poin #1 & #4)
                Expanded(
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppConfig.searchBoxBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: orange.withOpacity(0.6), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: (_) => _doSearch(),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'Cari lagu karaoke...',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _doSearch,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text('🔍', style: TextStyle(fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Loading indicator
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                        color: orange,
                        strokeWidth: 2,
                      ),
                    ),
                  ),

                // Antrian + Refresh -- dibungkus Flexible+FittedBox
                // supaya tidak pernah ke-clip di layar sempit (sama
                // pendekatan seperti perbaikan home_screen.dart).
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        GestureDetector(
                          onTap: () => _controller.reload(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppConfig.darkCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade700),
                            ),
                            child: const Text('🔄',
                              style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
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
