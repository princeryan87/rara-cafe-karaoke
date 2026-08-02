// ============================================================
//  QUEUE DIALOG — tampilan antrian lagu
// ============================================================

import 'package:flutter/material.dart';
import '../config.dart';
import '../services/queue_service.dart';

/// Menampilkan dialog antrian. [onPlay] dipanggil saat user tekan
/// "▶ Putar" pada salah satu item (item itu sudah dihapus dari
/// antrian SEBELUM callback ini dipanggil).
Future<void> showQueueDialog(
  BuildContext context, {
  required void Function(QueueItem item) onPlay,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _QueueDialogContent(onPlay: onPlay),
  );
}

class _QueueDialogContent extends StatefulWidget {
  final void Function(QueueItem item) onPlay;
  const _QueueDialogContent({required this.onPlay});

  @override
  State<_QueueDialogContent> createState() => _QueueDialogContentState();
}

class _QueueDialogContentState extends State<_QueueDialogContent> {
  List<QueueItem> _queue = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final q = await QueueService.getQueue();
    if (!mounted) return;
    setState(() {
      _queue = q;
      _loading = false;
    });
  }

  Future<void> _play(int index) async {
    final item = _queue[index];
    await QueueService.removeAt(index);
    if (!mounted) return;
    Navigator.pop(context);
    widget.onPlay(item);
  }

  Future<void> _remove(int index) async {
    await QueueService.removeAt(index);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 480),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppConfig.darkOrange, AppConfig.dark],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppConfig.orange, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('🎵 Antrian Lagu',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 6),
            const Text('Buka video lalu tekan "+ Tambah ke Antrian"',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppConfig.gold, fontSize: 12)),
            const SizedBox(height: 16),
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppConfig.orange)),
                    )
                  : _queue.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('Antrian kosong.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppConfig.gold)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _queue.length,
                          itemBuilder: (ctx, index) {
                            final item = _queue[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppConfig.darkCard,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text('${index + 1}. ${item.title}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13)),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _play(index),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppConfig.orange,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Text('▶ Putar',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _remove(index),
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Text('🗑',
                                          style: TextStyle(fontSize: 14)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppConfig.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppConfig.orange, width: 1.5),
                ),
                child: const Center(
                  child: Text('Tutup',
                      style: TextStyle(
                          color: AppConfig.gold,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
