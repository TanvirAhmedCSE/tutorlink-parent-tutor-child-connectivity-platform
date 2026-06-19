import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;

enum CloudinaryFolder {
  chatImages,
  chatFiles,
  assignmentImages,
  assignmentFiles,
  submissionImages,
  submissionFiles,
}

class CloudinaryUploadResult {
  final String url;
  final String publicId;
  final String resourceType;
  final String format;
  final String originalFilename;

  CloudinaryUploadResult({
    required this.url,
    required this.publicId,
    required this.resourceType,
    required this.format,
    required this.originalFilename,
  });
}

class CloudinaryService {
  static const String _cloudName = 'XXXXXXXXX';
  static const String _uploadPreset = 'XXXXXXX'; // unsigned preset

  static String _folderName(CloudinaryFolder folder) {
    switch (folder) {
      case CloudinaryFolder.chatImages:
        return 'tutorlink/chat/images';
      case CloudinaryFolder.chatFiles:
        return 'tutorlink/chat/files';
      case CloudinaryFolder.assignmentImages:
        return 'tutorlink/assignments/images';
      case CloudinaryFolder.assignmentFiles:
        return 'tutorlink/assignments/files';
      case CloudinaryFolder.submissionImages:
        return 'tutorlink/submissions/images';
      case CloudinaryFolder.submissionFiles:
        return 'tutorlink/submissions/files';
    }
  }

  static String _resourceType(File file) {
    final ext = path.extension(file.path).toLowerCase().replaceAll('.', '');
    const imageExts = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'heic',
      'heif',
    ];
    if (imageExts.contains(ext)) return 'image';
    return 'raw'; // for pdf, docx, txt, zip etc.
  }

  static MediaType _mediaType(File file) {
    final ext = path.extension(file.path).toLowerCase().replaceAll('.', '');
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'docx':
        return MediaType(
          'application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document',
        );
      case 'txt':
        return MediaType('text', 'plain');
      case 'zip':
        return MediaType('application', 'zip');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  static Future<CloudinaryUploadResult> uploadFile(
    File file,
    CloudinaryFolder folder,
  ) async {
    // Auto-correct folder: if caller passed an image folder but file is raw, use sibling files folder
    final resourceType = _resourceType(file);
    CloudinaryFolder resolvedFolder = folder;
    if (resourceType == 'raw') {
      // map image folder: file folder
      if (folder == CloudinaryFolder.chatImages)
        resolvedFolder = CloudinaryFolder.chatFiles;
      else if (folder == CloudinaryFolder.assignmentImages)
        resolvedFolder = CloudinaryFolder.assignmentFiles;
      else if (folder == CloudinaryFolder.submissionImages)
        resolvedFolder = CloudinaryFolder.submissionFiles;
    }

    final folderName = _folderName(resolvedFolder);
    final filename = path.basename(file.path);

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folderName
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: filename,
          contentType: _mediaType(file),
        ),
      );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed: $responseBody');
    }

    final json = jsonDecode(responseBody) as Map<String, dynamic>;

    return CloudinaryUploadResult(
      url: json['secure_url'] as String,
      publicId: json['public_id'] as String,
      resourceType: json['resource_type'] as String,
      format: json['format'] as String? ?? '',
      originalFilename: filename,
    );
  }

  // Upload multiple files, returns list of results
  static Future<List<CloudinaryUploadResult>> uploadFiles(
    List<File> files,
    CloudinaryFolder folder,
  ) async {
    final results = <CloudinaryUploadResult>[];
    for (final file in files) {
      final result = await uploadFile(file, folder);
      results.add(result);
    }
    return results;
  }
}
