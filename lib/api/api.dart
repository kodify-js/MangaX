import 'dart:convert';
import 'package:mangax/Classes/manga_class.dart';
import 'package:http/http.dart' as http;

class Api {
  Api();

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

  Future<List<MangaClass>> searchManga({
    String? query,
    int page = 1,
    int perPage = 10,
    String? sort,
    String? source,
    String? type = "MANGA",
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
    var queryString =
        'query (\$page:Int = 1 \$id:Int \$type:MediaType \$isAdult:Boolean = false \$search:String \$format:[MediaFormat]\$status:MediaStatus \$countryOfOrigin:CountryCode \$source:MediaSource \$season:MediaSeason \$seasonYear:Int \$year:String \$onList:Boolean \$yearLesser:FuzzyDateInt \$yearGreater:FuzzyDateInt \$episodeLesser:Int \$episodeGreater:Int \$durationLesser:Int \$durationGreater:Int \$chapterLesser:Int \$chapterGreater:Int \$volumeLesser:Int \$size:Int \$volumeGreater:Int \$licensedBy:[Int]\$isLicensed:Boolean \$genres:[String]\$excludedGenres:[String]\$tags:[String]\$excludedTags:[String]\$minimumTagRank:Int \$sort:[MediaSort]=[POPULARITY_DESC,SCORE_DESC]) {Page(page: \$page, perPage: \$size) {pageInfo {total perPage currentPage lastPage hasNextPage}media(id:\$id type:\$type season:\$season format_in:\$format status:\$status countryOfOrigin:\$countryOfOrigin source:\$source search:\$search onList:\$onList seasonYear:\$seasonYear startDate_like:\$year startDate_lesser:\$yearLesser startDate_greater:\$yearGreater episodes_lesser:\$episodeLesser episodes_greater:\$episodeGreater duration_lesser:\$durationLesser duration_greater:\$durationGreater chapters_lesser:\$chapterLesser chapters_greater:\$chapterGreater volumes_lesser:\$volumeLesser volumes_greater:\$volumeGreater licensedById_in:\$licensedBy isLicensed:\$isLicensed genre_in:\$genres genre_not_in:\$excludedGenres tag_in:\$tags tag_not_in:\$excludedTags minimumTagRank:\$minimumTagRank sort:\$sort isAdult:\$isAdult) {id idMal status(version: 2) title { userPreferred romaji english native }bannerImage popularity coverImage{extraLarge large medium color}episodes format season description  seasonYear chapters volumes averageScore genres nextAiringEpisode {airingAt timeUntilAiring episode }  } }}';

    Map<String, dynamic> variables = {
      "page": page,
      "size": perPage,
      "type": type,
      "isAdult": isAdult,
    };

    if (query != null && query.isNotEmpty) {
      variables["search"] = query;
    }

    if (sort != null && sort.isNotEmpty) {
      variables["sort"] = sort;
    } else {
      variables["sort"] = ["POPULARITY_DESC", "SCORE_DESC"]; // default sort
    }

    if (source != null && source.isNotEmpty) {
      variables["source"] = source;
    }

    if (format != null && format.isNotEmpty) {
      variables["format"] = format;
    }

    if (genre != null && genre.isNotEmpty) {
      variables["genres"] = genre;
    }

    if (excludedGenres != null && excludedGenres.isNotEmpty) {
      variables["excludedGenres"] = excludedGenres;
    }

    if (status != null && status.isNotEmpty) {
      variables["status"] = status;
    }

    if (countryOfOrigin != null && countryOfOrigin.isNotEmpty) {
      variables["countryOfOrigin"] = countryOfOrigin;
    }

    if (seasonYear != null) {
      variables["seasonYear"] = seasonYear;
    }

    if (season != null && season.isNotEmpty) {
      variables["season"] = season;
    }

    if (isLicensed != null) {
      variables["isLicensed"] = isLicensed;
    }

    if (tags != null && tags.isNotEmpty) {
      variables["tags"] = tags;
    }

    if (excludedTags != null && excludedTags.isNotEmpty) {
      variables["excludedTags"] = excludedTags;
    }

    print("Searching manga with variables: $variables");

    final response = await http.post(
      Uri.parse("https://graphql.anilist.co"),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({"query": queryString, "variables": variables}),
    );

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Check for GraphQL errors
      if (data['errors'] != null) {
        throw Exception("GraphQL Error: ${data['errors']}");
      }

      return parseMangaData(data['data']['Page']['media']);
    } else {
      throw Exception("Failed to search manga: ${response.statusCode}");
    }
  }
}
