import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;

  Future<void>? _initializeControllerFuture;

  File? _capturedImage;

  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null) return;

    try {
      setState(() {
        _isCapturing = true;
      });

      await _initializeControllerFuture;

      final XFile image = await _controller!.takePicture();

      _capturedImage = File(image.path);

      if (mounted) {
        setState(() {
          _isCapturing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Photo Captured Successfully"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }

      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text("Live Camera"),
      ),

      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [

                Positioned.fill(
                  child: CameraPreview(_controller!),
                ),

                if (_capturedImage != null)
                  Positioned(
                    right: 20,
                    top: 20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _capturedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

              ],
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: _isCapturing ? null : _captureImage,
        child: _isCapturing
            ? const CircularProgressIndicator(
                color: Colors.white,
              )
            : const Icon(Icons.camera_alt),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }
}