/// Named routes for the app. The router itself is wired in main.dart once the
/// screens are registered, keeping navigation strings in one typo-proof place.
class AppRoutes {
  AppRoutes._();

  static const String landing = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String shell = '/home'; // bottom-nav shell
  static const String analytics = '/analytics';
  static const String report = '/report';
  static const String reminder = '/reminder';
  static const String emergency = '/emergency';
  static const String fallAlert = '/fall-alert';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
}
