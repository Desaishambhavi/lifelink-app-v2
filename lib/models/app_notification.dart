/// The category of an in-app notification, used to pick its icon and accent.
enum NotificationKind { vitals, reminder, fall, sos, report, system }

/// A single entry in the in-app notification centre.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationKind kind;
  final DateTime timestamp;
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.timestamp,
    this.read = false,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        kind: kind,
        timestamp: timestamp,
        read: read ?? this.read,
      );

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id: map['id'] as String,
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        kind: NotificationKind.values[(map['kind'] as num?)?.toInt() ?? 5],
        timestamp: DateTime.tryParse('${map['timestamp']}') ?? DateTime.now(),
        read: map['read'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'kind': kind.index,
        'timestamp': timestamp.toIso8601String(),
        'read': read,
      };
}
