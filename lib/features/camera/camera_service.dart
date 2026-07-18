import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;

  CameraController? get controller => _controller;

  bool get isReady => _controller?.value.isInitialized ?? false;

  Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw StateError('No camera found');
    }

    final backCamera = cameras.cast<CameraDescription?>().firstWhere(
          (camera) => camera?.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        ) ??
        cameras.first;

    await _controller?.dispose();
    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
  }

  Future<XFile> capture() async {
    final camera = _controller;
    if (camera == null || !camera.value.isInitialized) {
      throw StateError('Camera is not ready');
    }
    if (camera.value.isTakingPicture) {
      throw StateError('A photo is already being captured');
    }

    return camera.takePicture();
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
