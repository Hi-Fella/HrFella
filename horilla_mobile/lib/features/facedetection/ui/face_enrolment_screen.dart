// Platform-conditional export: native platforms get the camera implementation;
// web gets a "not supported" stub.
export 'face_enrolment_screen_io.dart'
    if (dart.library.html) 'face_enrolment_screen_web.dart';
