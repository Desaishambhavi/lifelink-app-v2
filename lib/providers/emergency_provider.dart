import 'package:flutter/foundation.dart';

import '../models/emergency_alert.dart';
import '../models/health_data.dart';
import '../models/user_profile.dart';
import '../services/service_locator.dart';

/// Coordinates raising an SOS and reflecting its send state in the UI.
class EmergencyProvider extends ChangeNotifier {
  bool _sending = false;
  DateTime? _lastRaised;

  bool get sending => _sending;
  DateTime? get lastRaised => _lastRaised;

  Future<void> raise({
    UserProfile? profile,
    GpsPoint? location,
    String message = 'Emergency SOS triggered from LifeLink.',
  }) async {
    _sending = true;
    notifyListeners();

    final alert = EmergencyAlert(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      userName: profile?.name ?? '',
      contactName: profile?.emergencyContactName ?? '',
      contactPhone: profile?.emergencyContactPhone ?? '',
      location: location,
      message: message,
    );
    await Services.emergencies.raise(alert);

    _lastRaised = alert.timestamp;
    _sending = false;
    notifyListeners();
  }
}
