import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../ai/scanner_ai.dart';
import '../reports/report_page.dart';
import 'camera_service.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  static const String _apiKey = String.fromEnvironment(
    'ROBOFLOW_API_KEY',
  );

  final CameraService _cameraService = CameraService();

  bool _isCameraReady = false;
  bool _isCapturing = false;
  bool _isAnalyzing = false;

  String? _cameraError;
  XFile? _capturedImage;
  ScanResult? _scanResult;

  double _imageWidth = 1;
  double _imageHeight = 1;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (mounted) {
      setState(() {
        _isCameraReady = false;
        _cameraError = null;
      });
    }

    try {
      await _cameraService.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraReady = true;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _cameraError = error.toString();
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || !_cameraService.isReady) return;

    setState(() {
      _isCapturing = true;
      _scanResult = null;
    });

    try {
      final image = await _cameraService.capture();

      if (image == null) {
        throw Exception('No image was captured.');
      }

      await _readImageSize(File(image.path));

      if (!mounted) return;

      setState(() {
        _capturedImage = image;
      });
    } catch (error) {
      if (!mounted) return;

      _showMessage('Capture failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
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
    final capturedImage = _capturedImage;

    if (capturedImage == null) {
      _showMessage('Please capture a photo first.');
      return;
    }

    if (_apiKey.isEmpty) {
      _showMessage(
        'Roboflow API key is missing. Run the app with --dart-define.',
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
        File(capturedImage.path),
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

      _showMessage('AI scan failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

 void _openReport() {
  if (_scanResult == null || _capturedImage == null) {
    _showMessage('Analyze the image first.');
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ReportPage(
        imagePath: _capturedImage!.path,
        result: _scanResult!,
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
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraService.controller;

    if (_cameraError != null) {
      return _buildCameraError();
    }

    if (!_isCameraReady ||
        controller == null ||
        !controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('PDR Live Scan'),
        centerTitle: true,
        actions: [
          if (_capturedImage != null)
            IconButton(
              onPressed: _retakePhoto,
              icon: const Icon(Icons.refresh),
              tooltip: 'Retake',
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _capturedImage == null
                ? CameraPreview(controller)
                : _buildCapturedImage(),
          ),
          if (_scanResult != null) _buildResultSummary(),
          if (_isAnalyzing)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x88000000),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Analyzing dents...',
                        style: TextStyle(
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
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _capturedImage == null
          ? FloatingActionButton.large(
              backgroundColor: Colors.blue,
              onPressed: _isCapturing ? null : _capturePhoto,
              child: _isCapturing
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Icon(
                      Icons.camera_alt,
                      size: 34,
                    ),
            )
          : null,
      bottomNavigationBar: _capturedImage == null
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
                          onPressed: _retakePhoto,
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
                              : _scanResult == null
                                  ? _analyzeImage
                                  : _openReport,
                          icon: Icon(
                            _scanResult == null
                                ? Icons.analytics
                                : Icons.description,
                          ),
                          label: Text(
                            _scanResult == null
                                ? 'Analyze Image'
                                : 'Open Report',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _scanResult == null
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

  Widget _buildCapturedImage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(_capturedImage!.path),
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
      },
    );
  }

  Widget _buildResultSummary() {
    final result = _scanResult!;

    final averageConfidence = result.predictions.isEmpty
        ? 0.0
        : result.predictions
                .map((prediction) => prediction.confidence)
                .reduce((a, b) => a + b) /
            result.predictions.length;

    return Positioned(
      top: 16,
      left: 16,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dent Count: ${result.dentCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
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

  Widget _buildCameraError() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('PDR Live Scan'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                color: Colors.redAccent,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _cameraError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _initializeCamera,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
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