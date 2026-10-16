# google_mlkit_text_recognition references optional script recognizers
# (Chinese/Japanese/Korean/Devanagari). We only bundle and use Latin, so
# R8 should ignore the missing classes instead of failing the release build.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
