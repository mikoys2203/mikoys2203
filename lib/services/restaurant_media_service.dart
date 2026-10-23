
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RestaurantMediaService {
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<String> uploadImage({
    required Uint8List bytes,
    required String contentType,
    required String extension,
  }) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    if (bytes.isEmpty || bytes.lengthInBytes > 4 * 1024 * 1024) {
      throw Exception('Image must be smaller than 4 MB.');
    }

    if (!['jpg', 'png', 'webp'].contains(extension)) {
      throw Exception('Unsupported image format.');
    }

    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}.$extension';

    final reference = storage.ref().child(
      'restaurant_media/${user.uid}/$fileName',
    );

    final task = reference.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );

    await task;

    return await reference.getDownloadURL();
  }
}
