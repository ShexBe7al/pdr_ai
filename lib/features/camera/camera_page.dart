import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../ai/scanner_ai.dart';
import '../reports/report_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  static const String _apiKey = String.fromEnvironment(
    'ROBOFLOW_API_KEY',
  );

  final ImagePicker _picker = ImagePicker();

  XFile? _capturedImage;
  ScanResult? _scanResult;

  bool _isOpeningCamera = false;
  bool _isAnalyzing = false;

  double _imageWidth = 1;
  double _imageHeight = 1;

  Future<void> _openCamera() async {
    if (_isOpeningCamera) return;

    setState(() {
      _isOpeningCamera = true;
      _scanResult = null;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 95,
      );

      if (image == null) {
        return;
      }

      await _readImageSize(File(image.path));

      if (!mounted) return;

      setState(() {
        _capturedImage = image;
      });

      await _analyzeImage();
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Camera failed: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningCamera = false;
        });
      }
    }
  }

  Future<void> _readImageSize(File imageFile) async {
    final bytes = await imageFile.readAsBytes();

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    _imageWidth = frame.image.width.toDouble();
    _imageHeight = frame.image.height.toDouble();

    frame.image.dispose();
    codec.dispose();
  }

  Future<void> _analyzeImage() async {
    final image = _capturedImage;

    if (image == null) {
      _showMessage('Please take a photo first.');
      return;
    }

    if (_apiKey.isEmpty) {
      _showMessage(
        'Roboflow API key is missing.',
      );
      return;
    }

    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _scanResult = null;
    });

    try {
      final result = await ScannerAI.scan(
        File(image.path),
        _apiKey,
      );

      if (!mounted) return;

      setState(() {
        _scanResult = result;
      });

      _showMessage(
        '${result.dentCount} dent(s) detected.',
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'AI scan failed: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }
    void _openReport() {
    final image = _capturedImage;
    final result = _scanResult;

    if (image == null || result == null) {
      _showMessage('Analyze the image first.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPage(
          imagePath: image.path,
          result: result,
          imageWidth: _imageWidth,
          imageHeight: _imageHeight,
        ),
      ),
    );
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _scanResult = null;
      _imageWidth = 1;
      _imageHeight = 1;
    });

    _openCamera();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = _capturedImage;
    final result = _scanResult;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('PDR Scan'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: image == null
                ? _buildStartScreen()
                : _buildCapturedImage(image),
          ),

          if (result != null) _buildResultSummary(result),

          if (_isOpeningCamera || _isAnalyzing)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0x99000000),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _isOpeningCamera
                            ? 'Opening camera...'
                            : 'Analyzing dents...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: image == null
          ? null
          : SafeArea(
              child: Container(
                color: Colors.black,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: OutlinedButton.icon(
                          onPressed:
                              _isAnalyzing ? null : _retakePhoto,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retake'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _isAnalyzing
                              ? null
                              : result == null
                                  ? _analyzeImage
                                  : _openReport,
                          icon: Icon(
                            result == null
                                ? Icons.analytics
                                : Icons.description,
                          ),
                          label: Text(
                            result == null
                                ? 'Analyze Image'
                                : 'Open Report',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: result == null
                                ? Colors.green
                                : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              color: Colors.blue,
              size: 90,
            ),
            const SizedBox(height: 20),
            const Text(
              'Take a vehicle panel photo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The image will be sent to PDR AI for dent detection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed:
                    _isOpeningCamera ? null : _openCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text(
                  'Start Scan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
    Widget _buildCapturedImage(XFile image) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(image.path),
          fit: BoxFit.contain,
        ),
        if (_scanResult != null)
          CustomPaint(
            painter: DentBoxPainter(
              predictions: _scanResult!.predictions,
              originalImageWidth: _imageWidth,
              originalImageHeight: _imageHeight,
            ),
          ),
      ],
    );
  }

  Widget _buildResultSummary(ScanResult result) {
    final averageConfidence = result.predictions.isEmpty
        ? 0.0
        : result.predictions
                .map((prediction) => prediction.confidence)
                .reduce((a, b) => a + b) /
            result.predictions.length;

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xDD111827),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.blue,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dent Count: ${result.dentCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Confidence: ${(averageConfidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DentBoxPainter extends CustomPainter {
  const DentBoxPainter({
    required this.predictions,
    required this.originalImageWidth,
    required this.originalImageHeight,
  });

  final List<Prediction> predictions;
  final double originalImageWidth;
  final double originalImageHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (originalImageWidth <= 1 || originalImageHeight <= 1) {
      return;
    }

    final imageRatio = originalImageWidth / originalImageHeight;
    final canvasRatio = size.width / size.height;

    double displayedWidth;
    double displayedHeight;
    double offsetX;
    double offsetY;

    if (canvasRatio > imageRatio) {
      displayedHeight = size.height;
      displayedWidth = displayedHeight * imageRatio;
      offsetX = (size.width - displayedWidth) / 2;
      offsetY = 0;
    } else {
      displayedWidth = size.width;
      displayedHeight = displayedWidth / imageRatio;
      offsetX = 0;
      offsetY = (size.height - displayedHeight) / 2;
    }

    final scaleX = displayedWidth / originalImageWidth;
    final scaleY = displayedHeight / originalImageHeight;

    final boxPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final labelBackgroundPaint = Paint()
      ..color = const Color(0xDD000000)
      ..style = PaintingStyle.fill;

    for (int index = 0; index < predictions.length; index++) {
      final prediction = predictions[index];

      final left =
          offsetX + (prediction.x - prediction.width / 2) * scaleX;
      final top =
          offsetY + (prediction.y - prediction.height / 2) * scaleY;
      final right =
          offsetX + (prediction.x + prediction.width / 2) * scaleX;
      final bottom =
          offsetY + (prediction.y + prediction.height / 2) * scaleY;

      final rect = Rect.fromLTRB(
        left,
        top,
        right,
        bottom,
      );

      canvas.drawRect(rect, boxPaint);

      final label =
          '#${index + 1} ${(prediction.confidence * 100).toStringAsFixed(0)}%';

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelTop = top > textPainter.height + 8
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
        labelBackgroundPaint,
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
  bool shouldRepaint(covariant DentBoxPainter oldDelegate) {
    return oldDelegate.predictions != predictions ||
        oldDelegate.originalImageWidth != originalImageWidth ||
        oldDelegate.originalImageHeight != originalImageHeight;
  }
}