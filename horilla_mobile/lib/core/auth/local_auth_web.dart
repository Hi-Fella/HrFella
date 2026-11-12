// Stub for web — biometric lock is not supported.
class LocalAuthentication {
  Future<bool> isDeviceSupported() async => false;

  Future<bool> authenticate({
    required String localizedReason,
    AuthenticationOptions? options,
  }) async => false;
}

class AuthenticationOptions {
  const AuthenticationOptions({this.stickyAuth = false});

  final bool stickyAuth;
}
