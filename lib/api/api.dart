import 'dart:convert';
import 'package:mangax/Classes/manga_class.dart';
import 'package:http/http.dart' as http;

class Api {
  Api();

  // Rate limiting variables
  static DateTime? _lastSearchRequestTime;
  static const Duration _minSearchInterval = Duration(
    milliseconds: 1000,
  ); // 1 second between search requests

  // Rate limiting method for search requests
  Future<void> _throttleSearchRequest() async {
    if (_lastSearchRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(
        _lastSearchRequestTime!,
      );
      if (timeSinceLastRequest < _minSearchInterval) {
        final waitTime = _minSearchInterval - timeSinceLastRequest;
        print(
          "Throttling search request, waiting ${waitTime.inMilliseconds}ms",
        );
        await Future.delayed(waitTime);
      }
    }
    _lastSearchRequestTime = DateTime.now();
  }

  List<MangaClass> parseMangaData(List media) {
    List<MangaClass> result = [];
    for (var item in media) {
      MangaClass manga = MangaClass(
        id: item['id'].toString(),
        title: item['title']['userPreferred'] ?? item['title']['romaji'],
        coverImage: item['coverImage']['large'] ?? item['coverImage']['medium'],
        description: item['description'] ?? '',
        status: item['status'] ?? '',
        genre:
            item['genres'] != null && item['genres'].isNotEmpty
                ? item['genres']
                : 'Unknown',
        chaptersCount: item['chapters'] ?? 0,
        color: item['coverImage']['color'] ?? "",
        bannerImage: item['bannerImage'] ?? '',
        rating:
            item['averageScore'] != null
                ? (item['averageScore'] / 10).toDouble()
                : 0.0,
        characters:
            item['characters'] != null
                ? (item['characters']['edges'] as List)
                    .map(
                      (edge) => CharacterPreview(
                        id: edge['node']['id'].toString(),
                        name: edge['node']['name']['userPreferred'],
                        imageUrl: edge['node']['image']['large'],
                        role: edge['role'],
                      ),
                    )
                    .toList()
                : [],
        recommendations:
            item['recommendations'] != null
                ? (item['recommendations']['edges'] as List)
                    .map(
                      (edges) => RelatedManga(
                        id:
                            edges['node']['mediaRecommendation']['id']
                                .toString(),
                        title:
                            edges['node']['mediaRecommendation']['title']['userPreferred'],
                        coverImage:
                            edges['node']['mediaRecommendation']['coverImage']['large'],
                      ),
                    )
                    .toList()
                : [],
        synonyms:
            item['synonyms'] != null ? List<String>.from(item['synonyms']) : [],
      );
      result.add(manga);
    }
    return result;
  }

