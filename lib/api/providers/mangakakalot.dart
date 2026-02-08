import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:html/parser.dart';

import '../../Classes/chapters_class.dart';
import 'base_provider.dart';
import 'package:http/http.dart' as http;

class MangaKakalot extends MangaProvider {
  @override
  String get name => 'MangaKakalot';

  @override
  String get baseUrl => 'https://www.mangakakalove.com';

  @override
  Future searchManga(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/home/search/json?searchword=$query'),
      headers: {
        'accept': 'application/json, text/javascript, */*; q=0.01',
        'accept-encoding': 'gzip, deflate, br, zstd',
        'accept-language':
            'en-US,en;q=0.9,en-IN;q=0.8,zh;q=0.7,zh-CN;q=0.6,zh-TW;q=0.5,da;q=0.4',
        'cache-control': 'no-cache',
        'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'pragma': 'no-cache',
        'priority': 'u=1, i',
        'referer': 'https://www.mangakakalove.com/search/story/$query',
        'sec-ch-ua':
            '"Not(A:Brand";v="8", "Chromium";v="144", "Microsoft Edge";v="144"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"',
        'sec-fetch-dest': 'empty',
        'sec-fetch-mode': 'cors',
        'sec-fetch-site': 'same-origin',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0',
        'x-requested-with': 'XMLHttpRequest',
      },
    );
    return response.statusCode == 200
        ? List.from(json.decode(response.body))
        : [];
  }

  @override
  Future<List<ChaptersClass>> getAllChapters(
    String mangaId, {
    int offset = 0,
    String? language,
  }) async {
    List<ChaptersClass> allChapters = [];
    int currentOffset = 0;
    const int limit = 100;
    bool hasMoreChapters = true;

    print('Loading all chapters for manga: $mangaId');

    while (hasMoreChapters) {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/manga/$mangaId/chapters?limit=$limit&offset=$currentOffset',
        ),
        headers: {
          'accept': 'application/json, text/javascript, */*; q=0.01',
          'accept-encoding': 'gzip, deflate, br, zstd',
          'accept-language':
              'en-US,en;q=0.9,en-IN;q=0.8,zh;q=0.7,zh-CN;q=0.6,zh-TW;q=0.5,da;q=0.4',
          'cache-control': 'no-cache',
          'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'pragma': 'no-cache',
          'priority': 'u=1, i',
          'referer': 'https://www.mangakakalove.com/manga/$mangaId',
          'sec-ch-ua':
              '"Not(A:Brand";v="8", "Chromium";v="144", "Microsoft Edge";v="144"',
          'sec-ch-ua-mobile': '?0',
          'sec-ch-ua-platform': '"Windows"',
          'sec-fetch-dest': 'empty',
          'sec-fetch-mode': 'cors',
          'sec-fetch-site': 'same-origin',
          'user-agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0',
          'x-requested-with': 'XMLHttpRequest',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true &&
            data['data'] != null &&
            data['data']['chapters'] != null) {
          final chaptersData = data['data']['chapters'] as List;

          if (chaptersData.isEmpty) {
            hasMoreChapters = false;
          } else {
            final chapters =
                chaptersData.map((chapter) {
                  return ChaptersClass(
                    chapterId: "$mangaId/${chapter['chapter_slug']}",
                    chapterNumber: chapter['chapterNumber'],
                    chapterName: chapter['chapter_name'],
                    chapterUrl: chapter['chapter_slug'],
                  );
                }).toList();

            allChapters.addAll(chapters);
            print(
              'Loaded ${chapters.length} chapters (offset: $currentOffset, total: ${allChapters.length})',
            );

            // If we got fewer chapters than the limit, we've reached the end
            if (chaptersData.length < limit) {
              hasMoreChapters = false;
            } else {
              currentOffset += limit;
            }
          }
        } else {
          hasMoreChapters = false;
        }
      } else {
        print('Failed to fetch chapters: ${response.statusCode}');
        hasMoreChapters = false;
      }
    }

    print('Total chapters loaded from MangaKakalot: ${allChapters.length}');
    return allChapters;
  }

  //get best matching manga id from search and then get chapters

  String getBestMatchingMangaId(List<dynamic> searchResults, String query) {
    String lowerQuery = query.toLowerCase();
    for (var result in searchResults) {
      if (result['name'].toLowerCase() == lowerQuery) {
        return result['url'].split('/').last;
      }
    }
    // If no exact match, return the first result
    return searchResults.isNotEmpty
        ? searchResults[0]['url'].split('/').last
        : '';
  }

  @override
  Future<List<ChaptersClass>> getChapters(
    String query, {
    String? language,
  }) async {
    final searchResults = await searchManga(query);
    if (searchResults.isEmpty) {
      return [];
    }
    final mangaId = getBestMatchingMangaId(searchResults, query);
    print(mangaId);
    return await getAllChapters(mangaId);
  }

  @override
  Future<List<String>> getChapterPages(String chapterId) async {
    print('$baseUrl/manga/$chapterId');
    final response = await http.get(Uri.parse('$baseUrl/manga/$chapterId'));

    final document = parse(response.body);
    final pageElements =
        document.querySelectorAll('div.container-chapter-reader img').map((
          element,
        ) {
          return element.attributes['src'] ?? '';
        }).toList();
    return pageElements;
  }

  @override
  Map<String, String> getImageHeaders(String imageUrl) {
    return {
      'accept':
          'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
      'accept-encoding': 'gzip, deflate, br, zstd',
      'accept-language':
          'en-US,en;q=0.9,en-IN;q=0.8,zh;q=0.7,zh-CN;q=0.6,zh-TW;q=0.5,da;q=0.4',
      'cache-control': 'no-cache',
      'pragma': 'no-cache',
      'priority': 'i',
      'referer': 'https://www.mangakakalove.com/',
      'sec-ch-ua':
          '"Not(A:Brand";v="8", "Chromium";v="144", "Microsoft Edge";v="144"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': '"Windows"',
      'sec-fetch-dest': 'image',
      'sec-fetch-mode': 'no-cors',
      'sec-fetch-site': 'cross-site',
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0',
    };
  }
}
