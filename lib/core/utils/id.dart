import 'dart:math';

final _random = Random();

/// Gera um identificador único curto.
String newId() =>
    DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
    _random.nextInt(0xffffff).toRadixString(36);
