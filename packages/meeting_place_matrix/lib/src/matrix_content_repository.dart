import 'dart:typed_data';
import 'package:dio/dio.dart';

class MatrixContentRepository {
  final String homeserverUrl;
  final Dio _dio;

  MatrixContentRepository({required this.homeserverUrl}) 
    : _dio = Dio(BaseOptions(baseUrl: homeserverUrl));

  /// Upload file to Matrix Content Repository
  /// POST /_matrix/media/v3/upload
  Future<String> uploadMedia({
    required Uint8List data,
    required String filename,
    required String contentType,
    String? accessToken,
  }) async {
    final response = await _dio.post(
      '/_matrix/media/v3/upload',
      data: data,
      queryParameters: {'filename': filename},
      options: Options(
        headers: {
          'Content-Type': contentType,
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
      ),
    );
    return response.data['content_uri'] as String; // Returns mxc:// URI
  }

/// Download file from Matrix Content Repository
  /// GET /_matrix/client/v1/media/download/{serverName}/{mediaId}/{fileName}
  /// The fileName parameter is optional and provides a hint for the download filename
  Future<Uint8List> downloadMedia(String mxcUri, {String? fileName}) async {
    final uri = Uri.parse(mxcUri);
    final serverName = uri.host;
    final mediaId = uri.pathSegments.last;
    
    final path = fileName != null
        ? '/_matrix/client/v1/media/download/$serverName/$mediaId/$fileName'
        : '/_matrix/client/v1/media/download/$serverName/$mediaId';
    
    final response = await _dio.get(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data as Uint8List;
  }

  /// Get thumbnail
  /// GET /_matrix/client/v1/media/thumbnail/{serverName}/{mediaId}
  Future<Uint8List> getThumbnail(
    String mxcUri, {
    int? width,
    int? height,
    String method = 'scale', // 'crop' or 'scale'
  }) async {
    final uri = Uri.parse(mxcUri);
    final serverName = uri.host;
    final mediaId = uri.pathSegments.last;
    
    final response = await _dio.get(
      '/_matrix/client/v1/media/thumbnail/$serverName/$mediaId',
      queryParameters: {
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        'method': method,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data as Uint8List;
  }
}