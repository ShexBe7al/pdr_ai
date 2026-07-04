import 'package:flutter/material.dart';

class CameraButtons extends StatelessWidget {
  final VoidCallback onLiveCamera;
  final VoidCallback onGallery;
  final VoidCallback onScan;

  const CameraButtons({
    super.key,
    required this.onLiveCamera,
    required this.onGallery,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onLiveCamera,
          child: const Text("Live Camera"),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: onGallery,
          child: const Text("Gallery"),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: onScan,
          child: const Text("Scan"),
        ),
      ],
    );
  }
}