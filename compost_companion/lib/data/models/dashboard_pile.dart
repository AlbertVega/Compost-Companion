import 'package:flutter/material.dart';

class HealthRecord {
  final double temperature;
  final double moisture;
  final DateTime timestamp;
  final double? carbonContent;
  final double? nitrogenContent;
  final String? status; // 'good' | 'acceptable' | 'bad' (from API field "status")
  final int? healthScore; // 0–100, provided by server

  HealthRecord({
    required this.temperature,
    required this.moisture,
    required this.timestamp,
    this.carbonContent,
    this.nitrogenContent,
    this.status,
    this.healthScore,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      temperature: (json['temperature'] as num).toDouble(),
      moisture: (json['moisture'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      carbonContent: json['carbon_content'] != null ? (json['carbon_content'] as num).toDouble() : null,
      nitrogenContent: json['nitrogen_content'] != null ? (json['nitrogen_content'] as num).toDouble() : null,
      status: json['status'] as String?,
      healthScore: json['health_score'] != null ? (json['health_score'] as num).toInt() : null,
    );
  }
}

/// A lightweight view model used by the dashboard.
///
/// Combines the pile's core info with the most recent health record
/// (if any) plus an optional error message when the health endpoint
/// could not be fetched.
class DashboardPile {
  final int id;
  final String name;
  final HealthRecord? latestRecord;
  final String? error;

  DashboardPile({
    required this.id,
    required this.name,
    this.latestRecord,
    this.error,
  });

  /// Raw status string exactly as returned by the server
  /// (`good` / `acceptable` / `bad`). May be null if the record
  /// wasn't populated by the database.
  String? get rawStatus => latestRecord?.status;

  /// Color corresponding to the raw status; grey when unknown.
  Color get statusColor {
    switch (rawStatus) {
      case 'good':
        return const Color(0xFF2F6F4E);
      case 'acceptable':
        return const Color(0xFFD68D18);
      case 'bad':
        return const Color(0xFFDB181B);
      default:
        return Colors.grey;
    }
  }

  /// Text to show on cards etc.  Prefer the raw status value; if
  /// that's unavailable fall back to error/no-data messaging.
  String get status {
    if (error != null) return 'Error';
    if (latestRecord == null) return 'No data yet';
    return rawStatus ?? 'Unknown';
  }

  /// Human‑readable label for screens that want a friendly title.
  String get displayStatus {
    switch (rawStatus) {
      case 'good':
        return 'Good';
      case 'acceptable':
        return 'Acceptable';
      case 'bad':
        return 'Needs Attention';
      default:
        return status;
    }
  }
}
