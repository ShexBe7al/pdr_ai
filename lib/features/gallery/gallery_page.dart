import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../ai/scanner_ai.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final ImagePicker _picker = ImagePicker();

  File? _image;

  List<Offset> _points = [];

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _points.clear();
      });
    }
  }

  Future<void> _scanImage() async {
    if (_image == null) return;

    final result = await ScannerAI.scanImage(_image!);

    setState(() {
      _points = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B18),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Gallery"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            Expanded(
              child: Center(
                child: _image == null
                    ? const Text(
                        "No Image Selected",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      )
                    : Stack(
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
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _pickImage,
                child: const Text("Choose Image"),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _scanImage,
                child: const Text("Scan Image"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}