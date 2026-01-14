import 'package:mangax/Classes/manga_class.dart';
import 'package:mangax/api/api.dart';
import 'package:mangax/components/carousel.dart';
import 'package:mangax/components/horizontal_list.dart';
import 'package:mangax/pages/search.dart';
import 'package:mangax/utils/constants.dart';
import 'package:mangax/widgets/skeleton_loaders.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);
  
  // Cache futures to prevent reload on scroll
  late Future<List<MangaClass>> _trendingFuture;
  late Future<List<MangaClass>> _popularFuture;
  late Future<List<MangaClass>> _manhwaFuture;
  late Future<List<MangaClass>> _manhuaFuture;
  
  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController = ScrollController()
      ..addListener(() {
        _scrollOffset.value = _scrollController.offset;
      });
  }
  
  void _loadData() {
    final api = Api();
    _trendingFuture = api.getTrendingManga(1, 10);
    _popularFuture = api.getPopularManga(1, 10);
    _manhwaFuture = api.getTrendingByCountry("KR", 1, 10);
    _manhuaFuture = api.getTrendingByCountry("CN", 1, 10);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }
  
  Future<void> _refreshData() async {
    _loadData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          RefreshIndicator(
            onRefresh: _refreshData,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Featured Carousel
                SliverToBoxAdapter(
                  child: FutureBuilder<List<MangaClass>>(
                    future: _trendingFuture,
                    builder: (context, snapshot) {
                      final topPadding = MediaQuery.of(context).padding.top;
                      final carouselHeight = 400 + topPadding;
                      
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          width: double.infinity,
                          height: carouselHeight,
                          child: const CarouselSkeleton(),
                        );
                      } else if (snapshot.hasError) {
                        return _buildErrorWidget(
                          'Failed to load featured manga',
                          _refreshData,
                          height: carouselHeight,
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return SizedBox(
                          height: carouselHeight,
                          child: const Center(child: Text('No data found')),
                        );
                      } else {
                        return SizedBox(
                          width: double.infinity,
                          height: carouselHeight,
                          child: Carousel(mangaList: snapshot.data!),
                        );
                      }
                    },
                  ),
                ),
                
                // Section Title - Popular
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    context,
                    'Popular Now',
                    Icons.local_fire_department_rounded,
                    Colors.orange,
                  ),
                ),
                
                // Popular Manga
                SliverToBoxAdapter(
                  child: FutureBuilder<List<MangaClass>>(
                    future: _popularFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildHorizontalListSkeleton();
                      } else if (snapshot.hasError) {
                        return _buildErrorWidget(
                          'Failed to load popular manga',
                          _refreshData,
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox(
                          height: 220,
                          child: Center(child: Text('No data found')),
                        );
                      } else {
                        return HorizontalList(
                          mangaList: snapshot.data!,
                          title: "Popular Manga",
                          sort: Sort.popular.value,
                        );
                      }
                    },
                  ),
                ),
                
                // Section Title - Manhwa
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    context,
                    'Trending Manhwa',
                    Icons.trending_up_rounded,
                    Colors.blue,
                  ),
                ),
                
                // Trending Manhwa (Korean)
                SliverToBoxAdapter(
                  child: FutureBuilder<List<MangaClass>>(
                    future: _manhwaFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildHorizontalListSkeleton();
                      } else if (snapshot.hasError) {
                        return _buildErrorWidget(
                          'Failed to load manhwa',
                          _refreshData,
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox(
                          height: 220,
                          child: Center(child: Text('No data found')),
                        );
                      } else {
                        return HorizontalList(
                          mangaList: snapshot.data!,
                          title: 'Trending Manhwa',
                          country: "KR",
                          sort: Sort.trending.value,
                        );
                      }
                    },
                  ),
                ),
                
                // Section Title - Manhua
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    context,
                    'Trending Manhua',
                    Icons.auto_awesome_rounded,
                    Colors.red,
                  ),
                ),
                
                // Trending Manhua (Chinese)
                SliverToBoxAdapter(
                  child: FutureBuilder<List<MangaClass>>(
                    future: _manhuaFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildHorizontalListSkeleton();
                      } else if (snapshot.hasError) {
                        return _buildErrorWidget(
                          'Failed to load manhua',
                          _refreshData,
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox(
                          height: 220,
                          child: Center(child: Text('No data found')),
                        );
                      } else {
                        return HorizontalList(
                          mangaList: snapshot.data!,
                          country: "CN",
                          sort: Sort.trending.value,
                          title: "Trending Manhua",
                        );
                      }
                    },
                  ),
                ),
                
                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],
            ),
          ),
          
          // Floating Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<double>(
              valueListenable: _scrollOffset,
              builder: (context, scrollOffset, child) {
                final headerOpacity = (scrollOffset / 100).clamp(0.0, 1.0);
                return Container(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        headerOpacity > 0.5 
                            ? colorScheme.surface.withOpacity(headerOpacity)
                            : Colors.black.withOpacity(0.7 - headerOpacity * 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // Logo
                          Row(
                            children: [
                              Text(
                                'Manga',
                                style: TextStyle(
                                  color: headerOpacity > 0.5 
                                      ? colorScheme.onSurface 
                                      : Colors.white,
                                  fontSize: 28,
                                  fontFamily: 'MangaX',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'X',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 32,
                                  fontFamily: 'MangaX',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Action buttons
                          _buildHeaderButton(
                            Icons.shuffle_rounded,
                            headerOpacity,
                            colorScheme,
                            () {},
                          ),
                          const SizedBox(width: 8),
                          _buildHeaderButton(
                            Icons.search_rounded,
                            headerOpacity,
                            colorScheme,
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SearchPage(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(
    IconData icon,
    double headerOpacity,
    ColorScheme colorScheme,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: headerOpacity > 0.5
            ? colorScheme.surfaceContainerHighest
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: headerOpacity > 0.5 
                  ? colorScheme.onSurface 
                  : Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalListSkeleton() {
    return SizedBox(
      height: 220,
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        highlightColor: Theme.of(context).colorScheme.surface,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 180,
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message, VoidCallback onRetry, {double height = 220}) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
