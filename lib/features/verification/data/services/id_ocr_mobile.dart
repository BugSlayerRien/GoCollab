import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

Future<String?> readText(XFile image) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(InputImage.fromFilePath(image.path));
    return result.text;
  } catch (_) {
    return null;
  } finally {
    await recognizer.close();
  }
}
