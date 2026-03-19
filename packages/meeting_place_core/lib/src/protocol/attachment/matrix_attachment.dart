import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

/// Attachment for Matrix Content Repository media
/// Supports Matrix mxc:// URIs and additional metadata
class MatrixAttachment extends Attachment {
  /// Matrix Content Repository URI (mxc://server/mediaId)
  final String? mxcUri;
  
  /// Size of the file in bytes
  final int? byteCount;
  
  /// Hash of the file content
  final String? hash;

  MatrixAttachment({
    super.id,
    super.description,
    super.mediaType,
    super.format,
    super.data,
    String? filename,
    this.mxcUri,
    this.byteCount,
    this.hash,
  }) : super(filename: filename);

  /// Create a MatrixAttachment for uploaded content
  factory MatrixAttachment.fromUpload({
    required String mxcUri,
    required String filename,
    required String contentType,
    String? format,
    int? byteCount,
    String? hash,
    String? description,
    AttachmentData? data,
  }) {
    return MatrixAttachment(
      id: const Uuid().v4(),
      mxcUri: mxcUri,
      filename: filename,
      mediaType: contentType,
      format: format,
      byteCount: byteCount,
      hash: hash,
      description: description,
      data: data,
    );
  }

  /// Create a MatrixAttachment for download reference (without data)
  factory MatrixAttachment.reference({
    required String mxcUri,
    required String filename,
    required String contentType,
    String? format,
    int? byteCount,
    String? hash,
    String? description,
  }) {
    return MatrixAttachment(
      id: const Uuid().v4(),
      mxcUri: mxcUri,
      filename: filename,
      mediaType: contentType,
      format: format,
      byteCount: byteCount,
      hash: hash,
      description: description,
    );
  }

  /// Copy with new data (e.g., after downloading)
  MatrixAttachment copyWith({
    String? id,
    String? description,
    String? filename,
    String? mediaType,
    String? format,
    AttachmentData? data,
    String? mxcUri,
    int? byteCount,
    String? hash,
  }) {
    return MatrixAttachment(
      id: id ?? this.id,
      description: description ?? this.description,
      filename: filename ?? this.filename,
      mediaType: mediaType ?? this.mediaType,
      format: format ?? this.format,
      data: data ?? this.data,
      mxcUri: mxcUri ?? this.mxcUri,
      byteCount: byteCount ?? this.byteCount,
      hash: hash ?? this.hash,
    );
  }
}
