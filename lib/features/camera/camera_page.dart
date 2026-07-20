import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../ai/scanner_ai.dart';
import '../reports/report_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;

  String? _capturedImagePath;
  String? _errorMessage;

  bool _isInitializing = true;
  bool _isTakingPhoto = false;
  bool _isScanning = false;

  static const String _roboflowApiKey = String.fromEnvironment(
    'ROBOFLOW_API_KEY',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (mounted) {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });
    }

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('هیچ کامێرایەک لەسەر ئامێرەکە نەدۆزرایەوە.');
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final oldController = _cameraController;

      final newController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = newController;

      await oldController?.dispose();
      await newController.initialize();

      if (!mounted) {
        await newController.dispose();
        return;
      }

      setState(() {
        _isInitializing = false;
      });
    } on CameraException catch (error) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _errorMessage =
            'کامێرا نەکرایەوە:\n${error.description ?? error.code}';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _errorMessage = 'هەڵەیەک ڕوویدا:\n$error';
      });
    }
  }

  Future<void> _takePhoto() async {
    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _isTakingPhoto) {
      return;
    }

    try {
      setState(() {
        _isTakingPhoto = true;
        _errorMessage = null;
      });

      final XFile photo = await controller.takePicture();

      if (!mounted) return;

      setState(() {
        _capturedImagePath = photo.path;
      });
    } on CameraException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'نەتوانرا وێنە بگیرێت:\n${error.description ?? error.code}';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'هەڵە لە کاتی وێنەگرتن:\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPhoto = false;
        });
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImagePath = null;
      _errorMessage = null;
    });
  }

  Future<ui.Image> _readImageSize(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    return frame.image;
  }

  Future<void> _openReportPage() async {
    final imagePath = _capturedImagePath;

    if (imagePath == null || _isScanning) {
      return;
    }

    if (_roboflowApiKey.trim().isEmpty) {
      setState(() {
        _errorMessage =
            'RoboFlow API Key دانەنراوە.\n'
            'پڕۆژەکە بە --dart-define دروست بکە.';
      });
      return;
    }

    try {
      setState(() {
        _isScanning = true;
        _errorMessage = null;
      });

      final imageFile = File(imagePath);

      if (!await imageFile.exists()) {
        throw Exception('فایلی وێنەکە نەدۆزرایەوە.');
      }

      final decodedImage = await _readImageSize(imageFile);

      final scanResult = await ScannerAI.scan(
        imageFile,
        _roboflowApiKey,
      );

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ReportPage(
            imagePath: imagePath,
            result: scanResult,
            imageWidth: decodedImage.width.toDouble(),
            imageHeight: decodedImage.height.toDouble(),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'سکانکردنی وێنە سەرکەوتوو نەبوو:\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final capturedImagePath = _capturedImagePath;

    return Scaffold(
      backgroundColor: const Color(0xFF050B18),
      appBar: AppBar(
        title: const Text(
          'PDR Camera',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF050B18),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: capturedImagePath == null
            ? _buildCameraView()
            : _buildCapturedImageView(capturedImagePath),
      ),
    );
  }

  Widget _buildCameraView() {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return _buildErrorView(
        message: 'کامێرا ئامادە نییە.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: CameraPreview(controller),
              ),
            ),
          ),
        ),
        if (_errorMessage != null) _buildErrorMessage(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: _isTakingPhoto ? null : _takePhoto,
              icon: _isTakingPhoto
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.camera_alt_rounded),
              label: Text(
                _isTakingPhoto ? 'وێنەکە دەگیرێت...' : 'وێنە بگرە',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.blueGrey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCapturedImageView(String imagePath) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        'وێنەکە ناتوانرێت پیشان بدرێت.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (_errorMessage != null) _buildErrorMessage(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 58,
                  child: OutlinedButton.icon(
                    onPressed: _isScanning ? null : _retakePhoto,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(
                      'دووبارە',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: Colors.white54,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _openReportPage,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      _isScanning ? 'AI سکان دەکات...' : 'دەستپێکردنی سکان',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.blueGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView({String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? _errorMessage ?? 'هەڵەیەک ڕوویدا.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('هەوڵدانەوە'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.redAccent,
          ),
        ),
        child: Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}