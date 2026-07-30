import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

abstract interface class ImagePickerService {
  Future<XFile?> pick({required bool useCamera});
}

class PlatformImagePickerService implements ImagePickerService {
  PlatformImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  @override
  Future<XFile?> pick({required bool useCamera}) {
    final unsupportedDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
    final source = useCamera && !unsupportedDesktop
        ? ImageSource.camera
        : ImageSource.gallery;
    return _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
  }
}
