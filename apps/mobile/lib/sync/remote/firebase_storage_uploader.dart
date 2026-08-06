import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import 'storage_uploader.dart';

/// Uploads real files to Firebase Storage.
///
/// Demo `local://` paths skip the network and return a `demo://` URL so Fake
/// evidence capture still flushes cleanly when Firebase is enabled.
class FirebaseStorageUploader implements StorageUploader {
  FirebaseStorageUploader({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<String> upload(StorageUploadRequest request) async {
    final path = request.localPath;
    if (path.startsWith('local://') || path.startsWith('demo://')) {
      return 'demo://storage/${request.storagePath}';
    }

    final file = File(path);
    if (!await file.exists()) {
      throw StateError('Local file missing for upload: $path');
    }

    final ref = _storage.ref(request.storagePath);
    await ref.putFile(
      file,
      SettableMetadata(contentType: request.contentType),
    );
    return ref.getDownloadURL();
  }
}
