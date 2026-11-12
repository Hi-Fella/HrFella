// Platform-conditional export: native platforms get the full ML Kit
// implementation; web gets a pass-through stub (ML Kit is native-only).
export 'face_presence_gate_io.dart'
    if (dart.library.html) 'face_presence_gate_web.dart';
