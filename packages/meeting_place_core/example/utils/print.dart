// ignore_for_file: avoid_print
import 'dart:io';

import 'package:pretty_json/pretty_json.dart';

void prettyJsonPrint(String name, Object json) {
  print(name);
  print(prettyJson(json));
}

void prettyJsonPrintYellow(String name, Object json) {
  print('\x1B[33m$name');
  print('${prettyJson(json)}\x1B[0m');
}

void prettyPrint(String message) {
  print(message);
}

void prettyPrintGreen(String message) {
  stdout.writeln('\x1B[32m$message\x1B[0m');
}

void prettyPrintYellow(String message) {
  stdout.writeln('\x1B[33m$message\x1B[0m');
}
