import 'dart:convert';
import 'package:mangax/Classes/character_class.dart';
import 'package:mangax/Classes/manga_class.dart';
import 'package:http/http.dart' as http;

class Api {
  Api();

  // MangaDex API base URL
  static const String _mangaDexBaseUrl = 'https://api.mangadex.org';

  // Rate limiting for MangaDex
  static DateTime? _lastMangaDexRequestTime;
  static const Duration _minMangaDexInterval = Duration(
    milliseconds: 500,
  ); // 500ms between MangaDex requests

  // Rate limiting method for MangaDex requests
  Future<void> _throttleMangaDexRequest() async {
    if (_lastMangaDexRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(
        _lastMangaDexRequestTime!,
      );
      if (timeSinceLastRequest < _minMangaDexInterval) {
        final waitTime = _minMangaDexInterval - timeSinceLastRequest;
        print(
          "Throttling MangaDex request, waiting ${waitTime.inMilliseconds}ms",
        );
        await Future.delayed(waitTime);
      }
    }
    _lastMangaDexRequestTime = DateTime.now();
  }

  // Fetch statistics for multiple manga (ratings, follows, etc.)
  Future<Map<String, double>> _getMangaStatistics(List<String> mangaIds) async {
    if (mangaIds.isEmpty) return {};
    
    try {
      await _throttleMangaDexRequest();
      
      final uri = Uri.parse('$_mangaDexBaseUrl/statistics/manga').replace(
        queryParameters: {
          'manga[]': mangaIds,
        },
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final statistics = data['statistics'] as Map<String, dynamic>? ?? {};
        Map<String, double> ratings = {};
        
        for (var entry in statistics.entries) {
          final mangaId = entry.key;
          final stats = entry.value as Map<String, dynamic>? ?? {};
          final rating = stats['rating'] as Map<String, dynamic>? ?? {};
          final average = rating['average'];
          if (average != null) {
            ratings[mangaId] = (average as num).toDouble();
          }
        }
        return ratings;
      }
    } catch (e) {
      print("Error fetching manga statistics: $e");
    }
    return {};
  }

  // Parse MangaDex manga data into MangaClass
  List<MangaClass> parseMangaDexData(List mangaList, [Map<String, String>? coverArtMap, Map<String, double>? ratingsMap]) {
    List<MangaClass> result = [];
    for (var item in mangaList) {
      final attributes = item['attributes'] ?? {};
      final relationships = item['relationships'] as List? ?? [];
      
      // Get title (prefer English, fallback to other languages)
      String title = '';
      final titles = attributes['title'] as Map<String, dynamic>? ?? {};
      title = titles['en'] ?? 
              titles['ja-ro'] ?? 
              titles['ja'] ?? 
              titles.values.firstOrNull?.toString() ?? 
              'Unknown Title';

      // Get description
      String description = '';
      final descriptions = attributes['description'] as Map<String, dynamic>? ?? {};
      description = descriptions['en'] ?? 
                    descriptions.values.firstOrNull?.toString() ?? 
                    '';

      // Get cover art
      String coverImage = '';
      String? coverArtId;
      for (var rel in relationships) {
        if (rel['type'] == 'cover_art') {
          coverArtId = rel['id'];
          if (rel['attributes'] != null && rel['attributes']['fileName'] != null) {
            coverImage = 'https://uploads.mangadex.org/covers/${item['id']}/${rel['attributes']['fileName']}';
          }
          break;
        }
      }
      // Use coverArtMap if available and coverImage is still empty
      if (coverImage.isEmpty && coverArtId != null && coverArtMap != null) {
        coverImage = coverArtMap[coverArtId] ?? '';
      }

      // Get author
      String author = '';
      for (var rel in relationships) {
        if (rel['type'] == 'author') {
          if (rel['attributes'] != null && rel['attributes']['name'] != null) {
            author = rel['attributes']['name'];
          }
          break;
        }
      }

      // Get genres/tags
      List<String> genres = [];
      final tags = attributes['tags'] as List? ?? [];
      for (var tag in tags) {
        final tagName = tag['attributes']?['name']?['en'];
        if (tagName != null) {
          genres.add(tagName);
        }
      }

      // Get alternate titles
      List<String> synonyms = [];
      final altTitles = attributes['altTitles'] as List? ?? [];
      for (var altTitle in altTitles) {
        if (altTitle is Map) {
          synonyms.addAll(altTitle.values.map((e) => e.toString()));
        }
      }

      // Map MangaDex status to similar format
      String status = attributes['status']?.toString().toUpperCase() ?? 'UNKNOWN';

      // Get rating from ratingsMap if available
      double rating = 0.0;
      final mangaId = item['id'] as String?;
      if (ratingsMap != null && mangaId != null && ratingsMap.containsKey(mangaId)) {
        rating = ratingsMap[mangaId]!;
      }

      MangaClass manga = MangaClass(
        id: 'mdx_${item['id']}', // Prefix with mdx_ to identify MangaDex source
        title: title,
        coverImage: coverImage,
        description: description,
        status: status,
        author: author,
        genre: genres.isNotEmpty ? genres : ['Unknown'],
        chaptersCount: attributes['lastChapter'] != null 
            ? int.tryParse(attributes['lastChapter'].toString()) ?? 0 
            : 0,
        color: '',
        bannerImage: '',
        rating: rating,
        characters: [],
        recommendations: [],
        synonyms: synonyms,
      );
      result.add(manga);
    }
    return result;
  }

