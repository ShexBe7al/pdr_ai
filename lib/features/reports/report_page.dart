import 'dart:io';

import 'package:flutter/material.dart';

import '../ai/scanner_ai.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({
    super.key,
    required this.imagePath,
    required this.result,
    required this.imageWidth,
    required this.imageHeight,
  });

  final String imagePath;
  final ScanResult result;
  final double imageWidth;
  final double imageHeight;

  double get averageConfidence {
    if (result.predictions.isEmpty) return 0;

    final total = result.predictions.fold<double>(
      0,
      (sum, prediction) => sum + prediction.confidence,
    );

    return total / result.predictions.length;
  }

  String get scanDate {
    final now = DateTime.now();

    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');

    return '$day/$month/${now.year}';
  }

  void _showComingSoon(
    BuildContext context,
    String feature,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be added in the next step.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Scan Report',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 300,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.blue,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                  ),
                  CustomPaint(
                    painter: ReportDentBoxPainter(
                      predictions: result.predictions,
                      originalImageWidth: imageWidth,
                      originalImageHeight: imageHeight,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _infoRow(
                    'Dent Count',
                    result.dentCount.toString(),
                    Icons.car_repair,
                    Colors.red,
                  ),

                  const Divider(
                    color: Colors.white12,
                  ),

                  _infoRow(
                    'Average Confidence',
                    '${(averageConfidence * 100).toStringAsFixed(1)}%',
                    Icons.analytics,
                    Colors.green,
                  ),

                  const Divider(
                    color: Colors.white12,
                  ),

                  _infoRow(
                    'Scan Date',
                    scanDate,
                    Icons.calendar_today,
                    Colors.orange,
                  ),

                  const Divider(
                    color: Colors.white12,
                  ),

                  _infoRow(
                    'Status',
                    result.dentCount > 0
                        ? 'Dents Detected'
                        : 'No Dents Detected',
                    result.dentCount > 0
                        ? Icons.warning_amber
                        : Icons.check_circle,
                    result.dentCount > 0
                        ? Colors.redAccent
                        : Colors.green,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showComingSoon(
                    context,
                    'Export PDF',
                  );
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text(
                  'Export PDF',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showComingSoon(
                    context,
                    'Save Report',
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text(
                  'Save Report',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportDentBoxPainter extends CustomPainter {
  const ReportDentBoxPainter({
    required this.predictions,
    required this.originalImageWidth,
    required this.originalImageHeight,
  });

  final List<Prediction> predictions;
  final double originalImageWidth;
  final double originalImageHeight;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (originalImageWidth <= 1 ||
        originalImageHeight <= 1) {
      return;
    }

    final imageRatio =
        originalImageWidth / originalImageHeight;

    final canvasRatio =
        size.width / size.height;

    double displayedWidth;
    double displayedHeight;
    double offsetX;
    double offsetY;

    if (canvasRatio > imageRatio) {
      displayedHeight = size.height;
      displayedWidth =
          displayedHeight * imageRatio;

      offsetX =
          (size.width - displayedWidth) / 2;

      offsetY = 0;
    } else {
      displayedWidth = size.width;
      displayedHeight =
          displayedWidth / imageRatio;

      offsetX = 0;

      offsetY =
          (size.height - displayedHeight) / 2;
    }

    final scaleX =
        displayedWidth / originalImageWidth;

    final scaleY =
        displayedHeight / originalImageHeight;

    final boxPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final labelPaint = Paint()
      ..color = const Color(0xDD000000)
      ..style = PaintingStyle.fill;

    for (
      int index = 0;
      index < predictions.length;
      index++
    ) {
      final prediction = predictions[index];

      final left = offsetX +
          (prediction.x -
                  prediction.width / 2) *
              scaleX;

      final top = offsetY +
          (prediction.y -
                  prediction.height / 2) *
              scaleY;

      final right = offsetX +
          (prediction.x +
                  prediction.width / 2) *
              scaleX;

      final bottom = offsetY +
          (prediction.y +
                  prediction.height / 2) *
              scaleY;

      final rect = Rect.fromLTRB(
        left,
        top,
        right,
        bottom,
      );

      canvas.drawRect(
        rect,
        boxPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text:
              '#${index + 1} ${(prediction.confidence * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelTop =
          top > textPainter.height + 8
              ? top - textPainter.height - 8
              : top;

      final labelRect = Rect.fromLTWH(
        left,
        labelTop,
        textPainter.width + 12,
        textPainter.height + 6,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          labelRect,
          const Radius.circular(5),
        ),
        labelPaint,
      );

      textPainter.paint(
        canvas,
        Offset(
          left + 6,
          labelTop + 3,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant ReportDentBoxPainter oldDelegate,
  ) {
    return oldDelegate.predictions != predictions ||
        oldDelegate.originalImageWidth !=
            originalImageWidth ||
        oldDelegate.originalImageHeight !=
            originalImageHeight;
  }
}