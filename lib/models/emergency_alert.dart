import 'health_data.dart';

/// A one-tap SOS event, mirrored from `/emergency_alerts/{pushKey}`.
class EmergencyAlert {
  final String id;
  final DateTime timestamp;
  final String userName;
  final String contactName;
  final String contactPhone;
  final GpsPoint? location;
  final String message;
  final bool resolved;

  const EmergencyAlert({
    required this.id,
    required this.timestamp,
    required this.userName,
    required this.contactName,
    required this.contactPhone,
    required this.location,
    required this.message,
    this.resolved = false,
  });

  EmergencyAlert copyWith({bool? resolved}) => EmergencyAlert(
        id: id,
        timestamp: timestamp,
        userName: userName,
        contactName: contactName,
        contactPhone: contactPhone,
        location: location,
        message: message,
        resolved: resolved ?? this.resolved,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'user_name': userName,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'location': location?.toMap(),
        'message': message,
        'resolved': resolved,
      };
}
