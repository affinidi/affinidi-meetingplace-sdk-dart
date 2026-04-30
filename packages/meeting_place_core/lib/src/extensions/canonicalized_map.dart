extension CanonicalizedMap on Map<String, dynamic> {
  Map<String, dynamic> canonicalized() {
    final sorted = <String, dynamic>{};
    final mapKeys = keys.toList()..sort();
    for (final key in mapKeys) {
      final value = this[key];
      if (value is Map<String, dynamic>) {
        sorted[key] = value.canonicalized();
      } else if (value is List) {
        sorted[key] = value
            .map(
              (element) => element is Map<String, dynamic>
                  ? element.canonicalized()
                  : element,
            )
            .toList();
      } else {
        sorted[key] = value;
      }
    }
    return sorted;
  }
}
