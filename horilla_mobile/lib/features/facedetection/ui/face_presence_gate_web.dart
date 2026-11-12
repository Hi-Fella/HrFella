import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Pure liveness logic -- no ML Kit dependency, safe on web too.
@visibleForTesting
bool isSupportedCameraFrame({
  required int? formatRawValue,
  required int planeCount,
  required bool isAndroid,
}) => false;

@visibleForTesting
class PresenceCounter {
  PresenceCounter({this.requiredConsecutiveFrames = 6});
  final int requiredConsecutiveFrames;
  int _consecutive = 0;
  bool record({required bool faceDetected}) {
    _consecutive = faceDetected ? _consecutive + 1 : 0;
    return _consecutive >= requiredConsecutiveFrames;
  }
}

// Face detection is native-only. On web, skip the gate and pass through.
class FacePresenceGate extends StatefulWidget {
  const FacePresenceGate({super.key});

  @override
  State<FacePresenceGate> createState() => _FacePresenceGateWebState();
}

class _FacePresenceGateWebState extends State<FacePresenceGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop(true);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
