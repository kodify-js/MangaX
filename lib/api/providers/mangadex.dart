import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Classes/chapters_class.dart';
import 'base_provider.dart';

class Mangadex extends MangaProvider {
  @override
  String get name => 'MangaDex';

  @override
  String get baseUrl => 'https://api.mangadex.org';

  // Endpoints
  String get mangaEndpoint => '/manga';
  String get chapterEndpoint => '/at-home/server';

  // Supported languages with their display names
  static const Map<String, String> _languages = {
    'en': 'English',
    'ja': 'Japanese',
    'ja-ro': 'Japanese (Romanized)',
    'ko': 'Korean',
    'ko-ro': 'Korean (Romanized)',
    'zh': 'Chinese (Simplified)',
    'zh-hk': 'Chinese (Traditional)',
    'zh-ro': 'Chinese (Romanized)',
    'es': 'Spanish',
    'es-la': 'Spanish (Latin America)',
    'pt': 'Portuguese',
    'pt-br': 'Portuguese (Brazil)',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'ru': 'Russian',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'id': 'Indonesian',
    'ms': 'Malay',
    'th': 'Thai',
    'vi': 'Vietnamese',
    'tr': 'Turkish',
    'pl': 'Polish',
    'uk': 'Ukrainian',
    'nl': 'Dutch',
    'hu': 'Hungarian',
    'el': 'Greek',
    'ro': 'Romanian',
    'cs': 'Czech',
    'sv': 'Swedish',
    'fi': 'Finnish',
    'da': 'Danish',
    'no': 'Norwegian',
    'bg': 'Bulgarian',
    'he': 'Hebrew',
    'fa': 'Persian',
    'bn': 'Bengali',
    'ta': 'Tamil',
    'tl': 'Filipino',
    'my': 'Burmese',
  };

  @override
  Map<String, String> get supportedLanguages => _languages;

  // Current selected language (default: English)
  String _selectedLanguage = 'en';

  @override
  String get selectedLanguage => _selectedLanguage;

  @override
  void setLanguage(String languageCode) {
    _selectedLanguage = languageCode;
  }

  static String getLanguageName(String code) {
    return _languages[code] ?? code.toUpperCase();
  }

  // Common headers for requests
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  List<ChaptersClass> parseChapters(String responseBody) {
    final parsed = jsonDecode(responseBody)['data'] as List;
    return parsed.map<ChaptersClass>((json) {
      return ChaptersClass(
        chapterName: json['attributes']['chapter'],
        chapterId: json['id'],
        chapterUrl: '$baseUrl$chapterEndpoint/${json['id']}',
        translatedLanguage: json['attributes']['translatedLanguage'],
      );
    }).toList();
  }

  // Parse response and return both chapters and total count
  (List<ChaptersClass>, int) parseChaptersWithTotal(String responseBody) {
    final json = jsonDecode(responseBody);
    final parsed = json['data'] as List;
    final total = json['total'] as int? ?? 0;
    final chapters = parsed.map<ChaptersClass>((item) {
      return ChaptersClass(
        chapterName: item['attributes']['chapter'],
        chapterId: item['id'],
        chapterUrl: '$baseUrl$chapterEndpoint/${item['id']}',
        translatedLanguage: item['attributes']['translatedLanguage'],
      );
    }).toList();
    return (chapters, total);
  }

  @override
  Future searchManga(String query) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl$mangaEndpoint?title=$query&limit=5&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&includes[]=cover_art&order[followedCount]=desc&order[relevance]=desc',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load manga');
    }
  }

  @override
  Future<List<ChaptersClass>> getAllChapters(
    String mangaId, {
    int offset = 0,
    String? language,
  }) async {
    final lang = language ?? _selectedLanguage;
    const int limit = 500; // Max allowed by MangaDex API
    List<ChaptersClass> allChapters = [];
    int currentOffset = 0;
    int total = 0;

    do {
      final response = await http.get(
        Uri.parse(
          '$baseUrl$mangaEndpoint/$mangaId/feed?offset=$currentOffset&limit=$limit&order[chapter]=desc&includes[]=scanlation_group&includes[]=user&translatedLanguage[]=$lang',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final (chapters, totalCount) = parseChaptersWithTotal(response.body);
        allChapters.addAll(chapters);
        total = totalCount;
        currentOffset += limit;
      } else {
        throw Exception('Failed to load chapters');
      }
    } while (currentOffset < total);

    return allChapters;
  }

  // Get chapters for all languages with pagination (useful for showing available languages)
  Future<List<ChaptersClass>> getAllChaptersAllLanguages(
    String mangaId, {
    int offset = 0,
  }) async {
    const int limit = 500;
    List<ChaptersClass> allChapters = [];
    int currentOffset = 0;
    int total = 0;

    do {
      final response = await http.get(
        Uri.parse(
          '$baseUrl$mangaEndpoint/$mangaId/feed?offset=$currentOffset&limit=$limit&order[chapter]=desc&includes[]=scanlation_group&includes[]=user',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final (chapters, totalCount) = parseChaptersWithTotal(response.body);
        allChapters.addAll(chapters);
        total = totalCount;
        currentOffset += limit;
      } else {
        throw Exception('Failed to load chapters');
      }
    } while (currentOffset < total);

    return allChapters;
  }

  // Get available languages for a manga
  Future<Set<String>> getAvailableLanguages(String mangaId) async {
    final chapters = await getAllChaptersAllLanguages(mangaId);
    return chapters
        .where((c) => c.translatedLanguage != null)
        .map((c) => c.translatedLanguage!)
        .toSet();
  }

  @override
  Future<List<ChaptersClass>> getChapters(String query, {String? language}) async {
    try {
      final search = await searchManga(query);
      if (search['data'] == null || search['data'].isEmpty) {
        return [];
      }
      final mangaId = search['data'][0]['id'];
      return await getAllChapters(mangaId, language: language);
    } catch (e) {
      throw Exception('Failed to get chapters: $e');
    }
  }

  @override
  Future<List<String>> getChapterPages(String chapterId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$chapterEndpoint/$chapterId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final baseImageUrl = data['baseUrl'];
        final chapterHash = data['chapter']['hash'];
        final pageFilenames = data['chapter']['data'] as List;
        
        return pageFilenames.map<String>((filename) {
          return '$baseImageUrl/data/$chapterHash/$filename';
        }).toList();
      } else {
        throw Exception('Failed to load chapter pages');
      }
    } catch (e) {
      throw Exception('Failed to get chapter pages: $e');
    }
  }
}
