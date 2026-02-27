import 'package:flutter/material.dart';

class PileData {
  final String title;
  final String status;
  final Color statusColor;
  final String temp;
  final String moisture;
  final String chartAsset;
  final String tempIconAsset;
  final String moistureIconAsset;
  final Color buttonColor;

  PileData({
    required this.title,
    required this.status,
    required this.statusColor,
    required this.temp,
    required this.moisture,
    required this.chartAsset,
    required this.tempIconAsset,
    required this.moistureIconAsset,
    required this.buttonColor,
  });
}