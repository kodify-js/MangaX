import 'package:flutter/material.dart';
import 'package:mangax/providers/chapters_provider.dart';
import 'package:mangax/api/providers/provider_manager.dart';
import 'package:mangax/api/providers/mangadex.dart';
import 'package:mangax/pages/reading_page.dart';
import 'package:shimmer/shimmer.dart';

class ChaptersPage extends StatefulWidget {
  final String? mangaId;
  final String? mangaTitle;
  final String? coverImage;
  const ChaptersPage({super.key, this.mangaId, this.mangaTitle, this.coverImage});

  @override
  State<ChaptersPage> createState() => _ChaptersPageState();
}

class _ChaptersPageState extends State<ChaptersPage> with SingleTickerProviderStateMixin {
  late ChaptersProvider chaptersProvider;
  TextEditingController searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isDescending = true;

  @override
  void initState() {
    super.initState();
    chaptersProvider = ChaptersProvider();
    if (widget.mangaId != null) {
      chaptersProvider.loadChapters(widget.mangaTitle!);
      // Load available languages for MangaDex
      chaptersProvider.loadAvailableLanguages(widget.mangaTitle!);
    }
    searchController.addListener(() {
      chaptersProvider.searchChapters(searchController.text);
    });
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void showProviderSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        final colorScheme = Theme.of(bottomSheetContext).colorScheme;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.source_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Select Provider',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.1)),
                  ...ProviderManager.providers.map((provider) {
                    final isSelected = provider.name == chaptersProvider.currentProvider.name;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? colorScheme.primary.withOpacity(0.1) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? colorScheme.primary.withOpacity(0.3) 
                              : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? colorScheme.primary 
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.cloud_rounded,
                            color: isSelected 
                                ? colorScheme.onPrimary 
                                : colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        title: Text(
                          provider.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          provider.baseUrl,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                            : null,
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          if (widget.mangaId != null) {
                            chaptersProvider.changeProvider(provider, widget.mangaId!);
                          }
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showLanguageSelector() {
    if (!chaptersProvider.supportsLanguageSelection) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext bottomSheetContext) {
        final colorScheme = Theme.of(bottomSheetContext).colorScheme;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableLanguages = chaptersProvider.availableLanguages.toList()
              ..sort((a, b) => Mangadex.getLanguageName(a).compareTo(Mangadex.getLanguageName(b)));
            
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.translate_rounded,
                            color: colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Language',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '${availableLanguages.length} languages available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colorScheme.outline.withOpacity(0.1)),
                  if (chaptersProvider.isLoadingLanguages)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: availableLanguages.length,
                        itemBuilder: (context, index) {
                          final langCode = availableLanguages[index];
                          final isSelected = langCode == chaptersProvider.selectedLanguage;
                          final langName = Mangadex.getLanguageName(langCode);
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? colorScheme.secondary.withOpacity(0.1) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? colorScheme.secondary.withOpacity(0.3) 
                                    : Colors.transparent,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? colorScheme.secondary 
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    langCode.toUpperCase().substring(0, langCode.length > 2 ? 2 : langCode.length),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isSelected 
                                          ? colorScheme.onSecondary 
                                          : colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                langName,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                langCode.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle_rounded, color: colorScheme.secondary)
                                  : null,
                              onTap: () {
                                Navigator.pop(bottomSheetContext);
                                if (widget.mangaTitle != null) {
                                  chaptersProvider.changeLanguage(langCode, widget.mangaTitle!);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Modern App Bar
            _buildSliverAppBar(colorScheme),
            // Search and Controls
            SliverToBoxAdapter(
              child: _buildSearchAndControls(colorScheme),
            ),
            // Provider Info
            SliverToBoxAdapter(
              child: _buildProviderInfo(colorScheme),
            ),
            // Chapters List
            _buildChaptersList(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.of(context).pop(),
            color: colorScheme.onSurface,
          ),
        ),
      ),
      actions: [
        // Language selector button (only for MangaDex)
        ListenableBuilder(
          listenable: chaptersProvider,
          builder: (context, child) {
            if (!chaptersProvider.supportsLanguageSelection) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.secondary,
                      colorScheme.secondary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.secondary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: showLanguageSelector,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.translate_rounded,
                          size: 18,
                          color: colorScheme.onSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          chaptersProvider.selectedLanguage.toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.onSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.swap_horiz_rounded, size: 20),
              onPressed: showProviderSelector,
              color: colorScheme.onPrimary,
              tooltip: 'Change Provider',
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16, right: 60),
        title: Text(
          widget.mangaTitle ?? 'Chapters',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary.withOpacity(0.1),
                colorScheme.surface,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndControls(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: searchController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search chapters...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.primary,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            searchController.clear();
                            chaptersProvider.clearSearch();
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
          // Sort Button
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: Icon(
                _isDescending 
                    ? Icons.arrow_downward_rounded 
                    : Icons.arrow_upward_rounded,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _isDescending = !_isDescending;
                });
                // TODO: Implement sorting in provider
              },
              color: colorScheme.primary,
              tooltip: _isDescending ? 'Newest first' : 'Oldest first',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderInfo(ColorScheme colorScheme) {
    return ListenableBuilder(
      listenable: chaptersProvider,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withOpacity(0.15),
                colorScheme.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.cloud_done_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chaptersProvider.currentProvider.name,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            chaptersProvider.currentProvider.baseUrl,
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chaptersProvider.supportsLanguageSelection) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                          Icon(
                            Icons.translate_rounded,
                            size: 12,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Mangadex.getLanguageName(chaptersProvider.selectedLanguage),
                            style: TextStyle(
                              color: colorScheme.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${chaptersProvider.filteredChapters.length} ch',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChaptersList(ColorScheme colorScheme) {
    return ListenableBuilder(
      listenable: chaptersProvider,
      builder: (context, child) {
        if (chaptersProvider.isLoading) {
          return SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildChapterSkeleton(colorScheme),
                childCount: 8,
              ),
            ),
          );
        }

        if (chaptersProvider.hasError) {
          return SliverFillRemaining(
            child: _buildErrorState(colorScheme, chaptersProvider),
          );
        }

        if (chaptersProvider.filteredChapters.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(colorScheme),
          );
        }

        final chapters = _isDescending
            ? chaptersProvider.filteredChapters
            : chaptersProvider.filteredChapters.reversed.toList();

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final chapter = chapters[index];
                return _buildChapterCard(chapter, colorScheme, index, chapters);
              },
              childCount: chapters.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChapterCard(dynamic chapter, ColorScheme colorScheme, int index, List<dynamic> allChapters) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + (index * 30).clamp(0, 300)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              // Navigate to reading page with provider
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ReadingPage(
                    chapterId: chapter.chapterId ?? '',
                    chapterName: chapter.chapterName ?? 'Unknown',
                    mangaTitle: widget.mangaTitle,
                    provider: chaptersProvider.currentProvider,
                    allChapterIds: allChapters.map<String>((c) => c.chapterId ?? '').toList(),
                    currentIndex: index,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Chapter Number Badge
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${chapter.chapterName ?? '?'}',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Chapter Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chapter ${chapter.chapterName ?? 'Unknown'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (chapter.translatedLanguage != null)
                          Row(
                            children: [
                              Icon(
                                Icons.translate_rounded,
                                size: 14,
                                color: colorScheme.primary.withOpacity(0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                chapter.translatedLanguage!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Arrow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChapterSkeleton(ColorScheme colorScheme) {
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surface,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
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
                    height: 16,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 80,
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
  }

  Widget _buildErrorState(ColorScheme colorScheme, ChaptersProvider chaptersProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Error loading chapters',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              chaptersProvider.errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (widget.mangaId != null) {
                chaptersProvider.loadChapters(widget.mangaId!);
              }
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
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
              Icons.menu_book_rounded,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No chapters found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            chaptersProvider.supportsLanguageSelection
                ? 'Try changing the language or provider'
                : 'Try changing the provider or\ncheck back later',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          if (chaptersProvider.supportsLanguageSelection) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: showLanguageSelector,
              icon: const Icon(Icons.translate_rounded),
              label: const Text('Change Language'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
