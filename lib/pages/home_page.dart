import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';

import '../ai/scanner_ai.dart';
import '../widgets/camera_buttons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();

  File? _image;
  List<Offset> _points = [];

  CameraController? _controller;

  bool _isCameraOpen = false;

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _isCameraOpen = false;
      });
    }
  }

  Future<void> _openLiveCamera() async {
    final cameras = await availableCameras();

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
    );

    await _controller!.initialize();

    setState(() {
      _isCameraOpen = true;
    });
  }

  Future<void> _scanImage() async {
    debugprint("SCAN CLICKED");

    if (_image == null) {
    debugprint("IMAGE IS NULL");
    return;
  }
    debugprint("IMAGE FOUND");
    final result = await ScannerAI.scanImage(_image!);

    debugprint("RESULT = ${result.length}");
    setState(() {
      _points = result;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDR AI"),
        centerTitle: true,
      ),
      body: Center(
        child: _isCameraOpen && _controller != null
            ? CameraPreview(_controller!)
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    if (_image != null)
                      SizedBox(
  height: 300,
  child: Stack(
    children: [
      Image.file(_image!),

      ..._points.map(
        (p) => Positioned(
          left: p.dx,
          top: p.dy,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    ],
  ),
)
                    else
                      const Icon(
                        Icons.car_repair,
                        size: 120,
                      ),

                    const SizedBox(height: 30),

                    CameraButtons(
                      onLiveCamera: _openLiveCamera,
                      onGallery: _pickImage,
                      onScan: _scanImage,
                    ),

                  ],
                ),
              ),
      ),
    );
  }
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}