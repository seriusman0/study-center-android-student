// Models for admin-managed jurnal offline templates and photo scans.
//
// JurnalOfflineTemplate represents a pre-built jurnal file (PDF) that
// students can download and fill offline, uploaded per cabang.
// JurnalPhotoScan represents a student-submitted photo scan of a filled
// offline jurnal, along with its processing status from the OCR job.
import 'package:flutter/foundation.dart';

/// Shared date parser used by [JurnalOfflineTemplate] and [JurnalPhotoScan].
@visibleForTesting
DateTime parseDate(dynamic raw) {
  if (raw == null) return DateTime.now();
  if (raw is DateTime) return raw;
  try {
    return DateTime.parse(raw as String);
  } catch (_) {
    return DateTime.now();
  }
}

class JurnalOfflineTemplate {
  final int id;
  final String cabangNama;
  final String originalName;
  final String uploadedByName;
  final DateTime createdAt;
  final String? downloadUrl;

  const JurnalOfflineTemplate({
    required this.id,
    required this.cabangNama,
    required this.originalName,
    required this.uploadedByName,
    required this.createdAt,
    this.downloadUrl,
  });

  factory JurnalOfflineTemplate.fromJson(Map<String, dynamic> json) {
    return JurnalOfflineTemplate(
      id: (json['id'] as num).toInt(),
      cabangNama: json['cabang'] is Map
          ? (json['cabang'] as Map)['nama'] as String? ?? ''
          : json['cabang_nama'] as String? ?? '',
      originalName: json['original_name'] as String? ?? '',
      uploadedByName: json['uploaded_by'] is Map
          ? (json['uploaded_by'] as Map)['name'] as String? ?? ''
          : json['uploaded_by_name'] as String? ?? '',
      createdAt: parseDate(json['created_at']),
      downloadUrl: json['download_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'cabang_nama': cabangNama,
        'original_name': originalName,
        'uploaded_by_name': uploadedByName,
        'created_at': createdAt.toIso8601String(),
        'download_url': downloadUrl,
      };
}

/// Status for a [JurnalPhotoScan] upload / processing.
enum JurnalPhotoScanStatus { pending, processing, success, failed }

extension JurnalPhotoScanStatusX on JurnalPhotoScanStatus {
  String get label {
    switch (this) {
      case JurnalPhotoScanStatus.pending:
        return 'Menunggu';
      case JurnalPhotoScanStatus.processing:
        return 'Memproses';
      case JurnalPhotoScanStatus.success:
        return 'Berhasil';
      case JurnalPhotoScanStatus.failed:
        return 'Gagal';
    }
  }

  /// Parse a backend snake_case status string into the matching enum value.
  static JurnalPhotoScanStatus fromString(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'pending':
        return JurnalPhotoScanStatus.pending;
      case 'processing':
        return JurnalPhotoScanStatus.processing;
      case 'success':
      case 'succeeded':
      case 'completed':
        return JurnalPhotoScanStatus.success;
      case 'failed':
      case 'error':
        return JurnalPhotoScanStatus.failed;
      default:
        return JurnalPhotoScanStatus.pending;
    }
  }
}

class JurnalPhotoScan {
  final int id;
  final String originalName;
  final JurnalPhotoScanStatus status;
  final String? resultJson;
  final String? error;
  final DateTime createdAt;

  const JurnalPhotoScan({
    required this.id,
    required this.originalName,
    this.status = JurnalPhotoScanStatus.pending,
    this.resultJson,
    this.error,
    required this.createdAt,
  });

  factory JurnalPhotoScan.fromJson(Map<String, dynamic> json) {
    return JurnalPhotoScan(
      id: (json['id'] as num).toInt(),
      originalName: json['original_name'] as String? ?? '',
      status: JurnalPhotoScanStatusX.fromString(
          json['status'] as String? ?? 'pending'),
      resultJson: json['result_json'] as String?,
      error: json['error_message'] as String?,
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'original_name': originalName,
        'status': status.name,
        'result_json': resultJson,
        'error': error,
        'created_at': createdAt.toIso8601String(),
      };
}
