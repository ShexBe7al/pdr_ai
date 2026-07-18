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

  ScanResult? _result;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _result = null;
      });
    }
  }

  Future<void> _scanImage() async {
    if (_image == null) return;

    final result = await ScannerAI.scan(
      _image!,
      const String.fromEnvironment("ROBOFLOW_API_KEY"),
    );

    setState(() {
      _result = result;
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
                    : Image.file(_image!),
              ),
            ),

            if (_result != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(
                  "Dent Count : ${_result!.dentCount}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

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