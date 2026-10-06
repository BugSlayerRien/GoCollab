import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Uploads media to Supabase Storage buckets used by the app.
class StorageService {
  StorageService(this._client);

  final SupabaseClient _client;

  static const _eventBannersBucket = 'event-banners';
  static const _avatarsBucket = 'avatars';
  static const _verificationDocsBucket = 'verification-docs';

  /// Uploads a profile avatar and returns its public URL.
  Future<String> uploadAvatar({
    required XFile file,
    required String userId,
  }) async {
    final bytes = await file.readAsBytes();
    final contentType = _contentTypeForFile(file);
    final extension = _extensionForContentType(contentType);
    final objectPath = '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _client.storage.from(_avatarsBucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return _client.storage.from(_avatarsBucket).getPublicUrl(objectPath);
  }

  /// Uploads an event banner and returns its public URL.
  Future<String> uploadEventBanner({
    required XFile file,
    String? eventId,
  }) async {
    final bytes = await file.readAsBytes();
    final contentType = _contentTypeForFile(file);
    final extension = _extensionForContentType(contentType);
    final objectPath = '${eventId ?? const Uuid().v4()}/${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _client.storage.from(_eventBannersBucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return _client.storage.from(_eventBannersBucket).getPublicUrl(objectPath);
  }

  /// Uploads a student ID photo to the PRIVATE verification bucket and
  /// returns its object path (not a URL — this bucket has no public URLs).
  /// Storage RLS keys off the `<user-id>/` prefix, so the path shape matters.
  Future<String> uploadVerificationDocument({
    required XFile file,
    required String userId,
  }) async {
    final bytes = await file.readAsBytes();
    final contentType = _contentTypeForFile(file);
    final extension = _extensionForContentType(contentType);
    final objectPath = '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _client.storage.from(_verificationDocsBucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return objectPath;
  }

  /// Time-limited URL so officers can view a submitted ID without the
  /// bucket ever being public. Defaults to 5 minutes.
  Future<String> signedVerificationDocumentUrl(String objectPath, {int expiresInSeconds = 300}) {
    return _client.storage.from(_verificationDocsBucket).createSignedUrl(objectPath, expiresInSeconds);
  }

  String _contentTypeForFile(XFile file) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  String _extensionForContentType(String contentType) => switch (contentType) {
        'image/png' => 'png',
        'image/webp' => 'webp',
        'image/gif' => 'gif',
        _ => 'jpg',
      };
}
