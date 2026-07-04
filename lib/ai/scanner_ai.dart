import 'dart:io';
import 'package:flutter/material.dart';

class ScannerAI {
  static Future<List<Offset>> scanImage(File image) async {
    // ئێستا AI نییە، تەنها بۆ تاقیکردنەوە
    await Future.delayed(const Duration(seconds: 1));

    return [
      const Offset(120, 180),
      const Offset(240, 320),
      const Offset(330, 210),
    ];
  }
}