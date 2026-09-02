/// The user's health profile, stored in Firestore/Supabase `users/{uid}` in
/// the original app. Height is in cm, weight in kg.
class UserProfile {
  final String id;
  final String name;
  final String email;
  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final String bloodGroup;
  final String emergencyContactName;
  final String emergencyContactPhone;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.bloodGroup,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
  });

  /// Body mass index, derived from height and weight.
  double get bmi {
    if (heightCm <= 0) return 0;
    final m = heightCm / 100.0;
    return weightKg / (m * m);
  }

  String get bmiLabel {
    final value = bmi;
    if (value <= 0) return 'Unknown';
    if (value < 18.5) return 'Underweight';
    if (value < 25) return 'Healthy';
    if (value < 30) return 'Overweight';
    return 'Obese';
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'LL';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  UserProfile copyWith({
    String? name,
    String? email,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? bloodGroup,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
    );
  }

  /// Maps a row from the `users` table (see supabase/schema.sql).
  factory UserProfile.fromMap(String id, Map<String, dynamic> map) {
    final full = (map['full_name'] as String?)?.trim();
    final composed = [map['first_name'], map['last_name']]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(' ')
        .trim();
    return UserProfile(
      id: id,
      name: (full != null && full.isNotEmpty) ? full : composed,
      email: map['email'] as String? ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      gender: map['gender'] as String? ?? '',
      heightCm: (map['height'] as num?)?.toDouble() ?? 0,
      weightKg: (map['weight'] as num?)?.toDouble() ?? 0,
      bloodGroup: map['blood_group'] as String? ?? '',
      emergencyContactName: map['emergency_contact_name'] as String? ?? '',
      emergencyContactPhone: map['emergency_contact'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    final parts = name.trim().split(RegExp(r'\s+'));
    return {
      'full_name': name,
      'first_name': parts.isNotEmpty ? parts.first : '',
      'last_name': parts.length > 1 ? parts.sublist(1).join(' ') : '',
      'email': email,
      'age': age,
      'gender': gender,
      'height': heightCm,
      'weight': weightKg,
      'bmi': bmi,
      'blood_group': bloodGroup,
      // emergency_contact_name is an app-added column (see schema.sql).
      'emergency_contact_name': emergencyContactName,
      'emergency_contact': emergencyContactPhone,
    };
  }
}
