import '../services_api.dart';




class AppPreloader {
  static final AppPreloader instance = AppPreloader._();
  AppPreloader._();

  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    // 🔒 DO NOT add APIs yet
    // This will be wired in the next steps
  }
}
