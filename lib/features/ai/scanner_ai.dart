import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class Prediction {
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;
  final String label;

  Prediction({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
    required this.label,
  });
}

class ScanResult {
  final List<Prediction> predictions;
  final int dentCount;

  ScanResult({
    required this.predictions,
    required this.dentCount,
  });
}

class ScannerAI {
  static const String _project = "pdr-scanner-ai-v2";
  static const String _version = "1";

  static Future<ScanResult> scan(
    File image,
    String apiKey,
  ) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse(
        "https://detect.roboflow.com/$_project/$_version?api_key=$apiKey",
      ),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        image.path,
      ),
    );

    final response = await request.send();

    final body = await response.stream.bytesToString();

    final json = jsonDecode(body);

    final List predictions = json["predictions"] ?? [];

    return ScanResult(
      dentCount: predictions.length,
      predictions: predictions.map((e) {
        return Prediction(
          x: (e["x"] as num).toDouble(),
          y: (e["y"] as num).toDouble(),
          width: (e["width"] as num).toDouble(),
          height: (e["height"] as num).toDouble(),
          confidence: (e["confidence"] as num).toDouble(),
          label: e["class"].toString(),
        );
      }).toList(),
    );
  }
}