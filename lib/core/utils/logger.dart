import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print(' [Teman Nakes] ${DateTime.now()}: $message');
      if (error != null) print(' Error: $error');
      if (stackTrace != null) print(' StackTrace: $stackTrace');
    }
  }

  static void info(String message) => log('INFO: $message');
  static void warning(String message) => log('WARNING: $message');
  static void error(String message, [Object? err, StackTrace? st]) => log('ERROR: $message', err, st);
}
