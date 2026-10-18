import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structflow/core/utils/material_icon_registry.dart';

void main() {
  test('restores supported material icons from persisted code points', () {
    expect(
      materialIconFromCodePoint(
        Icons.business_rounded.codePoint,
        fallback: Icons.apartment_rounded,
      ),
      Icons.business_rounded,
    );
  });

  test('uses a safe fallback for unknown persisted icon code points', () {
    expect(
      materialIconFromCodePoint(0, fallback: Icons.person_rounded),
      Icons.person_rounded,
    );
  });
}
