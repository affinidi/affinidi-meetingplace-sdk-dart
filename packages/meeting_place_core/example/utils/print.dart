// ignore_for_file: avoid_print
import 'package:pretty_json/pretty_json.dart';

prettyJsonPrint(String name, Object json) {
  print(name);
  print(prettyJson(json));
}

prettyJsonPrintYellow(String name, Object json) {
  print('\x1B[33m$name');
  print('${prettyJson(json)}\x1B[0m');
}

prettyPrint(String message) {
  print(message);
}

prettyPrintGreen(String message) {
  print('\x1B[32m$message\x1B[0m');
}

prettyPrintYellow(String message) {
  print('\x1B[33m$message\x1B[0m');
}
