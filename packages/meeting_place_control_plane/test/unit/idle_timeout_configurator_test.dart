import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:meeting_place_control_plane/src/api/idle_timeout_configurator_io.dart';
import 'package:test/test.dart';

void main() {
  test(
    'configureIdleTimeout wires createHttpClient with the given idleTimeout',
    () {
      final dio = Dio();
      const timeout = Duration(seconds: 42);

      configureIdleTimeout(dio, timeout);

      final adapter = dio.httpClientAdapter as IOHttpClientAdapter;
      expect(adapter.createHttpClient, isNotNull);

      final client = adapter.createHttpClient!();
      expect(client.idleTimeout, equals(timeout));
      client.close();
    },
  );
}
