import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class FileHelper {
  /// Convert asset image to File object for upload
  /// Uses a simpler approach without path_provider
  /// 
  /// Example:
  /// ```dart
  /// final file = await FileHelper.assetToFile('assets/svg_images/A.png');
  /// ```
  static Future<File?> assetToFile(String assetPath) async {
    try {
      // Load asset as bytes
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      
      // Extract filename from asset path
      final String fileName = assetPath.split('/').last;
      
      // Create file in system temp directory
      final String tempPath = Directory.systemTemp.path;
      final File file = File('$tempPath/$fileName');
      
      // Write bytes to file
      await file.writeAsBytes(bytes);
      
      print('✅ Asset converted to file: ${file.path}');
      return file;
    } catch (e) {
      print('❌ Error converting asset to file: $e');
      return null;
    }
  }
  
  /// Create MultipartFile directly from asset bytes
  /// This is more efficient as it doesn't create a temp file
  /// 
  /// Example:
  /// ```dart
  /// final multipartFile = await FileHelper.assetToMultipartFile(
  ///   'assets/svg_images/A.png',
  ///   'avatar_logo'
  /// );
  /// ```
  static Future<http.MultipartFile?> assetToMultipartFile(
    String assetPath,
    String fieldName,
  ) async {
    try {
      // Load asset as bytes
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      
      // Extract filename from asset path
      final String fileName = assetPath.split('/').last;
      
      // Create multipart file from bytes
      final multipartFile = http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: fileName,
      );
      
      print('✅ Asset converted to MultipartFile: $fileName');
      return multipartFile;
    } catch (e) {
      print('❌ Error converting asset to MultipartFile: $e');
      return null;
    }
  }
  
  /// Check if a path is an asset path or a file path
  static bool isAssetPath(String path) {
    return path.startsWith('assets/');
  }
  
  /// Check if a path is a URL
  static bool isUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }
}
