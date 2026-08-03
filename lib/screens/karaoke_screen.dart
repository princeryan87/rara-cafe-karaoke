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

  // ── Adblock: blokir fetch()/XHR ke domain iklan dari DALAM halaman ──
  // Bukan blokir level jaringan/OS (webview_flutter tidak menyediakan hook
  // ke situ tanpa fork plugin) -- ini "monkey-patch" fetch & XHR milik
  // JAVASCRIPT HALAMAN ITU SENDIRI, jadi permintaan ke domain iklan gagal
  // SEBELUM sempat dikirim. Tidak 100% (request lewat <script src> atau
  // <iframe src> langsung tidak tertangkap), makanya dikombinasi CSS
  // hiding + auto-skip di bawah.
  var AD_DOMAINS = [
    "doubleclick.net", "googlesyndication.com", "googleadservices.com",
    "google-analytics.com", "adservice.google.com", "imasdk.googleapis.com",
    "googleads.g.doubleclick.net", "static.doubleclick.net"
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

  // ── Sembunyikan topbar YouTube (logo, search box, sign-in) ──
  // Supaya yang terlihat cuma topbar aplikasi kita. Dibuat tahan-banting
  // (try/catch + dicoba berkala) -- kalau document belum siap saat
  // dipanggil pertama kali, dicoba lagi di tick interval berikutnya.
  function hideYoutubeTopbar() {
    try {
      if (document.getElementById("__rara_hide_topbar_style__")) return;
      if (!document.head && !document.documentElement) return;
      var style = document.createElement("style");
      style.id = "__rara_hide_topbar_style__";
      style.textContent =
        "ytd-masthead,#masthead-container,tp-yt-app-header#header{display:none !important;}" +
        "html{--ytd-masthead-height:0px !important;}" +
        "ytd-app,#page-manager,ytd-page-manager{margin-top:0 !important;padding-top:0 !important;}";
      (document.head || document.documentElement).appendChild(style);
    } catch (e) {}
  }

  // ── Sembunyikan elemen "Sponsored" / iklan tampilan ──
  function hideAdElements() {
    try {
      if (document.getElementById("__rara_adblock_style__")) return;
      if (!document.head && !document.documentElement) return;
      var style = document.createElement("style");
      style.id = "__rara_adblock_style__";
      style.textContent =
        "ytd-display-ad-renderer,ytd-promoted-sparkles-web-renderer," +
        "ytd-promoted-video-renderer,ytd-in-feed-ad-layout-renderer," +
        "ytd-ad-slot-renderer,ytd-companion-slot-renderer," +
        "ytd-action-companion-ad-renderer,ytd-statement-banner-renderer," +
        "ytd-banner-promo-renderer,ytd-mealbar-promo-renderer,ytd-merch-shelf-renderer," +
        "ytd-primetime-promo-renderer,ytm-companion-ad-renderer,#masthead-ad," +
        "#player-ads,.ytp-ad-player-overlay,.ytp-ad-player-overlay-instream-info," +
        "[class*=\"shopping\" i],[id*=\"shopping\" i],.ytp-suggested-action," +
        ".ytp-visit-advertiser-link,.ytp-suggestion-set," +
        "[class*=\"ytp-ad-\"]:not(.ytp-ad-skip-button):not(.ytp-ad-skip-button-modern):not(.ytp-skip-ad-button)" +
        "{display:none !important;}";
      (document.head || document.documentElement).appendChild(style);
    } catch (e) {}
  }

  // ── Sembunyikan dialog/overlay promosi berdasarkan TEKS ──
  // Nama class elemen promo YouTube (mis. "Music discovery made easy",
  // "View products") sering berubah-ubah, jadi lebih tahan lama kalau
  // dideteksi dari isi teksnya, bukan cuma nama class/tag.
  var PROMO_PHRASES = [
    "Music discovery made easy",
    "View products",
    "Check it out",
    "YouTube Music",
    "Try YouTube Premium",
    "No thanks"
  ];
  function hidePromoByText() {
    try {
      var candidates = document.querySelectorAll(
        'tp-yt-paper-dialog, ytd-popup-container, [role="dialog"], ytd-mealbar-promo-renderer, ' +
        '.ytp-suggested-action, .ytp-ce-element, [class*="shopping" i]'
      );
      for (var i = 0; i < candidates.length; i++) {
        var el = candidates[i];
        var text = el.textContent || "";
        for (var j = 0; j < PROMO_PHRASES.length; j++) {
          if (text.indexOf(PROMO_PHRASES[j]) !== -1) {
            el.style.display = "none";
            break;
          }
        }
      }
    } catch (e) {}
  }

  // ── Auto-skip iklan video begitu tombol "Skip Ad" muncul ──
  function autoSkipAds() {
    try {
      var skipBtn = document.querySelector(
        ".ytp-ad-skip-button, .ytp-skip-ad-button, .ytp-ad-skip-button-modern, .ytp-ad-skip-button-container button"
      );
      if (skipBtn) skipBtn.click();
      var overlayCloseBtn = document.querySelector(".ytp-ad-overlay-close-button, .ytp-ad-feedback-dialog-container button");
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

  // Tombol "+ Tambah ke Antrian" ditaruh di POJOK KANAN ATAS (bukan
  // kanan bawah) -- supaya tidak menutupi tombol fullscreen / kontrol
  // player YouTube yang selalu ada di bagian bawah, baik mode normal
  // maupun fullscreen.
  function injectQueueButton() {
    try {
      if (document.getElementById("__rara_queue_btn__")) return;
      var btn = document.createElement("button");
      btn.id = "__rara_queue_btn__";
      btn.textContent = "+ Tambah ke Antrian";
      btn.style.cssText = "position:fixed;top:16px;right:16px;z-index:999999;" +
        "padding:10px 18px;border-radius:24px;border:none;" +
        "background:linear-gradient(135deg,#e85d00,#ff8c00);color:#111;" +
        "font-size:13px;font-weight:700;font-family:sans-serif;cursor:pointer;" +
        "box-shadow:0 4px 16px rgba(232,93,0,0.6);opacity:0.92;";
      btn.addEventListener("click", function () {
        var info = getVideoInfo();
        RaraQueueBridge.postMessage(JSON.stringify({ type: "add-to-queue", title: info.title, url: info.url }));
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

  setInterval(hideYoutubeTopbar, 500);
  setInterval(hideAdElements, 1000);
  setInterval(autoSkipAds, 800);
  setInterval(hidePromoByText, 1000);

  hideYoutubeTopbar();
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
