import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ssi/ssi.dart';

/// An in-memory implementation of the [KeyStore] interface.
///
/// This implementation stores all keys and seeds in memory and does not persist them.
/// It is primarily used for testing purposes.
class FileSystemStore implements KeyStore {
  final fileName = '${Directory.current.path}/storage.json';

  @override
  Future<void> set(String key, StoredKey value) async {
    final file = File(fileName);
    final jsonString = file.readAsStringSync();
    final records = jsonDecode(jsonString) as Map<String, dynamic>;

    records[key] = value;
    await file.writeAsString(jsonEncode(records));
  }

  @override
  Future<StoredKey?> get(String key) async {
    final file = File(fileName);
    final jsonString = file.readAsStringSync();
    final records = jsonDecode(jsonString) as Map<String, dynamic>;
    if (records[key] == null) return null;

    return StoredKey(
      keyType: KeyType.values.byName(records[key]['keyType']),
      privateKeyBytes: Uint8List.fromList(
        records[key]['privateKeyBytes'].cast<int>(),
      ),
    );
  }

  @override
  Future<void> remove(String key) async {
    final file = File(fileName);
    final jsonString = file.readAsStringSync();
    final records = jsonDecode(jsonString) as Map<String, dynamic>;

    records.remove(key);
    await file.writeAsString(jsonEncode(records));
  }

  @override
  Future<bool> contains(String key) async {
    final file = File(fileName);
    final jsonString = file.readAsStringSync();
    final records = jsonDecode(jsonString) as Map<String, dynamic>;
    return records.containsKey(key);
  }

  @override
  Future<void> clear() async {
    final file = File(fileName);
    await file.writeAsString(jsonEncode({}));
  }
}
