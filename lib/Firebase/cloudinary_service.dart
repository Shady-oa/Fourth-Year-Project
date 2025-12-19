import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  final String backendUrl; // your Render backend URL

  CloudinaryService({required this.backendUrl});

  /// Pick image from gallery or camera
  Future<File?> pickImage({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
//walai tena
  /// Fetch Cloudinary signature from backend
  Future<Map<String, dynamic>?> getSignature() async {
    final url = Uri.parse('$backendUrl/generate-signature');

    final response = await http.post(url); // POST because backend expects POST
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Failed to get Cloudinary signature: ${response.body}');
      return null;
    }
  }

  /// Upload file to Cloudinary
  Future<String?> uploadFile(File file) async {
    final signatureData = await getSignature();
    if (signatureData == null) return null;

    final cloudName = signatureData['cloud_name'];
    final apiKey = signatureData['api_key'];
    final timestamp = signatureData['timestamp'];
    final signature = signatureData['signature'];

    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
    final fileName = path.basename(file.path);

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);
    request.fields['api_key'] = apiKey;
    request.fields['timestamp'] = timestamp.toString();
    request.fields['signature'] = signature;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('image', mimeType.split('/')[1]),
        filename: fileName,
      ),
    );

    final response = await request.send();
    if (response.statusCode == 200 || response.statusCode == 201) {
      final resStr = await response.stream.bytesToString();
      final resJson = jsonDecode(resStr);
      return resJson['secure_url']; // Return uploaded image URL
    } else {
      print('Cloudinary upload failed: ${response.statusCode}');
      return null;
    }
  }
}
