// Basic smoke tests for LifeLink building blocks.
//
// The full app relies on the service locator (Services.init), so these tests
// exercise self-contained widgets and pure model logic instead.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelink/models/user_profile.dart';
import 'package:lifelink/widgets/brand_mark.dart';

void main() {
  testWidgets('BrandMark renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: BrandMark(size: 72))),
    ));
    expect(find.byType(BrandMark), findsOneWidget);
  });

  test('UserProfile BMI is computed from height and weight', () {
    const profile = UserProfile(
      id: 'u1',
      name: 'Test User',
      email: 'test@lifelink.health',
      age: 30,
      gender: 'Other',
      heightCm: 180,
      weightKg: 81,
      bloodGroup: 'O+',
      emergencyContactName: 'Kin',
      emergencyContactPhone: '123',
    );
    expect(profile.bmi, closeTo(25.0, 0.1));
    expect(profile.bmiLabel, 'Overweight');
  });
}
