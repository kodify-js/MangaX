import 'dart:async';
import 'package:mangax/Classes/manga_class.dart';
import 'package:mangax/api/api.dart';
import 'package:mangax/pages/catagory_page.dart';
import 'package:mangax/pages/infopage.dart';
import 'package:mangax/utils/utils.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String searchQuery = '';
  bool isSearching = false;
  List<MangaClass> searchResults = [];
  bool isLoadingMore = false;
  bool hasMoreData = true;
  int currentPage = 1;
  final int itemsPerPage = 20;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Filter options
  String selectedSource = '';
  List<String> selectedGenres = [];
  String selectedStatus = '';
  String selectedType = '';
  String selectedSortBy = '';
  String selectedCountry = '';

  final List<String> sources = [
    'MANGA',
    'WEB_NOVEL',
    'ORIGINAL',
    'NOVEL',
    'LIGHT_NOVEL',
  ];

  final List<String> genres = [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Ecchi',
    'Fantasy',
    'Hentai',
    'Horror',
    'Mahou Shoujo',
    'Mecha',
    'Music',
    'Mystery',
    'Psychological',
    'Romance',
    'Sci-Fi',
    'Slice of Life',
    'Sports',
    'Supernatural',
    'Thriller',
  ];

  final List<String> statuses = [
    'RELEASING',
    'FINISHED',
    'NOT_YET_RELEASED',
    'HIATUS',
    'CANCELLED',
  ];
  final List<String> sortOptions = [
    'POPULARITY',
    'RATING',
    'LATEST',
    'ALPHABETICAL',
    'RECENTLY_ADDED',
    'MOST_VIEWED',
  ];

  // Popular tags that users commonly search for
  final List<String> popularTags = [
    'School',
    'Isekai',
    'Magic',
    'Martial Arts',
    'Cultivation',
    'Female Protagonist',
    'Male Protagonist',
    'Reincarnation',
    'Time Travel',
    'Overpowered',
    'Weak to Strong',
    'System',
    'Harem',
    'Romance',
    'Medieval',
    'Modern Day',
    'Demons',
    'Dragons',
    'Nobles',
    'Academy',
  ];

  // Country codes instead of country names
  final Map<String, String> countries = {
    'JP': 'Japan',
    'KR': 'Korea',
    'CN': 'China',
    'US': 'USA',
    'GB': 'UK',
    'FR': 'France',
    'DE': 'Germany',
    'TH': 'Thailand',
    'ID': 'Indonesia',
    'PH': 'Philippines',
    'VN': 'Vietnam',
    'MY': 'Malaysia',
    'SG': 'Singapore',
    'TW': 'Taiwan',
    'HK': 'Hong Kong',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore &&
          hasMoreData &&
          searchQuery.isNotEmpty &&
          searchResults.isNotEmpty) {
        _loadMoreResults();
      }
    }
  }

  void _showFilterDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filters',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  selectedSource = '';
                                  selectedGenres.clear();
                                  selectedStatus = '';
                                  selectedType = '';
                                  selectedSortBy = '';
                                  selectedCountry = '';
                                });
                              },
                              child: Text('Clear All'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sort By Filter
                              Text(
                                'Sort By',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children:
                                    sortOptions
                                        .map(
                                          (sortOption) => FilterChip(
                                            label: Text(
                                              sortOption.replaceAll('_', ' '),
                                            ),
                                            selected:
                                                selectedSortBy == sortOption,
                                            onSelected: (selected) {
                                              setModalState(() {
                                                selectedSortBy =
                                                    selected ? sortOption : '';
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                              ),
                              SizedBox(height: 16),

                              // Country Filter
                              Text(
                                'Country',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children:
                                    countries.entries
                                        .map(
                                          (entry) => FilterChip(
                                            label: Text(
                                              entry.value.replaceAll('_', ' '),
                                            ),
                                            selected:
                                                selectedCountry == entry.key,
                                            onSelected: (selected) {
                                              setModalState(() {
                                                selectedCountry =
                                                    selected ? entry.key : '';
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                              ),
                              SizedBox(height: 16),

                              // Source Filter
                              Text(
                                'Source',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children:
                                    sources
                                        .map(
                                          (source) => FilterChip(
                                            label: Text(
                                              source.replaceAll('_', ' '),
                                            ),
                                            selected: selectedSource == source,
                                            onSelected: (selected) {
                                              setModalState(() {
                                                selectedSource =
                                                    selected ? source : '';
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                              ),
                              SizedBox(height: 16),

                              // Genres Filter
                              Text(
                                'Genres',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children:
                                    genres
                                        .map(
                                          (genre) => FilterChip(
                                            label: Text(genre),
                                            selected: selectedGenres.contains(
                                              genre,
                                            ),
                                            onSelected: (selected) {
                                              setModalState(() {
                                                if (selected) {
                                                  selectedGenres.add(genre);
                                                } else {
                                                  selectedGenres.remove(genre);
                                                }
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                              ),
                              SizedBox(height: 16),

                              // Popular Tags Filter
                              Text(
                                'Popular Tags',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children:
                                    popularTags
                                        .map(
                                          (tag) => FilterChip(
                                            label: Text(tag),
                                            selected: selectedGenres.contains(
                                              tag,
                                            ),
                                            onSelected: (selected) {
                                              setModalState(() {
                                                if (selected) {
                                                  selectedGenres.add(tag);
                                                } else {
                                                  selectedGenres.remove(tag);
                                                }
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                              ),
                              SizedBox(height: 16),

                              // Status Filter
                              Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children:
                                    statuses
                                        .map(
                                          (status) => FilterChip(
                                            label: Text(
                                              status.replaceAll('_', ' '),
                                            ),
                                            selected: selectedStatus == status,
                                            onSelected: (selected) {
                                              setModalState(() {
                                                selectedStatus =
                                                    selected ? status : '';
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (searchQuery.isNotEmpty) {
                                _performSearch(searchQuery);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Apply Filters',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Future<void> _loadMoreResults() async {
    if (isLoadingMore || !hasMoreData || searchQuery.isEmpty) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final newResults = await Api().searchManga(
        page: currentPage + 1,
        perPage: itemsPerPage,
        query: searchQuery,
        source: selectedSource.isNotEmpty ? selectedSource : null,
        genre: selectedGenres.isNotEmpty ? selectedGenres : null,
        status: selectedStatus.isNotEmpty ? selectedStatus : null,
        type: selectedType.isNotEmpty ? selectedType : null,
        sort: selectedSortBy.isNotEmpty ? selectedSortBy : null,
        countryOfOrigin: selectedCountry.isNotEmpty ? selectedCountry : null,
      );

      setState(() {
        if (newResults.isNotEmpty) {
          searchResults.addAll(newResults);
          currentPage++;
          if (newResults.length < itemsPerPage) {
            hasMoreData = false;
          }
        } else {
          hasMoreData = false;
        }
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        isLoadingMore = false;
      });
      print('Error loading more results: $e');
    }
  }

  Future<void> _performSearch(String value) async {
    if (value.trim().isNotEmpty) {
      setState(() {
        searchQuery = value.trim();
        isSearching = true;
        searchResults.clear();
        currentPage = 1;
        hasMoreData = true;
        isLoadingMore = false;
      });

      try {
        final results = await Api().searchManga(
          page: 1,
          perPage: itemsPerPage,
          query: searchQuery,
          source: selectedSource.isNotEmpty ? selectedSource : null,
          genre: selectedGenres.isNotEmpty ? selectedGenres : null,
          status: selectedStatus.isNotEmpty ? selectedStatus : null,
          type: selectedType.isNotEmpty ? selectedType : null,
          sort: selectedSortBy.isNotEmpty ? selectedSortBy : null,
          countryOfOrigin: selectedCountry.isNotEmpty ? selectedCountry : null,
        );

        setState(() {
          searchResults = results;
          isSearching = false;
          if (results.length < itemsPerPage) {
            hasMoreData = false;
          }
        });
      } catch (e) {
        setState(() {
          isSearching = false;
          searchResults = [];
          hasMoreData = false;
        });
        print('Error performing search: $e');
      }
    } else {
      setState(() {
        searchQuery = '';
        isSearching = false;
        searchResults.clear();
        currentPage = 1;
        hasMoreData = true;
        isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Search',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
            // Search Bar with Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withAlpha(100),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _performSearch,
                        decoration: InputDecoration(
                          hintText: 'Search manga, novels...',
                          hintStyle: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(150),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(100),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: _showFilterDrawer,
                      icon: Icon(
                        Icons.tune,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Active Filters Display
            if (selectedSource.isNotEmpty ||
                selectedGenres.isNotEmpty ||
                selectedStatus.isNotEmpty ||
                selectedType.isNotEmpty ||
                selectedSortBy.isNotEmpty ||
                selectedCountry.isNotEmpty)
              Container(
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (selectedSortBy.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(
                            'Sort: ${selectedSortBy.replaceAll('_', ' ')}',
                          ),
                          onDeleted: () {
                            setState(() => selectedSortBy = '');
                            _performSearch(searchQuery);
                          },
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(50),
                        ),
                      ),
                    if (selectedCountry.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(
                            countries[selectedCountry]!,
                          ), // Display country name
                          onDeleted: () {
                            setState(() => selectedCountry = '');
                            _performSearch(searchQuery);
                          },
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary.withAlpha(50),
                        ),
                      ),
                    if (selectedSource.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(selectedSource),
                          onDeleted: () {
                            setState(() => selectedSource = '');
                            _performSearch(searchQuery);
                          },
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.tertiary.withAlpha(50),
                        ),
                      ),
                    ...selectedGenres.map(
                      (genre) => Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(genre),
                          onDeleted: () {
                            setState(() => selectedGenres.remove(genre));
                            _performSearch(searchQuery);
                          },
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.error.withAlpha(50),
                        ),
                      ),
                    ),
                    if (selectedStatus.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(selectedStatus),
                          onDeleted: () {
                            setState(() => selectedStatus = '');
                            _performSearch(searchQuery);
                          },
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface.withAlpha(100),
                        ),
                      ),
                    if (selectedType.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(selectedType),
                          onDeleted: () {
                            setState(() => selectedType = '');
                            _performSearch(searchQuery);
                          },
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.outline.withAlpha(50),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child:
                  searchQuery.isNotEmpty
                      ? isSearching
                          ? Center(child: CircularProgressIndicator())
                          : searchResults.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text('No results found for "$searchQuery"'),
                                SizedBox(height: 8),
                                Text(
                                  'Try a different search term or adjust filters',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            controller: _scrollController,
                            itemCount:
                                searchResults.length + (isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == searchResults.length) {
                                return Container(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 8),
                                        Text(
                                          'Loading more...',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final manga = searchResults[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              Infopage(mangaId: manga.id!),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline.withAlpha(50),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
                                          child: Image.network(
                                            manga.coverImage!,
                                            width: 80,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Container(
                                                width: 80,
                                                height: 100,
                                                color: Colors.grey[300],
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 40,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                manga.title!,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                manga.description ?? '',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                      : SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16.0,
                                8.0,
                                16.0,
                                8.0,
                              ),
                              child: Text(
                                "Popular Web Novels",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Sayyeda',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 200,
                              child: FutureBuilder(
                                future: Api().searchManga(
                                  page: 1,
                                  perPage: 20,
                                  source: "WEB_NOVEL",
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  } else if (snapshot.hasError) {
                                    return Center(
                                      child: Text('Error: ${snapshot.error}'),
                                    );
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No popular web novels found',
                                      ),
                                    );
                                  } else {
                                    final mangaList = snapshot.data!;
                                    return ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      itemCount: mangaList.length,
                                      itemBuilder: (context, index) {
                                        final manga = mangaList[index];
                                        return Container(
                                          width: 120,
                                          margin: EdgeInsets.only(right: 12),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) => Infopage(
                                                        mangaId: manga.id!,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8.0,
                                                      ),
                                                  child: Image.network(
                                                    manga.coverImage!,
                                                    width: 120,
                                                    height: 160,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Container(
                                                        width: 120,
                                                        height: 160,
                                                        color: Colors.grey[300],
                                                        child: Icon(
                                                          Icons.broken_image,
                                                          size: 40,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  manga.title!,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                            ),
                            SizedBox(height: 16),
                            SizedBox(
                              height: 400,
                              child: GridView(
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 1.5,
                                      crossAxisSpacing: 8.0,
                                      mainAxisSpacing: 8.0,
                                    ),
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                children: List.generate(
                                  categories.length,
                                  (index) => GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (context) => CatagoryPage(
                                                catagory: [
                                                  categories[index].value,
                                                ],
                                              ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withAlpha(50),
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              categories[index].value,
                                              style: TextStyle(
                                                fontSize: 20,
                                                letterSpacing: 2,
                                                fontFamily: 'MangaX',
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                      0.0,
                                                      0.0,
                                                      16.0,
                                                      8.0,
                                                    ),
                                                child: SizedBox(
                                                  width: 100,
                                                  child: Stack(
                                                    children: [
                                                      Positioned(
                                                        right: 10,
                                                        bottom: 5,
                                                        child: Container(
                                                          width: 20,
                                                          height: 50,
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4.0,
                                                                ),
                                                            color: Theme.of(
                                                                  context,
                                                                )
                                                                .colorScheme
                                                                .primary
                                                                .withAlpha(180),
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        right: 0,
                                                        bottom: 10,
                                                        child: Container(
                                                          width: 30,
                                                          height: 40,
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4.0,
                                                                ),
                                                            color: Theme.of(
                                                                  context,
                                                                )
                                                                .colorScheme
                                                                .primary
                                                                .withAlpha(100),
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                          left: 20,
                                                        ),
                                                        width: 60,
                                                        height: 60,
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8.0,
                                                              ),
                                                          image: DecorationImage(
                                                            image: AssetImage(
                                                              'assets/images/${categories[index].value}.png',
                                                            ),
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
