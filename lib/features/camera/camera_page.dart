import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../reports/report_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;

  Future<void>? _initializeCameraFuture;

  bool _isCameraReady = false;
  bool _isCapturing = false;

  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception("No camera found");
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeCameraFuture = _controller!.initialize();

      await _initializeCameraFuture;

      if (!mounted) return;

      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      debugPrint("Camera Error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Camera Error: $e"),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      final image = await _controller!.takePicture();

      if (!mounted) return;

      setState(() {
        _capturedImage = image;
        _isCapturing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCapturing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Capture Failed : $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady) {
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
        title: const Text("PDR Live Scan"),
        centerTitle: true,
      ),

      body: Stack(
        children: [

          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          if (_capturedImage != null)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.file(
                  File(_capturedImage!.path),
                  fit: BoxFit.cover,
                ),
              ),
            ),

        ],
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,

      floatingActionButton: FloatingActionButton.large(
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
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.analytics),
              label: const Text(
                "Analyze Image",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (_capturedImage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please capture a photo first.",
                      ),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportPage(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}