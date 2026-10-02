import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// A per-installation recovery secret, separate from the short parent PIN.
/// Only its SHA-256 digest is persisted; the printable code is shown once.
class ParentPinRecovery {
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String generateCode() {
    final random = Random.secure();
    final raw = List.generate(
      20,
      (_) => _alphabet[random.nextInt(_alphabet.length)],
    ).join();
    return List.generate(4, (i) => raw.substring(i * 5, i * 5 + 5)).join('-');
  }

  static String normalize(String code) =>
      code.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

  static String hash(String code) => sha256
      .convert(
        utf8.encode('lumo-parent-recovery-v1:${normalize(code)}'),
      )
      .toString();

  static bool matches(String code, String storedHash) {
    final normalized = normalize(code);
    if (!RegExp(r'^[A-HJ-NP-Z2-9]{20}$').hasMatch(normalized) ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(storedHash)) return false;
    final candidate = hash(normalized);
    var difference = 0;
    for (var i = 0; i < storedHash.length; i++) {
      difference |= storedHash.codeUnitAt(i) ^ candidate.codeUnitAt(i);
    }
    return difference == 0;
  }
}
