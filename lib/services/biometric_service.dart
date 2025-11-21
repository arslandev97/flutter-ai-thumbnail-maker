import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Keys for secure storage
  static const String _keyEmail = 'biometric_email';
  static const String _keyPassword = 'biometric_password';
  static const String _keyEnabled = 'biometric_enabled';

  /// Checks if the device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  /// Authenticates the user using biometrics (Fingerprint/Face ID)
  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Securely stores the user's credentials
  Future<void> storeCredentials(String email, String password) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
    await _storage.write(key: _keyEnabled, value: 'true');
  }

  /// Retrieves stored credentials if biometric login is enabled
  Future<Map<String, String>?> getCredentials() async {
    final String? enabled = await _storage.read(key: _keyEnabled);
    if (enabled != 'true') return null;

    final String? email = await _storage.read(key: _keyEmail);
    final String? password = await _storage.read(key: _keyPassword);

    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  /// Clears stored credentials (used when disabling feature or logging out)
  Future<void> clearCredentials() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
    await _storage.write(key: _keyEnabled, value: 'false');
  }

  /// Checks if biometric login is currently enabled
  Future<bool> isBiometricEnabled() async {
    final String? enabled = await _storage.read(key: _keyEnabled);
    return enabled == 'true';
  }
}
