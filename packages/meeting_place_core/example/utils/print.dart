// ignore_for_file: avoid_print
import 'package:pretty_json/pretty_json.dart';

const _ansiGray = '\x1B[38;5;250m';
const _ansiReset = '\x1B[0m';

prettyJsonPrint(String name, Object json) {
  print(name);
  print(prettyJson(json));
}

prettyJsonPrintYellow(String name, Object json) {
  print('\x1B[33m$name');
  print('${prettyJson(json)}\x1B[0m');
}

prettyJsonPrintGray(String name, Object json) {
  _printBox(name, prettyJson(json).split('\n'));
}

void _printBox(String title, Iterable<String> lines) {
  final contentLines = <String>[title, ...lines];
  final width = contentLines
      .map((l) => l.length)
      .reduce((a, b) => a > b ? a : b);

  print('$_ansiGray┌${'─' * (width + 2)}┐$_ansiReset');
  _printBoxLine(title, width);
  print('$_ansiGray├${'─' * (width + 2)}┤$_ansiReset');
  for (final line in lines) {
    _printBoxLine(line, width);
  }
  print('$_ansiGray└${'─' * (width + 2)}┘$_ansiReset');
}

void _printBoxLine(String line, int width) {
  final padding = ' ' * (width - line.length);
  print('$_ansiGray│ $line$padding │$_ansiReset');
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

prettyPrintGray(String message) {
  print('$_ansiGray$message$_ansiReset');
}

prettyPrintBoxDevider() {
  print('$_ansiGray────────────────────────────$_ansiReset');
}