  // Get trending manga from MangaDex
  Future<List<MangaClass>> getTrendingMangaDex({int page = 1, int perPage = 10}) async {
    await _throttleMangaDexRequest();
    
    final offset = (page - 1) * perPage;
    final uri = Uri.parse('$_mangaDexBaseUrl/manga').replace(
      queryParameters: {
        'limit': perPage.toString(),
        'offset': offset.toString(),
        'order[followedCount]': 'desc',
        'order[rating]': 'desc',
        'includes[]': ['cover_art', 'author'],
        'contentRating[]': ['safe', 'suggestive'],
        'hasAvailableChapters': 'true',
      },
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final mangaList = data['data'] as List;
      
      // Extract manga IDs for statistics fetch
      final mangaIds = mangaList.map((m) => m['id'] as String).toList();
      final ratingsMap = await _getMangaStatistics(mangaIds);
      
      return parseMangaDexData(mangaList, null, ratingsMap);
    } else {
      throw Exception("Failed to load trending manga from MangaDex: ${response.statusCode}");
    }
  }

  // Get popular manga from MangaDex
  Future<List<MangaClass>> getPopularMangaDex({int page = 1, int perPage = 10}) async {
    await _throttleMangaDexRequest();
    
    final offset = (page - 1) * perPage;
    final uri = Uri.parse('$_mangaDexBaseUrl/manga').replace(
      queryParameters: {
        'limit': perPage.toString(),
        'offset': offset.toString(),
        'order[followedCount]': 'desc',
        'includes[]': ['cover_art', 'author'],
        'contentRating[]': ['safe', 'suggestive'],
        'hasAvailableChapters': 'true',
      },
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final mangaList = data['data'] as List;
      
      // Extract manga IDs for statistics fetch
      final mangaIds = mangaList.map((m) => m['id'] as String).toList();
      final ratingsMap = await _getMangaStatistics(mangaIds);
      
      return parseMangaDexData(mangaList, null, ratingsMap);
    } else {
      throw Exception("Failed to load popular manga from MangaDex: ${response.statusCode}");
    }
  }

