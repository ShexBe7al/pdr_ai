import 'dart:io';
import 'dart:math';
import 'dart:ui';

class ScannerAI {
  static Future<List<Offset>> scanImage(File image) async {
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();

    List<Offset> dents = [];

    int count = random.nextInt(6) + 3;

    for (int i = 0; i < count; i++) {
      dents.add(
        Offset(
          random.nextDouble() * 250,
          random.nextDouble() * 250,
        ),
      );
    }

    return dents;
  }
}