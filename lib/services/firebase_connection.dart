/// Stores the Firebase startup result so providers can safely decide whether
/// to use Firebase or keep the app running in local prototype mode.
class FirebaseConnection {
  static bool isEnabled = false;
  static String? errorMessage;

  static void markEnabled() {
    isEnabled = true;
    errorMessage = null;
  }

  static void markDisabled([Object? error]) {
    isEnabled = false;
    errorMessage = error?.toString();
  }
}
