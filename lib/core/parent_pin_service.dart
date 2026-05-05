import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentPinStatus {
  const ParentPinStatus({
    required this.isSet,
    this.createdAt,
  });

  final bool isSet;
  final DateTime? createdAt;
}

class ParentPinService {
  const ParentPinService();

  static const String saltKey = 'lumo_parent_pin_salt_v1';
  static const String hashKey = 'lumo_parent_pin_hash_v1';
  static const String createdAtKey = 'lumo_parent_pin_created_at_v1';
  static const int minPinLength = 4;
  static const int maxPinLength = 12;

  /// MVP-Fallback bei vergessener PIN:
  ///
  /// Es gibt noch kein Backend, keine E-Mail-Verifikation und keinen
  /// serverseitigen Reset. Wenn die Eltern-PIN verloren geht, kann sie im MVP
  /// nur durch OS-seitiges Löschen der App-Daten zurückgesetzt werden
  /// (Android: Einstellungen -> Apps -> Lumo Lernen -> Speicher -> Daten löschen).
  /// Ein späterer produktiver Reset braucht eine geprüfte Eltern-Identität.
  String get forgottenPinRecoveryHint =>
      'PIN vergessen: Im MVP ist ein Reset nur über das Löschen der App-Daten im Betriebssystem möglich.';

  Future<ParentPinStatus> status() async {
    final prefs = await SharedPreferences.getInstance();
    final salt = prefs.getString(saltKey);
    final hash = prefs.getString(hashKey);
    final createdAt = DateTime.tryParse(prefs.getString(createdAtKey) ?? '');
    return ParentPinStatus(
      isSet: salt != null && salt.isNotEmpty && hash != null && hash.isNotEmpty,
      createdAt: createdAt,
    );
  }

  Future<bool> isPinSet() async => (await status()).isSet;

  Future<void> createPin(String pin) async {
    _validatePin(pin);
    final prefs = await SharedPreferences.getInstance();
    final salt = _newSalt();
    final hash = _hashPin(pin, salt);
    await prefs.setString(saltKey, salt);
    await prefs.setString(hashKey, hash);
    await prefs.setString(createdAtKey, DateTime.now().toIso8601String());
  }

  Future<void> changePin({
    required String currentPin,
    required String nextPin,
  }) async {
    final ok = await verifyPin(currentPin);
    if (!ok) {
      throw const ParentPinException('current_pin_invalid');
    }
    await createPin(nextPin);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = prefs.getString(saltKey);
    final storedHash = prefs.getString(hashKey);
    if (salt == null || storedHash == null || salt.isEmpty || storedHash.isEmpty) {
      return false;
    }
    if (!_isValidPinShape(pin)) return false;
    final candidate = _hashPin(pin, salt);
    return _constantTimeEquals(candidate, storedHash);
  }

  Future<void> removePinForFactoryResetOnly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(saltKey);
    await prefs.remove(hashKey);
    await prefs.remove(createdAtKey);
  }

  void _validatePin(String pin) {
    if (!_isValidPinShape(pin)) {
      throw const ParentPinException('pin_must_be_4_to_12_digits');
    }
  }

  bool _isValidPinShape(String pin) {
    final value = pin.trim();
    if (value.length < minPinLength || value.length > maxPinLength) return false;
    return RegExp(r'^\d+$').hasMatch(value);
  }

  String _newSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:${pin.trim()}');
    return sha256.convert(bytes).toString();
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

class ParentPinException implements Exception {
  const ParentPinException(this.code);
  final String code;

  @override
  String toString() => 'ParentPinException($code)';
}
