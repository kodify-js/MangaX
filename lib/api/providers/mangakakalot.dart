import 'dart:math';

import 'package:html/parser.dart';

import '../../Classes/chapters_class.dart';
import 'base_provider.dart';
import 'package:http/http.dart' as http;

class MangaKakalot extends MangaProvider {
  @override
  String get name => 'MangaKakalot';

  @override
  String get baseUrl => 'https://www.mangakakalove.com/';

  @override
  Future searchManga(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/search/story/$query'));
    print(response.body);
    final document = parse(response.body);
    final searchResults = document.querySelectorAll("div.panel_story_list div.story_item").map((element) {
      print(element);
      final titleElement = element.querySelector('h3.story_name a');
      final title = titleElement?.text.trim() ?? 'No Title';
      final url = titleElement?.attributes['href'] ?? '';
      final id = url.split('/').last;
      return {
        'id': id,
        'title': title,
        'url': url,
      };
    }).toList();
    return searchResults;
  }

  @override
  Future<List<ChaptersClass>> getAllChapters(
    String mangaId, {
    int offset = 0,
    String? language,
  }) async {
    final response = await http.get(Uri.parse('$baseUrl/manga/$mangaId'));
    final document = parse(response.body);
    final chapterElements = document.querySelectorAll('div.chapter-list div.row span a').map((element) {
      final chapterName = element.text.trim();
      final chapterUrl = element.attributes['href'] ?? '';
      final chapterId = chapterUrl.split('/').last;
      return ChaptersClass(
        chapterName: chapterName,
        chapterId: 'mk_$chapterId',
        chapterUrl: chapterUrl,
        translatedLanguage: 'en',
      );
    }).toList();
    return chapterElements.toList();
  }

  //get best matching manga id from search and then get chapters

  String getBestMatchingMangaId(List<dynamic> searchResults, String query) {
    String lowerQuery = query.toLowerCase();
    for (var result in searchResults) {
      if (result['title'].toLowerCase() == lowerQuery) {
        return result['id'];
      }
    }
    // If no exact match, return the first result
    return searchResults.isNotEmpty ? searchResults[0]['id'] : '';
  }

  @override
  Future<List<ChaptersClass>> getChapters(String query, {String? language}) async {
    final searchResults = await searchManga(query);
    if (searchResults.isEmpty) {
      return [];
    }
    final mangaId = getBestMatchingMangaId(searchResults, query);
    return await getAllChapters(mangaId);
  }

  @override
  Future<List<String>> getChapterPages(String chapterId) async {
    final response = await http.get(Uri.parse('$baseUrl/manga/$chapterId'));
    final document = parse(response.body);
    final pageElements = document.querySelectorAll('div.container-chapter-reader img').map((element) {
      return element.attributes['src'] ?? '';
    }).toList();
    return pageElements;
  }
}
