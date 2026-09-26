import 'package:flutter/foundation.dart';

Map<String, dynamic> generateOfflineTemplate(Map<String, dynamic> previousData, String targetDate) {
  final result = Map<String, dynamic>.from(previousData);
  
  void resetSnapshot(Map<String, dynamic> snap) {
    snap['date'] = targetDate;
    snap['verse_checked'] = false;
    snap['foto_belajar_url'] = null;
    snap['foto_belajar'] = null;
    snap['photo_url'] = null;
    snap['foto_url'] = null;
    snap['foto'] = null;
    
    if (snap['bible'] is Map) {
      final bible = Map<String, dynamic>.from(snap['bible']);
      bible['pl_checked'] = false;
      bible['pb_checked'] = false;
      // We don't know the exact reading porsi for the new day, so we leave it as is 
      // or we could clear it, but leaving it as a placeholder is fine.
      snap['bible'] = bible;
    }
    
    if (snap['college_bible'] is Map) {
      final cb = Map<String, dynamic>.from(snap['college_bible']);
      cb['pl_checked'] = false;
      cb['pb_checked'] = false;
      snap['college_bible'] = cb;
    }
    
    if (snap['life_items'] is List) {
      final items = List<dynamic>.from(snap['life_items']);
      for (int i = 0; i < items.length; i++) {
        if (items[i] is Map) {
          final item = Map<String, dynamic>.from(items[i]);
          item['checked'] = false;
          items[i] = item;
        }
      }
      snap['life_items'] = items;
    } else if (snap['life_items'] is Map) {
      final items = Map<String, dynamic>.from(snap['life_items']);
      for (final key in items.keys) {
        if (items[key] is Map) {
          final item = Map<String, dynamic>.from(items[key]);
          item['checked'] = false;
          items[key] = item;
        }
      }
      snap['life_items'] = items;
    }
  }

  if (result.containsKey('data') && result['data'] is Map) {
    final data = Map<String, dynamic>.from(result['data']);
    resetSnapshot(data);
    result['data'] = data;
  } else {
    resetSnapshot(result);
  }

  return result;
}
