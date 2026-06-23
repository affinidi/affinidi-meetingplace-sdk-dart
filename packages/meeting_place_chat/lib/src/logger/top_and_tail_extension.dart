extension TopAndTailExtension on String {
  String topAndTail({int charCountTop = 16, int charCountTail = 8}) {
    if (length < charCountTop || length - charCountTail < 0) {
      return this;
    }
    return """${substring(0, charCountTop)}${(charCountTop > 0) ? '...' : ''}${substring(length - charCountTail)}""";
  }
}