  Future<List<MangaClass>> getTrendingManga(int page, int perpage) async {
    var query =
        'query (\$page: Int, \$id: Int, \$type: MediaType, \$search: String, \$isAdult: Boolean = false, \$size: Int,\$sort: [MediaSort] = [TRENDING_DESC]) {Page(page: \$page, perPage: \$size) {pageInfo {total perPage currentPage lastPage hasNextPage}media(id: \$id, type: \$type, search: \$search, isAdult: \$isAdult ,sort:\$sort) {id idMal status(version: 2) title { userPreferred romaji english native }bannerImage popularity coverImage{extraLarge large medium color}episodes format season description  seasonYear chapters volumes averageScore genres nextAiringEpisode {airingAt timeUntilAiring episode }  } }}';
    final variables = {
      "page": page,
      "size": perpage,
      "type": "MANGA",
      "sort": ["TRENDING_DESC", "POPULARITY_DESC"],
    };
    final response = await http.post(
      Uri.parse("https://graphql.anilist.co"),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({"query": query, "variables": variables}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return parseMangaData(data['data']['Page']['media']);
    } else {
      throw Exception("Failed to load trending manga");
    }
  }

  Future<List<MangaClass>> getPopularManga(int page, int perpage) async {
    var query =
        'query (\$page: Int, \$id: Int, \$type: MediaType, \$search: String, \$isAdult: Boolean = false, \$size: Int,\$sort: [MediaSort] = [POPULARITY_DESC]) {Page(page: \$page, perPage: \$size) {pageInfo {total perPage currentPage lastPage hasNextPage}media(id: \$id, type: \$type, search: \$search, isAdult: \$isAdult ,sort:\$sort) {id idMal status(version: 2) title { userPreferred romaji english native }bannerImage popularity coverImage{extraLarge large medium color}episodes format season description  seasonYear chapters volumes averageScore genres nextAiringEpisode {airingAt timeUntilAiring episode }  } }}';
    final variables = {
      "page": page,
      "size": perpage,
      "type": "MANGA",
      "sort": ["POPULARITY_DESC", "TRENDING_DESC"],
    };
    final response = await http.post(
      Uri.parse("https://graphql.anilist.co"),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({"query": query, "variables": variables}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Api().parseMangaData(data['data']['Page']['media']);
    } else {
      throw Exception("Failed to load popular manga");
    }
  }

  Future<List<MangaClass>> getTrendingByCountry(
    String countrycode,
    int page,
    int perpage,
  ) async {
    var query =
        'query (\$page: Int, \$id: Int, \$type: MediaType, \$search: String, \$isAdult: Boolean = false, \$size: Int,\$sort: [MediaSort] = [POPULARITY_DESC,SCORE_DESC],\$countryOfOrigin:CountryCode) {Page(page: \$page, perPage: \$size) {pageInfo {total perPage currentPage lastPage hasNextPage}media(id: \$id, type: \$type, search: \$search, isAdult: \$isAdult ,sort:\$sort,countryOfOrigin:\$countryOfOrigin) {id idMal status(version: 2) title { userPreferred romaji english native }bannerImage popularity coverImage{extraLarge large medium color}episodes format season description  seasonYear chapters volumes averageScore genres nextAiringEpisode {airingAt timeUntilAiring episode }  } }}';
    final variables = {
      "page": page,
      "size": perpage,
      "type": "MANGA",
      "countryOfOrigin": countrycode,
      "sort": ["TRENDING_DESC", "POPULARITY_DESC"],
    };
    final response = await http.post(
      Uri.parse("https://graphql.anilist.co"),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({"query": query, "variables": variables}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Api().parseMangaData(data['data']['Page']['media']);
    } else {
      throw Exception("Failed to load trending manga by country");
    }
  }

  Future<MangaClass> getMangaDetails(String id) async {
    var query =
        'query (\$id: Int) { Media(id: \$id) { id idMal title { english native romaji } synonyms countryOfOrigin isLicensed isAdult externalLinks { url site type language } coverImage { extraLarge large color } startDate { year month day } endDate { year month day } bannerImage season seasonYear description type format status(version: 2) episodes duration chapters volumes trailer { id site thumbnail } genres source averageScore popularity meanScore nextAiringEpisode { airingAt timeUntilAiring episode } characters(sort: ROLE) { edges { role node { id name { first middle last full native userPreferred } image { large medium } } voiceActors(sort: LANGUAGE) { id languageV2 name { first middle last full native userPreferred } image { large medium } } } } recommendations { edges { node { id mediaRecommendation { id idMal title { romaji english native userPreferred } status episodes coverImage { extraLarge large medium color } bannerImage format chapters meanScore nextAiringEpisode { episode timeUntilAiring airingAt } } } } } relations { edges { id relationType node { id idMal status coverImage { extraLarge large medium color } bannerImage title { romaji english native userPreferred } episodes chapters format nextAiringEpisode { airingAt timeUntilAiring episode } meanScore } } } studios(isMain: true) { edges { isMain node { id name } } } } }';
    final variables = {"id": int.parse(id), "type": "MANGA"};
    final response = await http.post(
      Uri.parse("https://graphql.anilist.co"),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({"query": query, "variables": variables}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return parseMangaData([data['data']['Media']]).first;
    } else {
      throw Exception("Failed to load manga details");
    }
  }

  Future<List<MangaClass>> getWebNovels({
    int page = 1,
    int perpage = 5,
    String? sort,
    String? source,
  }) async {
    var query =
        'query (\$page: Int, \$size: Int, \$type: MediaType, \$source: MediaSource, \$sort: [MediaSort] = [POPULARITY_DESC, SCORE_DESC]) {Page(page: \$page, perPage: \$size) {pageInfo {total perPage currentPage lastPage hasNextPage} media(type: \$type, source: \$source, sort: \$sort) {id idMal status(version: 2) title { userPreferred romaji english native } bannerImage popularity coverImage{extraLarge large medium color} episodes format season description seasonYear chapters volumes averageScore genres nextAiringEpisode {airingAt timeUntilAiring episode }}}}';
    final variables = {
      "page": page,
      "size": perpage,
      "type": "MANGA",
      "source": source,
      "sort": sort != null ? [sort] : ["POPULARITY_DESC", "SCORE_DESC"],
    };
    final response = await http.post(
      Uri.parse("https://graphql.anilist.co"),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({"query": query, "variables": variables}),
    );
    print("Response status: ${response.body}");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return parseMangaData(data['data']['Page']['media']);
    } else {
      throw Exception("Failed to load web novels");
    }
  }

  Future<List<MangaClass>> searchManga({
    String? query,
    int page = 1,
    int perPage = 10,
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
    // Apply rate limiting specifically for search requests
    await _throttleSearchRequest();

    // Build dynamic query variables and parameters based on what's provided
    List<String> queryParams = [
      '\$page: Int = 1',
      '\$size: Int',
      '\$type: MediaType',
      '\$isAdult: Boolean = false',
      '\$sort: [MediaSort] = [POPULARITY_DESC, SCORE_DESC]',
    ];

    List<String> mediaParams = [
      'page: \$page',
      'perPage: \$size',
      'type: \$type',
      'isAdult: \$isAdult',
      'sort: \$sort',
    ];

    Map<String, dynamic> variables = {
      "page": page,
      "size": perPage,
      "type": "MANGA",
      "isAdult": isAdult,
    };

    if (query != null && query.isNotEmpty) {
      queryParams.add('\$search: String');
      mediaParams.add('search: \$search');
      variables["search"] = query;
    }

    if (source != null && source.isNotEmpty) {
      queryParams.add('\$source: MediaSource');
      mediaParams.add('source: \$source');
      variables["source"] = source;
    }

    if (format != null && format.isNotEmpty) {
      queryParams.add('\$format: [MediaFormat]');
      mediaParams.add('format_in: \$format');
      variables["format"] = format;
    }

    if (genre != null && genre.isNotEmpty) {
      queryParams.add('\$genres: [String]');
      mediaParams.add('genre_in: \$genres');
      variables["genres"] = genre;
    }

    if (excludedGenres != null && excludedGenres.isNotEmpty) {
      queryParams.add('\$excludedGenres: [String]');
      mediaParams.add('genre_not_in: \$excludedGenres');
      variables["excludedGenres"] = excludedGenres;
    }

    if (status != null && status.isNotEmpty) {
      queryParams.add('\$status: MediaStatus');
      mediaParams.add('status: \$status');
      variables["status"] = status;
    }

    if (countryOfOrigin != null && countryOfOrigin.isNotEmpty) {
      queryParams.add('\$countryOfOrigin: CountryCode');
      mediaParams.add('countryOfOrigin: \$countryOfOrigin');
      variables["countryOfOrigin"] = countryOfOrigin;
    }

    if (seasonYear != null) {
      queryParams.add('\$seasonYear: Int');
      mediaParams.add('seasonYear: \$seasonYear');
      variables["seasonYear"] = seasonYear;
    }

    if (season != null && season.isNotEmpty) {
      queryParams.add('\$season: MediaSeason');
      mediaParams.add('season: \$season');
      variables["season"] = season;
    }

    if (isLicensed != null) {
      queryParams.add('\$isLicensed: Boolean');
      mediaParams.add('isLicensed: \$isLicensed');
      variables["isLicensed"] = isLicensed;
    }

    if (tags != null && tags.isNotEmpty) {
      queryParams.add('\$tags: [String]');
      mediaParams.add('tag_in: \$tags');
      variables["tags"] = tags;
    }

    if (excludedTags != null && excludedTags.isNotEmpty) {
      queryParams.add('\$excludedTags: [String]');
      mediaParams.add('tag_not_in: \$excludedTags');
      variables["excludedTags"] = excludedTags;
    }

    if (sort != null && sort.isNotEmpty) {
      variables["sort"] = [sort];
    } else {
      variables["sort"] = ["POPULARITY_DESC", "SCORE_DESC"];
    }

    // Build the dynamic query string
    var queryString = '''
      query (${queryParams.join(', ')}) {
        Page(page: \$page, perPage: \$size) {
          pageInfo {
            total
            perPage
            currentPage
            lastPage
            hasNextPage
          }
          media(${mediaParams.join(', ')}) {
            id
            idMal
            status(version: 2)
            title {
              userPreferred
              romaji
              english
              native
            }
            bannerImage
            popularity
            coverImage {
              extraLarge
              large
              medium
              color
            }
            episodes
            format
            season
            description
            seasonYear
            chapters
            volumes
            averageScore
            genres
            nextAiringEpisode {
              airingAt
              timeUntilAiring
              episode
            }
          }
        }
      }
    ''';

    print("Generated query: $queryString");

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final response = await http
            .post(
              Uri.parse("https://graphql.anilist.co"),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({"query": queryString, "variables": variables}),
            )
            .timeout(Duration(seconds: 30));

        print("Response body: ${response.body}");

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Check for GraphQL errors
          if (data['errors'] != null) {
            print("GraphQL Error: ${data['errors']}");
            throw Exception("GraphQL Error: ${data['errors']}");
          }

          return parseMangaData(data['data']['Page']['media']);
        } else if (response.statusCode == 429) {
          // Rate limited - wait and retry
          retryCount++;
          final waitTime = Duration(seconds: retryCount * 3); // 3s, 6s, 9s
          print(
            "Rate limited (429), waiting ${waitTime.inSeconds} seconds before retry $retryCount/$maxRetries",
          );
          await Future.delayed(waitTime);
          continue;
        } else if (response.statusCode >= 500) {
          // Server error - retry
          retryCount++;
          if (retryCount >= maxRetries) {
            throw Exception(
              "Server error after $maxRetries retries: ${response.statusCode}",
            );
          }
          print(
            "Server error (${response.statusCode}), retrying in ${retryCount * 2} seconds",
          );
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        } else {
          print("Response body: ${response.body}");
          throw Exception("Failed to search manga: ${response.statusCode}");
        }
      } catch (e) {
        if (e.toString().contains('TimeoutException')) {
          retryCount++;
          if (retryCount >= maxRetries) {
            throw Exception("Request timeout after $maxRetries retries");
          }
          print("Request timeout, retrying in ${retryCount * 2} seconds");
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        } else {
          // Re-throw other errors immediately
          throw e;
        }
      }
    }

    throw Exception("Max retries exceeded");
  }
}
