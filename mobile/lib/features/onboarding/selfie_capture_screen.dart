// FILE: lib/features/onboarding/selfie_capture_screen.dart
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../core/theme/app_theme.dart';

/// Full-screen front-camera view that auto-captures a selfie as soon as a
/// single, centred, front-facing face is held steady inside the guide.
///
/// Pops with the captured image's file path, or `null` if the user closes it.
class SelfieCaptureScreen extends StatefulWidget {
  const SelfieCaptureScreen({super.key});

  @override
  State<SelfieCaptureScreen> createState() => _SelfieCaptureScreenState();
}

enum _FaceStatus {
  starting,
  noFace,
  multipleFaces,
  moveCloser,
  centerFace,
  lookStraight,
  openEyes,
  holdStill,
  capturing,
}

class _SelfieCaptureScreenState extends State<SelfieCaptureScreen>
    with WidgetsBindingObserver {
  /// Consecutive "good" frames required before capturing (~0.5–1s).
  static const int _requiredStableFrames = 6;

  static const Map<DeviceOrientation, int> _orientationDegrees = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      minFaceSize: 0.2,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  CameraController? _controller;
  CameraDescription? _camera;
  bool _isDetecting = false;
  bool _isCapturing = false;
  int _stableFrames = 0;
  _FaceStatus _status = _FaceStatus.starting;
  String? _fatalError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller = null;
      controller.dispose();
      if (mounted) setState(() => _status = _FaceStatus.starting);
    } else if (state == AppLifecycleState.resumed && !_isCapturing) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _fatalError = null;
      _status = _FaceStatus.starting;
      _stableFrames = 0;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'No camera found on this device.');
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _camera = camera;
      _controller = controller;
      await controller.startImageStream(_onFrame);
      setState(() => _status = _FaceStatus.noFace);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _fatalError = switch (e.code) {
          'CameraAccessDenied' ||
          'CameraAccessDeniedWithoutPrompt' ||
          'CameraAccessRestricted' =>
            'Camera access is needed to verify it\'s you. '
                'Allow camera access in Settings and try again.',
          _ => e.description ?? 'Could not start the camera.',
        };
      });
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_isDetecting || _isCapturing) return;
    _isDetecting = true;
    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted || _isCapturing) return;

      final rotation = inputImage.metadata!.rotation;
      final isRotated = rotation == InputImageRotation.rotation90deg ||
          rotation == InputImageRotation.rotation270deg;
      final uprightSize = isRotated
          ? Size(image.height.toDouble(), image.width.toDouble())
          : Size(image.width.toDouble(), image.height.toDouble());

      final status = _evaluate(faces, uprightSize);
      if (status == _FaceStatus.holdStill) {
        _stableFrames++;
      } else {
        _stableFrames = 0;
      }

      if (_stableFrames >= _requiredStableFrames) {
        await _capture();
        return;
      }

      if (status != _status) setState(() => _status = status);
    } catch (_) {
      // A single bad frame shouldn't break the stream; wait for the next one.
    } finally {
      _isDetecting = false;
    }
  }

  _FaceStatus _evaluate(List<Face> faces, Size imageSize) {
    if (faces.isEmpty) return _FaceStatus.noFace;
    if (faces.length > 1) return _FaceStatus.multipleFaces;

    final face = faces.first;
    final box = face.boundingBox;

    if (box.width / imageSize.width < 0.35) return _FaceStatus.moveCloser;

    final dx = (box.center.dx / imageSize.width) - 0.5;
    final dy = (box.center.dy / imageSize.height) - 0.45;
    if (dx.abs() > 0.15 || dy.abs() > 0.18) return _FaceStatus.centerFace;

    final yaw = face.headEulerAngleY ?? 0;
    final roll = face.headEulerAngleZ ?? 0;
    final pitch = face.headEulerAngleX ?? 0;
    if (yaw.abs() > 12 || roll.abs() > 12 || pitch.abs() > 15) {
      return _FaceStatus.lookStraight;
    }

    final leftEye = face.leftEyeOpenProbability;
    final rightEye = face.rightEyeOpenProbability;
    if ((leftEye != null && leftEye < 0.4) ||
        (rightEye != null && rightEye < 0.4)) {
      return _FaceStatus.openEyes;
    }

    return _FaceStatus.holdStill;
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _isCapturing) return;
    _isCapturing = true;
    setState(() => _status = _FaceStatus.capturing);

    try {
      await controller.stopImageStream();
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } on CameraException catch (e) {
      if (!mounted) return;
      _isCapturing = false;
      _stableFrames = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.description ?? 'Capture failed. Try again.')),
      );
      await controller.startImageStream(_onFrame);
      if (mounted) setState(() => _status = _FaceStatus.noFace);
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final controller = _controller;
    final camera = _camera;
    if (controller == null || camera == null) return null;

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else {
      final deviceDegrees =
          _orientationDegrees[controller.value.deviceOrientation];
      if (deviceDegrees == null) return null;
      final compensation = camera.lensDirection == CameraLensDirection.front
          ? (sensorOrientation + deviceDegrees) % 360
          : (sensorOrientation - deviceDegrees + 360) % 360;
      rotation = InputImageRotationValue.fromRawValue(compensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  String get _statusText {
    switch (_status) {
      case _FaceStatus.starting:
        return 'Starting camera…';
      case _FaceStatus.noFace:
        return 'Position your face inside the oval';
      case _FaceStatus.multipleFaces:
        return 'Make sure only you are in the frame';
      case _FaceStatus.moveCloser:
        return 'Move a little closer';
      case _FaceStatus.centerFace:
        return 'Centre your face in the oval';
      case _FaceStatus.lookStraight:
        return 'Look straight at the camera';
      case _FaceStatus.openEyes:
        return 'Keep your eyes open';
      case _FaceStatus.holdStill:
        return 'Hold still…';
      case _FaceStatus.capturing:
        return 'Got it!';
    }
  }

  bool get _isGood =>
      _status == _FaceStatus.holdStill || _status == _FaceStatus.capturing;

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_fatalError == null &&
              controller != null &&
              controller.value.isInitialized)
            _CoverCameraPreview(controller: controller),
          if (_fatalError == null)
            CustomPaint(
              painter: _OvalGuidePainter(
                borderColor:
                    _isGood ? const Color(0xFF34C759) : Colors.white,
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                  child: _fatalError != null
                      ? _ErrorPanel(message: _fatalError!, onRetry: _initCamera)
                      : _StatusPill(
                          text: _statusText,
                          isGood: _isGood,
                          showSpinner: _status == _FaceStatus.starting ||
                              _status == _FaceStatus.capturing,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverCameraPreview extends StatelessWidget {
  const _CoverCameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    // previewSize is reported in landscape; the preview is shown upright.
    var scale = screen.aspectRatio * controller.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return ClipRect(
      child: Transform.scale(
        scale: scale,
        child: Center(child: CameraPreview(controller)),
      ),
    );
  }
}

class _OvalGuidePainter extends CustomPainter {
  _OvalGuidePainter({required this.borderColor});

  final Color borderColor;

  static Rect ovalRect(Size size) {
    final width = size.width * 0.72;
    final height = width * 1.32;
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: width,
      height: height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final oval = ovalRect(size);
    final overlay = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(oval);
    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    canvas.drawOval(
      oval,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = borderColor,
    );
  }

  @override
  bool shouldRepaint(_OvalGuidePainter oldDelegate) =>
      oldDelegate.borderColor != borderColor;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.text,
    required this.isGood,
    required this.showSpinner,
  });

  final String text;
  final bool isGood;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isGood ? const Color(0xFF34C759) : Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isGood ? Colors.white : JDateTokens.brandRose,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: isGood ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 15.5),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: JDateTokens.brandRose,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
          ),
          onPressed: onRetry,
          child: const Text('Try again'),
        ),
      ],
    );
  }
}
