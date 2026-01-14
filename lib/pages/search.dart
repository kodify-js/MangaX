import 'dart:async';
import 'package:mangax/Classes/manga_class.dart';
import 'package:mangax/api/api.dart';
import 'package:mangax/pages/catagory_page.dart';
import 'package:mangax/pages/infopage.dart';
import 'package:mangax/utils/utils.dart';
import 'package:mangax/widgets/cached_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  String searchQuery = '';
  bool isSearching = false;
  List<MangaClass> searchResults = [];
  bool isLoadingMore = false;
  bool hasMoreData = true;
  int currentPage = 1;
  final int itemsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Cache futures to prevent reload on every rebuild
  late Future<List<MangaClass>> _webNovelsFuture;

  // Filter options
  String selectedSource = '';
  List<String> selectedGenres = [];
  String selectedStatus = '';
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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    // Cache the web novels future to prevent reloading on every rebuild
    _webNovelsFuture = Api().getWebNovels(
      page: 1,
      perpage: 10,
      source: "WEB_NOVEL",
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
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

  int _getActiveFilterCount() {
    int count = 0;
    if (selectedSource.isNotEmpty) count++;
    if (selectedGenres.isNotEmpty) count += selectedGenres.length;
    if (selectedStatus.isNotEmpty) count++;
    if (selectedSortBy.isNotEmpty) count++;
    if (selectedCountry.isNotEmpty) count++;
    return count;
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Modern Header with Search
              _buildHeader(colorScheme),
              // Active Filters
              _buildActiveFilters(colorScheme),
              // Content
              Expanded(
                child: searchQuery.isNotEmpty
                    ? _buildSearchResults(colorScheme)
                    : _buildDiscoverContent(colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row with back button and title
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Search',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Bar Row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _searchFocusNode.hasFocus 
                          ? colorScheme.primary 
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _performSearch,
                    onChanged: (value) {
                      setState(() {});
                    },
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search manga, novels...',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: colorScheme.primary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  searchQuery = '';
                                  searchResults.clear();
                                });
                              },
                              color: colorScheme.onSurface.withOpacity(0.5),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Filter Button with badge
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _showFilterDrawer,
                      icon: const Icon(Icons.tune_rounded),
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  if (_getActiveFilterCount() > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_getActiveFilterCount()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(ColorScheme colorScheme) {
    final hasFilters = selectedSource.isNotEmpty ||
        selectedGenres.isNotEmpty ||
        selectedStatus.isNotEmpty ||
        selectedSortBy.isNotEmpty ||
        selectedCountry.isNotEmpty;

    if (!hasFilters) return const SizedBox.shrink();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (selectedSortBy.isNotEmpty)
            _buildFilterChip(
              label: selectedSortBy.replaceAll('_', ' '),
              icon: Icons.sort_rounded,
              color: colorScheme.primary,
              onDeleted: () {
                setState(() => selectedSortBy = '');
                if (searchQuery.isNotEmpty) _performSearch(searchQuery);
              },
            ),
          if (selectedCountry.isNotEmpty)
            _buildFilterChip(
              label: countries[selectedCountry]!,
              icon: Icons.flag_rounded,
              color: Colors.orange,
              onDeleted: () {
                setState(() => selectedCountry = '');
                if (searchQuery.isNotEmpty) _performSearch(searchQuery);
              },
            ),
          if (selectedSource.isNotEmpty)
            _buildFilterChip(
              label: selectedSource.replaceAll('_', ' '),
              icon: Icons.book_rounded,
              color: Colors.purple,
              onDeleted: () {
                setState(() => selectedSource = '');
                if (searchQuery.isNotEmpty) _performSearch(searchQuery);
              },
            ),
          ...selectedGenres.map(
            (genre) => _buildFilterChip(
              label: genre,
              icon: Icons.category_rounded,
              color: Colors.teal,
              onDeleted: () {
                setState(() => selectedGenres.remove(genre));
                if (searchQuery.isNotEmpty) _performSearch(searchQuery);
              },
            ),
          ),
          if (selectedStatus.isNotEmpty)
            _buildFilterChip(
              label: selectedStatus.replaceAll('_', ' '),
              icon: Icons.info_rounded,
              color: Colors.blue,
              onDeleted: () {
                setState(() => selectedStatus = '');
                if (searchQuery.isNotEmpty) _performSearch(searchQuery);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onDeleted,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        avatar: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        deleteIcon: Icon(Icons.close_rounded, size: 16),
        onDeleted: onDeleted,
        backgroundColor: color.withOpacity(0.1),
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildSearchResults(ColorScheme colorScheme) {
    if (isSearching) {
      return _buildSearchSkeleton(colorScheme);
    }

    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term\nor adjust your filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: searchResults.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == searchResults.length) {
          return _buildLoadingMoreIndicator(colorScheme);
        }
        return _buildSearchResultCard(searchResults[index], colorScheme, index);
      },
    );
  }

  Widget _buildSearchResultCard(MangaClass manga, ColorScheme colorScheme, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Infopage(mangaId: manga.id!),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Cover Image
                Stack(
                  children: [
                    Hero(
                      tag: 'manga_cover_${manga.id}',
                      child: Container(
                        width: 90,
                        height: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedImage(
                            imageUrl: manga.coverImage ?? '',
                            fit: BoxFit.cover,
                            width: 90,
                            height: 130,
                          ),
                        ),
                      ),
                    ),
                    // Rating Badge
                    if (manga.rating != null && manga.rating! > 0)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                manga.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manga.title ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Status Badge
                      if (manga.status != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(manga.status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatStatus(manga.status),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(manga.status),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        manga.description ?? 'No description available',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colorScheme.onSurface.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading more...',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSkeleton(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: colorScheme.surfaceContainerHighest,
          highlightColor: colorScheme.surface,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 90,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 16,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 14,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiscoverContent(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Categories Section
          _buildSectionHeader(
            title: 'Browse Categories',
            icon: Icons.grid_view_rounded,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _buildCategoryGrid(colorScheme),
          const SizedBox(height: 24),
          // Popular Web Novels Section
          _buildSectionHeader(
            title: 'Popular Web Novels',
            icon: Icons.auto_stories_rounded,
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildWebNovelsSection(colorScheme),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(ColorScheme colorScheme) {
    final categoryIcons = {
      'Action': Icons.flash_on_rounded,
      'Romance': Icons.favorite_rounded,
      'Fantasy': Icons.auto_fix_high_rounded,
      'Comedy': Icons.sentiment_very_satisfied_rounded,
      'Adventure': Icons.explore_rounded,
      'Drama': Icons.theater_comedy_rounded,
    };

    final categoryColors = {
      'Action': Colors.red,
      'Romance': Colors.pink,
      'Fantasy': Colors.purple,
      'Comedy': Colors.amber,
      'Adventure': Colors.green,
      'Drama': Colors.blue,
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length > 6 ? 6 : categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final color = categoryColors[category.value] ?? colorScheme.primary;
        final icon = categoryIcons[category.value] ?? Icons.category_rounded;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CatagoryPage(
                  catagory: [category.value],
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.8),
                  color.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(
                    icon,
                    size: 60,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        category.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebNovelsSection(ColorScheme colorScheme) {
    return SizedBox(
      height: 200,
      child: FutureBuilder<List<MangaClass>>(
        future: _webNovelsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildWebNovelsSkeleton(colorScheme);
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No web novels found',
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
              ),
            );
          }

          final mangaList = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: mangaList.length,
            itemBuilder: (context, index) {
              final manga = mangaList[index];
              return _buildWebNovelCard(manga, colorScheme);
            },
          );
        },
      ),
    );
  }

  Widget _buildWebNovelCard(MangaClass manga, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Infopage(mangaId: manga.id!),
          ),
        );
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedImage(
                      imageUrl: manga.coverImage ?? '',
                      width: 130,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Rating badge
                if (manga.rating != null && manga.rating! > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            manga.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              manga.title ?? 'Unknown',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebNovelsSkeleton(ColorScheme colorScheme) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: colorScheme.surfaceContainerHighest,
          highlightColor: colorScheme.surface,
          child: Container(
            width: 130,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'ONGOING':
      case 'RELEASING':
        return Colors.green;
      case 'COMPLETED':
      case 'FINISHED':
        return Colors.blue;
      case 'HIATUS':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String? status) {
    if (status == null) return 'Unknown';
    return status.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
