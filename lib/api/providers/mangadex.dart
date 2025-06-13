import 'dart:convert';

import 'package:http/http.dart' as http;

class Mangadex {
  // Base URL for the MangaDex API
  static const String baseUrl = 'https://api.mangadex.org';

  // Endpoints
  static const String mangaEndpoint = '/manga';
  static const String chapterEndpoint = '/chapter';

  // Common headers for requests
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

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

  Future getMangaInfo(String mangaId) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl$mangaEndpoint/$mangaId?includes[]=cover_art&includes[]=author&includes[]=artist',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load manga info');
    }
  }
}
