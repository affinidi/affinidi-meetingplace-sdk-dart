import 'r_card_subject.dart';

/// vCard 3.0 export extension for [RCardSubject].
extension RCardVCardExtension on RCardSubject {
  /// Serialises this R-Card subject to a vCard 3.0 string.
  ///
  /// Follows [RFC 6350](https://datatracker.ietf.org/doc/html/rfc6350) for
  /// property names and value encoding.
  /// The [notes] parameter is appended as the `NOTE` field when provided.
  String toVCard({String? notes}) {
    final firstName = this.firstName?.trim();
    final lastName = this.lastName?.trim();
    final profilePic = this.profilePic?.trim();
    final email = this.email?.trim();
    final phone = this.phone?.trim();
    final company = this.company?.trim();
    final position = this.position?.trim();
    final website = this.website?.trim();
    final social = this.social?.trim();
    final vCardNotes = notes?.trim();

    final safeFirst = (firstName == null || firstName.isEmpty)
        ? null
        : firstName;
    final safeLast = (lastName == null || lastName.isEmpty) ? null : lastName;

    final lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      if (safeFirst != null || safeLast != null)
        'N:${_escapeVCard(safeLast ?? '')};${_escapeVCard(safeFirst ?? '')};;;',
      if (safeFirst != null || safeLast != null)
        'FN:${_escapeVCard([safeFirst, safeLast]
            .whereType<String>()
            .join(' ')
            .trim())}',
      if (profilePic != null && profilePic.isNotEmpty)
        ..._buildPhotoLines(profilePic),
      if (email != null && email.isNotEmpty) 'EMAIL:${_escapeVCard(email)}',
      if (phone != null && phone.isNotEmpty)
        'TEL;TYPE=cell:${_escapeVCard(phone)}',
      if (company != null && company.isNotEmpty) 'ORG:${_escapeVCard(company)}',
      if (position != null && position.isNotEmpty)
        'TITLE:${_escapeVCard(position)}',
      if (website != null && website.isNotEmpty) 'URL:${_escapeVCard(website)}',
      if (social != null && social.isNotEmpty) 'URL:${_escapeVCard(social)}',
      if (vCardNotes != null && vCardNotes.isNotEmpty)
        'NOTE:${_escapeVCard(vCardNotes)}',
      'END:VCARD',
      '',
    ];

    return lines.map((l) => '$l\r\n').join();
  }

  String _escapeVCard(String value) {
    return value
        .replaceAll('\\', r'\\')
        .replaceAll('\n', r'\n')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,');
  }

  List<String> _buildPhotoLines(String base64) {
    if (base64.isEmpty) return const [];

    const chunkSize = 76;
    final length = base64.length;
    final lineCount = (length + chunkSize - 1) ~/ chunkSize;

    return List<String>.generate(lineCount, (index) {
      final start = index * chunkSize;
      final end = (start + chunkSize > length) ? length : start + chunkSize;
      final chunk = base64.substring(start, end);
      return index == 0 ? 'PHOTO;ENCODING=BASE64;TYPE=JPEG:$chunk' : ' $chunk';
    });
  }
}
