import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'report_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;

  bool _isCameraReady = false;
  bool _isTakingPhoto = false;

  String? _errorMessage;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isCameraReady = false;
        _errorMessage = null;
      });

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'هیچ کامێرایەک لەسەر ئەم ئامێرە نەدۆزرایەوە.';
        });

        return;
      }

      CameraDescription selectedCamera = cameras.first;

      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraReady = true;
        _errorMessage = null;
      });
    } on CameraException catch (error) {
      if (!mounted) return;

      String message;

      switch (error.code) {
        case 'CameraAccessDenied':
          message =
              'مۆڵەتی کامێرا ڕەتکرایەوە.\nلە Settings مۆڵەتی Camera بۆ PDR AI چالاک بکە.';
          break;

        case 'CameraAccessDeniedWithoutPrompt':
          message =
              'مۆڵەتی کامێرا داخراوە.\nبڕۆ بۆ Settings > PDR AI > Camera و چالاکی بکە.';
          break;

        case 'CameraAccessRestricted':
          message = 'بەکارهێنانی کامێرا لەسەر ئەم ئامێرە سنووردار کراوە.';
          break;

        case 'AudioAccessDenied':
          message = 'مۆڵەتی دەنگ ڕەتکرایەوە.';
          break;

        default:
          message = 'هەڵەی کامێرا: ${error.description ?? error.code}';
      }

      setState(() {
        _errorMessage = message;
        _isCameraReady = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'هەڵەیەک ڕوویدا:\n$error';
        _isCameraReady = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
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

  void _openReportPage() {
    final imagePath = _capturedImagePath;

    if (imagePath == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportPage(
          imagePath: imagePath,
        ),
      ),
    );
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
      _isCameraReady = false;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _cameraController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050B18),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'PDR Camera',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null && !_isCameraReady) {
      return _buildErrorView();
    }

    if (_capturedImagePath != null) {
      return _buildCapturedImageView();
    }

    if (!_isCameraReady ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return _buildCameraView();
  }

  Widget _buildCameraView() {
    final controller = _cameraController!;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: CameraPreview(controller),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 6,
            ),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.redAccent,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            children: [
              const Text(
                'کامێرا بە ئاراستەی پەڕەی ئۆتۆمبێلەکە بگرە',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _isTakingPhoto ? null : _takePhoto,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.blueAccent,
                      width: 5,
                    ),
                  ),
                  child: _isTakingPhoto
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_rounded,
                          color: Color(0xFF050B18),
                          size: 36,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapturedImageView() {
    final imagePath = _capturedImagePath!;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                        'وێنەکە نەتوانرا پیشان بدرێت',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retakePhoto,
                  icon: const Icon(Icons.refresh),
                  label: const Text('دووبارە وێنە بگرە'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.white38,
                    ),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openReportPage,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('بەردەوام بە'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.redAccent,
                size: 64,
              ),
              const SizedBox(height: 18),
              Text(
                _errorMessage ?? 'کامێرا کار ناکات.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _initializeCamera,
                icon: const Icon(Icons.refresh),
                label: const Text('دووبارە هەوڵ بدە'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}