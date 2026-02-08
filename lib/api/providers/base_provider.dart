import '../../Classes/chapters_class.dart';

abstract class MangaProvider {
  String get name;
  String get baseUrl;

  Future<List<ChaptersClass>> getAllChapters(
    String mangaId, {
    int offset = 0,
    String? language,
  });
  Future<List<ChaptersClass>> getChapters(String query, {String? language});
  Future searchManga(String query);
  Future<List<String>> getChapterPages(String chapterId);

  // Image headers - providers can override to add custom headers for image requests
  Map<String, String> getImageHeaders(String imageUrl) => {};

  // Language support - providers can override these
  String get selectedLanguage => 'en';
  void setLanguage(String languageCode) {}
  Map<String, String> get supportedLanguages => {'en': 'English'};
}
