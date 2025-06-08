import 'package:flutter/foundation.dart';

void appLog(String message, [Object? error, StackTrace? stack]) {
  if (error != null) {
    debugPrint('[33m[APP] $message: $error[0m');
    if (stack != null) debugPrint('[90m$stack[0m');
  } else {
    debugPrint('[32m[APP] $message[0m');
  }
}
