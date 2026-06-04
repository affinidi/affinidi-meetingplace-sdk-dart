// ignore_for_file: avoid_print
import 'package:pretty_json/pretty_json.dart';

/// Prints [name] followed by pretty-printed [json] in yellow.
void prettyJsonPrintYellow(String name, Object json) {
  print('\x1B[33m$name');
  print('${prettyJson(json)}\x1B[0m');
}

/// Prints [name] followed by pretty-printed [json] with no colour.
void prettyJsonPrint(String name, Object json) {
  print(name);
  print(prettyJson(json));
}

/// Prints [message] in green for section headers.
void prettyPrintGreen(String message) {
  print('\x1B[32m$message\x1B[0m');
}

/// Prints [message] in yellow for data output.
void prettyPrintYellow(String message) {
  print('\x1B[33m$message\x1B[0m');
}

/// Prints [message] with no colour.
void prettyPrint(String message) {
  print(message);
}