  // Search manga on MangaDex
  Future<List<MangaClass>> searchMangaDex({
    String? query,
    int page = 1,
    int perPage = 30,
    String? status,
    List<String>? includedTags,
    List<String>? excludedTags,
    String? contentRating,
    String? originalLanguage,
    String? orderBy,
  }) async {
    await _throttleMangaDexRequest();
    
    final offset = (page - 1) * perPage;
    Map<String, dynamic> queryParams = {
      'limit': perPage.toString(),
      'offset': offset.toString(),
      'includes[]': ['cover_art', 'author'],
      'contentRating[]': contentRating != null ? [contentRating] : ['safe', 'suggestive'],
    };

    if (query != null && query.isNotEmpty) {
      queryParams['title'] = query;
    }

    if (status != null && status.isNotEmpty) {
      queryParams['status[]'] = [status.toLowerCase()];
    }

    if (originalLanguage != null && originalLanguage.isNotEmpty) {
      queryParams['originalLanguage[]'] = [originalLanguage];
    }

    // Set ordering
    if (orderBy != null) {
      switch (orderBy.toUpperCase()) {
        case 'POPULARITY_DESC':
          queryParams['order[followedCount]'] = 'desc';
          break;
        case 'RATING_DESC':
          queryParams['order[rating]'] = 'desc';
          break;
        case 'LATEST_UPLOAD_DESC':
          queryParams['order[latestUploadedChapter]'] = 'desc';
          break;
        case 'TITLE_ASC':
          queryParams['order[title]'] = 'asc';
          break;
        case 'CREATED_AT_DESC':
          queryParams['order[createdAt]'] = 'desc';
          break;
        default:
          queryParams['order[relevance]'] = 'desc';
      }
    } else {
      queryParams['order[relevance]'] = 'desc';
    }

    final uri = Uri.parse('$_mangaDexBaseUrl/manga').replace(
      queryParameters: queryParams.map((key, value) => 
        MapEntry(key, value is List ? value : value.toString())),
    );

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final response = await http.get(
          uri,
          headers: {'Accept': 'application/json'},
        ).timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final mangaList = data['data'] as List;
          
          // Extract manga IDs for statistics fetch
          final mangaIds = mangaList.map((m) => m['id'] as String).toList();
          final ratingsMap = await _getMangaStatistics(mangaIds);
          
          return parseMangaDexData(mangaList, null, ratingsMap);
        } else if (response.statusCode == 429) {
          retryCount++;
          final waitTime = Duration(seconds: retryCount * 3);
          print("MangaDex rate limited, waiting ${waitTime.inSeconds}s before retry");
          await Future.delayed(waitTime);
          continue;
        } else {
          throw Exception("Failed to search manga on MangaDex: ${response.statusCode}");
        }
      } catch (e) {
        if (e.toString().contains('TimeoutException')) {
          retryCount++;
          if (retryCount >= maxRetries) {
            throw Exception("MangaDex request timeout after $maxRetries retries");
          }
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        }
        rethrow;
      }
    }
    throw Exception("Max retries exceeded for MangaDex");
  }

  // Get manga details from MangaDex
  Future<MangaClass> getMangaDetailsMangaDex(String mangaId) async {
    await _throttleMangaDexRequest();
    
    // Remove mdx_ prefix if present
    final cleanId = mangaId.startsWith('mdx_') ? mangaId.substring(4) : mangaId;
    
    final uri = Uri.parse('$_mangaDexBaseUrl/manga/$cleanId').replace(
      queryParameters: {
        'includes[]': ['cover_art', 'author', 'artist'],
      },
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Fetch rating for this manga
      final ratingsMap = await _getMangaStatistics([cleanId]);
      final manga = parseMangaDexData([data['data']], null, ratingsMap).first;
      
      // Fetch related manga based on similar tags
      try {
        final relatedManga = await getRelatedMangaMangaDex(cleanId);
        manga.recommendations = relatedManga.map((m) => RelatedManga(
          id: m.id,
          title: m.title,
          coverImage: m.coverImage,
        )).toList();
      } catch (e) {
        print("Failed to fetch related manga: $e");
        manga.recommendations = [];
      }
      
      return manga;
    } else {
      throw Exception("Failed to load manga details from MangaDex: ${response.statusCode}");
    }
  }

  // Get related/similar manga from MangaDex
  Future<List<MangaClass>> getRelatedMangaMangaDex(String mangaId, {int limit = 10}) async {
    await _throttleMangaDexRequest();
    
    // Remove mdx_ prefix if present
    final cleanId = mangaId.startsWith('mdx_') ? mangaId.substring(4) : mangaId;
    
    // First get the manga to find its tags
    final mangaUri = Uri.parse('$_mangaDexBaseUrl/manga/$cleanId');
    final mangaResponse = await http.get(
      mangaUri,
      headers: {'Accept': 'application/json'},
    );
    
    if (mangaResponse.statusCode != 200) {
      return [];
    }
    
    final mangaData = jsonDecode(mangaResponse.body);
    final attributes = mangaData['data']['attributes'] ?? {};
    final tags = attributes['tags'] as List? ?? [];
    
    // Get tag IDs for searching similar manga
    List<String> tagIds = [];
    for (var tag in tags) {
      if (tag['id'] != null) {
        tagIds.add(tag['id']);
      }
      if (tagIds.length >= 3) break; // Limit to 3 tags for better results
    }
    
    if (tagIds.isEmpty) {
      return [];
    }
    
    await _throttleMangaDexRequest();
    
    // Search for manga with similar tags
    // Build query string manually for proper array parameter handling
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'includedTagsMode': 'OR',
      'order[followedCount]': 'desc',
      'hasAvailableChapters': 'true',
    };
    
    // Build the full URL with array parameters
    var queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    queryString += '&' + tagIds.map((id) => 'includedTags[]=$id').join('&');
    queryString += '&includes[]=cover_art&includes[]=author';
    queryString += '&contentRating[]=safe&contentRating[]=suggestive';
    
    final uri = Uri.parse('$_mangaDexBaseUrl/manga?$queryString');
    
    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = parseMangaDexData(data['data']);
      // Filter out the current manga if it's in results
      return results.where((m) => !m.id!.contains(cleanId)).take(limit).toList();
    }
    
    return [];
  }

  // Get manga by country/original language from MangaDex
  Future<List<MangaClass>> getMangaByLanguageMangaDex({
    required String language,
    int page = 1,
    int perPage = 10,
  }) async {
    await _throttleMangaDexRequest();
    
    final offset = (page - 1) * perPage;
    final uri = Uri.parse('$_mangaDexBaseUrl/manga').replace(
      queryParameters: {
        'limit': perPage.toString(),
        'offset': offset.toString(),
        'originalLanguage[]': [language],
        'order[followedCount]': 'desc',
        'includes[]': ['cover_art', 'author'],
        'contentRating[]': ['safe', 'suggestive'],
        'hasAvailableChapters': 'true',
      },
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final mangaList = data['data'] as List;
      
      // Extract manga IDs for statistics fetch
      final mangaIds = mangaList.map((m) => m['id'] as String).toList();
      final ratingsMap = await _getMangaStatistics(mangaIds);
      
      return parseMangaDexData(mangaList, null, ratingsMap);
    } else {
      throw Exception("Failed to load manga by language from MangaDex: ${response.statusCode}");
    }
  }

  // Rate limiting method for search requests (kept for compatibility)
  Future<void> _throttleSearchRequest() async {
    await _throttleMangaDexRequest();
  }

  // Get trending manga using MangaDex
  Future<List<MangaClass>> getTrendingManga(int page, int perpage) async {
    return await getTrendingMangaDex(page: page, perPage: perpage);
  }

  // Get popular manga using MangaDex
  Future<List<MangaClass>> getPopularManga(int page, int perpage) async {
    return await getPopularMangaDex(page: page, perPage: perpage);
  }

  // Get trending manga by country/language using MangaDex
  // Country code mapping: JP -> ja, KR -> ko, CN -> zh, TW -> zh-hk
  Future<List<MangaClass>> getTrendingByCountry(
    String countrycode,
    int page,
    int perpage,
  ) async {
    // Map AniList country codes to MangaDex language codes
    final languageMap = {
      'JP': 'ja',
      'KR': 'ko',
      'CN': 'zh',
      'TW': 'zh-hk',
    };
    final language = languageMap[countrycode.toUpperCase()] ?? 'ja';
    return await getMangaByLanguageMangaDex(
      language: language,
      page: page,
      perPage: perpage,
    );
  }

  // Get manga details using MangaDex
  Future<MangaClass> getMangaDetails(String id) async {
    return await getMangaDetailsMangaDex(id);
  }

  // Get web novels/light novels using MangaDex
  Future<List<MangaClass>> getWebNovels({
    int page = 1,
    int perpage = 5,
    String? sort,
    String? source,
  }) async {
    await _throttleMangaDexRequest();
    
    final offset = (page - 1) * perpage;
    
    // Map sort options
    Map<String, String> orderParams = {};
    if (sort != null) {
      switch (sort.toUpperCase()) {
        case 'POPULARITY_DESC':
          orderParams['order[followedCount]'] = 'desc';
          break;
        case 'SCORE_DESC':
        case 'RATING_DESC':
          orderParams['order[rating]'] = 'desc';
          break;
        default:
          orderParams['order[followedCount]'] = 'desc';
      }
    } else {
      orderParams['order[followedCount]'] = 'desc';
    }

    final uri = Uri.parse('$_mangaDexBaseUrl/manga').replace(
      queryParameters: {
        'limit': perpage.toString(),
        'offset': offset.toString(),
        ...orderParams,
        'includes[]': ['cover_art', 'author'],
        'contentRating[]': ['safe', 'suggestive'],
        'publicationDemographic[]': ['none', 'shounen', 'shoujo', 'seinen', 'josei'],
        'hasAvailableChapters': 'true',
      },
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return parseMangaDexData(data['data']);
    } else {
      throw Exception("Failed to load web novels from MangaDex: ${response.statusCode}");
    }
  }

  // Search manga using MangaDex
  Future<List<MangaClass>> searchManga({
    String? query,
    int page = 1,
    int perPage = 30,
    String? sort,
    String? source,
    List<String>? format,
    List<String>? genre,
    List<String>? excludedGenres,
    String? status,
    String? countryOfOrigin,
    int? seasonYear,
    String? season,
    bool isAdult = false,
    bool? isLicensed,
    List<String>? tags,
    List<String>? excludedTags,
  }) async {
    // Map country codes to MangaDex language codes
    String? originalLanguage;
    if (countryOfOrigin != null && countryOfOrigin.isNotEmpty) {
      final languageMap = {
        'JP': 'ja',
        'KR': 'ko',
        'CN': 'zh',
        'TW': 'zh-hk',
      };
      originalLanguage = languageMap[countryOfOrigin.toUpperCase()];
    }

    return await searchMangaDex(
      query: query,
      page: page,
      perPage: perPage,
      status: status,
      originalLanguage: originalLanguage,
      orderBy: sort,
      contentRating: isAdult ? 'erotica' : null,
    );
  }

  // Note: MangaDex doesn't have character info like AniList
  // This method returns a placeholder or throws an error
  Future<CharacterClass> getCharacterInfo(String characterId) async {
    // MangaDex doesn't have a character API like AniList
    // Return a basic placeholder or throw an exception
    throw Exception("Character info is not available from MangaDex API");
  }
}
