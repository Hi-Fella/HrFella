import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_top_bar.dart';

/// Whether a frame in this raw format/plane-count shape is one the
/// single-plane converter below can actually turn into an `InputImage`.
///
/// A pure, primitive-typed decision pulled out of [_toInputImage] so it can
/// be unit tested: `CameraImage`/`Plane` only have private constructors in
/// the `camera` package, so there is no way to build a fake one from a test
/// -- this is the part of that function that doesn't need one.
@visibleForTesting
bool isSupportedCameraFrame({
  required int? formatRawValue,
  required int planeCount,
  required bool isAndroid,
}) {
  final format = InputImageFormatValue.fromRawValue(formatRawValue ?? -1);
  if (format == null) return false;
  if (isAndroid && format != InputImageFormat.nv21) return false;
  if (!isAndroid && format != InputImageFormat.bgra8888) return false;
  return planeCount == 1;
}

/// Frame-by-frame liveness bookkeeping, isolated from the camera/detector so
/// it can be tested without either. A run of [requiredConsecutiveFrames]
/// detections in a row confirms; any frame with no face resets the count,
/// so a face that shows up, leaves, and comes back doesn't get credit for
/// frames before it left.
@visibleForTesting
class PresenceCounter {
  PresenceCounter({
    this.requiredConsecutiveFrames = _kRequiredConsecutiveFrames,
  });

  final int requiredConsecutiveFrames;
  int _consecutive = 0;

  /// Returns true the moment this frame completes the required run.
  bool record({required bool faceDetected}) {
    _consecutive = faceDetected ? _consecutive + 1 : 0;
    return _consecutive >= requiredConsecutiveFrames;
  }
}

const _kRequiredConsecutiveFrames = 6;

class FacePresenceGate extends StatefulWidget {
  const FacePresenceGate({super.key});

  @override
  State<FacePresenceGate> createState() => _FacePresenceGateState();
}

enum _Status { initializing, ready, denied, unavailable }

class _FacePresenceGateState extends State<FacePresenceGate> {
  CameraController? _controller;
  FaceDetector? _detector;
  _Status _status = _Status.initializing;
  final _presence = PresenceCounter();
  bool _processing = false;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _status = _Status.unavailable);
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: false,
        // A single-plane format on both platforms -- NV21 on Android,
        // BGRA8888 on iOS -- is what the multi-plane-agnostic converter
        // below assumes. Default YUV_420_888 on Android is multi-plane and
        // would need concatenating; asking for NV21 here avoids that.
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();

      _detector = FaceDetector(
        options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
      );

      await controller.startImageStream(_onFrame);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _status = _Status.ready;
      });
    } on CameraException {
      if (mounted) setState(() => _status = _Status.denied);
    } catch (_) {
      if (mounted) setState(() => _status = _Status.unavailable);
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_processing || _confirmed) return;
    _processing = true;
    try {
      final controller = _controller;
      final detector = _detector;
      if (controller == null || detector == null) return;

      final input = _toInputImage(image, controller.description);
      if (input == null) return;

      final faces = await detector.processImage(input);
      final confirmed = _presence.record(faceDetected: faces.isNotEmpty);

      if (confirmed && !_confirmed) {
        _confirmed = true;
        await controller.stopImageStream();
        if (mounted) context.pop(true);
      }
    } finally {
      _processing = false;
    }
  }

  @override
  void dispose() {
    _detector?.close();
    final controller = _controller;
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream();
      }
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Column(
        children: [
          AppTopBar(
            title: 'Confirm it\'s you',
            onDark: true,
            onBack: () => context.pop(false),
          ),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    switch (_status) {
      case _Status.initializing:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.surface),
        );
      case _Status.ready:
        final controller = _controller!;
        return Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.card),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.x20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      child: CameraPreview(controller),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.x20),
              child: Text(
                'Hold the front camera up so your face is in frame.',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: AppColors.onDark2),
              ),
            ),
          ],
        );
      case _Status.denied:
        return _fallback(
          context,
          message:
              'Camera access is off for HRFella, so this step can\'t run. '
              'Turn it on in Settings, or skip and punch without it.',
        );
      case _Status.unavailable:
        return _fallback(
          context,
          message: 'No usable camera was found on this device.',
        );
    }
  }

  Widget _fallback(BuildContext context, {required String message}) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.screen),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: AppColors.surface),
          ),
          const SizedBox(height: AppSpace.x20),
          AppButton(
            label: 'Skip and punch anyway',
            tone: AppButtonTone.onDark,
            onPressed: () => context.pop(true),
          ),
        ],
      ),
    );
  }
}

/// `CameraImage` -> the type google_mlkit's detector actually takes.
///
/// Assumes a single-plane format (NV21 on Android, BGRA8888 on iOS, which is
/// what the controller above requests) -- a multi-plane image returns null
/// and the frame is silently skipped rather than crashing the stream.
InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
  final supported = isSupportedCameraFrame(
    formatRawValue: image.format.raw,
    planeCount: image.planes.length,
    isAndroid: defaultTargetPlatform == TargetPlatform.android,
  );
  if (!supported) return null;
  final format = InputImageFormatValue.fromRawValue(image.format.raw)!;

  final rotation =
      InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
      InputImageRotation.rotation0deg;

  return InputImage.fromBytes(
    bytes: image.planes.first.bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    ),
  );
}
