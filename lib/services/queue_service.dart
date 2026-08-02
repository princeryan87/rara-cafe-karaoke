// ============================================================
//  QUEUE SERVICE — antrian lagu
// ============================================================
//  Disimpan sebagai file JSON sementara di folder cache aplikasi
//  (BUKAN database). Otomatis terhapus begitu antrian habis
//  diputar. Mirror dari sistem antrian di versi Windows.
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class QueueItem {
  final String title;
  final String url;

  QueueItem({required this.title, required this.url});

  Map<String, dynamic> toJson() => {'title': title, 'url': url};

  factory QueueItem.fromJson(Map<String, dynamic> json) => QueueItem(
        title: json['title'] as String? ?? 'Tanpa judul',
        url: json['url'] as String? ?? '',
      );
}

class QueueService {
  static Future<File> _queueFile() async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}/rara_queue.json');
  }

  static Future<List<QueueItem>> getQueue() async {
    try {
      final file = await _queueFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final List<dynamic> list = jsonDecode(content);
      return list
          .map((e) => QueueItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<QueueItem>> addToQueue(QueueItem item) async {
    final queue = await getQueue();
    queue.add(item);
    await _saveQueue(queue);
    return queue;
  }

  static Future<List<QueueItem>> removeAt(int index) async {
    final queue = await getQueue();
    if (index >= 0 && index < queue.length) {
      queue.removeAt(index);
      await _saveQueue(queue);
    }
    return queue;
  }

  static Future<void> clear() async {
    await _saveQueue([]);
  }

  static Future<void> _saveQueue(List<QueueItem> queue) async {
    try {
      final file = await _queueFile();
      if (queue.isEmpty) {
        // Antrian habis -> hapus file, tidak menyisakan jejak
        if (await file.exists()) await file.delete();
        return;
      }
      final jsonStr = jsonEncode(queue.map((e) => e.toJson()).toList());
      await file.writeAsString(jsonStr);
    } catch (_) {
      // diamkan -- kegagalan simpan antrian tidak boleh crash aplikasi
    }
  }
}
