import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangax/api/providers/base_provider.dart';
import 'package:mangax/widgets/cached_image.dart';

class ReadingPage extends StatefulWidget {
  final String chapterId;
  final String chapterName;
  final String? mangaTitle;
  final MangaProvider provider;
  final List<String>? allChapterIds;
  final int? currentIndex;

  const ReadingPage({
    super.key,
    required this.chapterId,
    required this.chapterName,
    required this.provider,
    this.mangaTitle,
    this.allChapterIds,
    this.currentIndex,
  });

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage>
    with TickerProviderStateMixin {
  // Chapter data for continuous reading
  final List<_ChapterData> _loadedChapters = [];
  List<String> _allPages = [];

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;

  late PageController _pageController;
  late ScrollController _scrollController;
  int _currentPage = 0;
  String _currentChapterName = '';

  bool _isVerticalMode = true;
  late AnimationController _controlsAnimController;
  late Animation<double> _controlsAnimation;

  // Zoom
  final TransformationController _transformationController =
      TransformationController();
  double _currentZoom = 1.0;

  // Auto-scroll
  bool _isAutoScrolling = false;
  Timer? _autoScrollTimer;
  double _autoScrollSpeed = 2.0;

  // Progress
  double _readingProgress = 0.0;
  bool _isLoadingNextChapter = false;

  // Settings
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _controlsAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _controlsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controlsAnimController, curve: Curves.easeInOut),
    );
    _controlsAnimController.forward();

    _currentChapterName = widget.chapterName;

    _loadInitialChapter();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _controlsAnimController.dispose();
    _transformationController.dispose();
    _stopAutoScroll();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _allPages.isEmpty) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    setState(() {
      _readingProgress =
          maxScroll > 0 ? (currentScroll / maxScroll).clamp(0.0, 1.0) : 0.0;
    });

    _updateCurrentPageFromScroll();

    // Load next chapter when near end (90%)
    if (currentScroll > maxScroll * 0.9 && !_isLoadingNextChapter) {
      _loadNextChapterContinuous();
    }
  }

  void _updateCurrentPageFromScroll() {
    if (!_scrollController.hasClients || _allPages.isEmpty) return;

    final scrollFraction =
        _scrollController.offset /
        (_scrollController.position.maxScrollExtent.clamp(1, double.infinity));
    final estimatedPage = (scrollFraction * _allPages.length).floor();

    if (estimatedPage != _currentPage &&
        estimatedPage >= 0 &&
        estimatedPage < _allPages.length) {
      setState(() {
        _currentPage = estimatedPage;
        _updateCurrentChapterFromPage();
      });
    }
  }

  void _updateCurrentChapterFromPage() {
    int pageCount = 0;
    for (int i = 0; i < _loadedChapters.length; i++) {
      pageCount += _loadedChapters[i].pages.length;
      if (_currentPage < pageCount) {
        if (_currentChapterName != _loadedChapters[i].chapterName) {
          setState(() {
            _currentChapterName = _loadedChapters[i].chapterName;
          });
        }
        break;
      }
    }
  }

  Future<void> _loadInitialChapter() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final pages = await widget.provider.getChapterPages(widget.chapterId);
      final chapterData = _ChapterData(
        chapterId: widget.chapterId,
        chapterName: widget.chapterName,
        chapterIndex: widget.currentIndex ?? 0,
        pages: pages,
      );

      setState(() {
        _loadedChapters.add(chapterData);
        _allPages = pages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadNextChapterContinuous() async {
    if (_isLoadingNextChapter) return;
    if (widget.allChapterIds == null || _loadedChapters.isEmpty) return;

    final lastChapter = _loadedChapters.last;
    final nextIndex = lastChapter.chapterIndex - 1;

    if (nextIndex < 0 || nextIndex >= widget.allChapterIds!.length) return;

    setState(() => _isLoadingNextChapter = true);

    try {
      final nextChapterId = widget.allChapterIds![nextIndex];
      final pages = await widget.provider.getChapterPages(nextChapterId);

      final chapterData = _ChapterData(
        chapterId: nextChapterId,
        chapterName: '${nextIndex + 1}',
        chapterIndex: nextIndex,
        pages: pages,
      );

      setState(() {
        _loadedChapters.add(chapterData);
        _allPages = _loadedChapters.expand((c) => c.pages).toList();
        _isLoadingNextChapter = false;
      });
    } catch (e) {
      setState(() => _isLoadingNextChapter = false);
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      _showSettings = false;
    });
    if (_showControls) {
      _controlsAnimController.forward();
    } else {
      _controlsAnimController.reverse();
    }
  }

  void _toggleSettings() {
    setState(() => _showSettings = !_showSettings);
  }

  // Auto-scroll
  void _startAutoScroll() {
    if (_isAutoScrolling || !_isVerticalMode) return;
    setState(() => _isAutoScrolling = true);

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      if (!_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      if (currentScroll < maxScroll) {
        _scrollController.jumpTo(currentScroll + _autoScrollSpeed);
      } else {
        _stopAutoScroll();
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    if (mounted) setState(() => _isAutoScrolling = false);
  }

  void _toggleAutoScroll() {
    _isAutoScrolling ? _stopAutoScroll() : _startAutoScroll();
  }

  // Zoom
  void _zoomIn() {
    _currentZoom = (_currentZoom + 0.5).clamp(1.0, 4.0);
    _transformationController.value = Matrix4.identity()..scale(_currentZoom);
    setState(() {});
  }

  void _zoomOut() {
    _currentZoom = (_currentZoom - 0.5).clamp(1.0, 4.0);
    _transformationController.value = Matrix4.identity()..scale(_currentZoom);
    setState(() {});
  }

  void _resetZoom() {
    _currentZoom = 1.0;
    _transformationController.value = Matrix4.identity();
    setState(() {});
  }

  void _jumpToProgress(double progress) {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      maxScroll * progress,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Content
          if (_isLoading)
            _buildLoadingState(colorScheme)
          else if (_hasError)
            _buildErrorState(colorScheme)
          else
            GestureDetector(
              onTap: _toggleControls,
              child:
                  _isVerticalMode
                      ? _buildVerticalReader()
                      : _buildHorizontalReader(),
            ),

          // Top Controls
          if (!_isLoading && !_hasError)
            AnimatedBuilder(
              animation: _controlsAnimation,
              builder: (context, child) {
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, -80 * (1 - _controlsAnimation.value)),
                    child: Opacity(
                      opacity: _controlsAnimation.value,
                      child: _buildTopControls(colorScheme),
                    ),
                  ),
                );
              },
            ),

          // Progress bar (always visible when controls hidden)
          if (!_isLoading && !_hasError)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showControls ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  height: 3,
                  child: LinearProgressIndicator(
                    value: _readingProgress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Controls
          if (!_isLoading && !_hasError)
            AnimatedBuilder(
              animation: _controlsAnimation,
              builder: (context, child) {
                return Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, 200 * (1 - _controlsAnimation.value)),
                    child: Opacity(
                      opacity: _controlsAnimation.value,
                      child: _buildBottomControls(colorScheme),
                    ),
                  ),
                );
              },
            ),

          // Settings Panel
          if (_showSettings && _showControls) _buildSettingsPanel(colorScheme),

          // Loading next chapter indicator
          if (_isLoadingNextChapter)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Loading next chapter...',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Auto-scroll indicator
          if (_isAutoScrolling)
            Positioned(
              top: 100,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Auto ${_autoScrollSpeed.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerticalReader() {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 1.0,
      maxScale: 4.0,
      onInteractionEnd: (details) {
        setState(() {
          _currentZoom = _transformationController.value.getMaxScaleOnAxis();
        });
      },
      child: ListView.builder(
        controller: _scrollController,
        physics:
            _currentZoom > 1.0 ? const NeverScrollableScrollPhysics() : null,
        itemCount: _allPages.length + _loadedChapters.length - 1,
        itemBuilder: (context, index) {
          // Check if this is a chapter divider
          int pageIndex = index;
          int pagesBeforeThis = 0;

          for (int i = 0; i < _loadedChapters.length; i++) {
            if (i > 0 && index == pagesBeforeThis + i - 1) {
              return _buildChapterDivider(_loadedChapters[i]);
            }
            pagesBeforeThis += _loadedChapters[i].pages.length;
          }

          // Calculate actual page index
          int dividersBeforeThis = 0;
          int runningCount = 0;
          for (int i = 0; i < _loadedChapters.length; i++) {
            if (i > 0) dividersBeforeThis++;
            runningCount += _loadedChapters[i].pages.length;
            if (index - dividersBeforeThis < runningCount) break;
          }
          pageIndex = index - dividersBeforeThis;

          if (pageIndex < 0 || pageIndex >= _allPages.length) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: CachedImage(
              imageUrl: _allPages[pageIndex],
              fit: BoxFit.fitWidth,
              width: double.infinity,
              placeholder: _buildPagePlaceholder(pageIndex),
              headers: widget.provider.getImageHeaders(_allPages[pageIndex]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChapterDivider(_ChapterData chapter) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.2),
            colorScheme.primary.withOpacity(0.1),
            colorScheme.primary.withOpacity(0.2),
          ],
        ),
        border: Border.symmetric(
          horizontal: BorderSide(
            color: colorScheme.primary.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              'Chapter ${chapter.chapterName}',
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${chapter.pages.length} pages',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagePlaceholder(int index) {
    return Container(
      height: 500,
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.white54,
              strokeWidth: 2,
            ),
            const SizedBox(height: 12),
            Text(
              'Loading page ${index + 1}...',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalReader() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _allPages.length,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
          _readingProgress =
              _allPages.isNotEmpty
                  ? index / (_allPages.length - 1).clamp(1, double.infinity)
                  : 0;
          _updateCurrentChapterFromPage();
        });

        // Load next chapter when near end
        if (index > _allPages.length - 3 && !_isLoadingNextChapter) {
          _loadNextChapterContinuous();
        }
      },
      itemBuilder: (context, index) {
        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1.0,
          maxScale: 4.0,
          onInteractionEnd: (details) {
            setState(() {
              _currentZoom =
                  _transformationController.value.getMaxScaleOnAxis();
            });
          },
          child: Center(
            child: CachedImage(
              imageUrl: _allPages[index],
              fit: BoxFit.contain,
              placeholder: _buildPagePlaceholder(index),
              headers: widget.provider.getImageHeaders(_allPages[index]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopControls(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.9), Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: Colors.white,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.mangaTitle != null)
                      Text(
                        widget.mangaTitle!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      'Chapter $_currentChapterName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Zoom indicator
              if (_currentZoom > 1.0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentZoom.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              // Settings
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  color: Colors.white,
                  onPressed: _toggleSettings,
                ),
              ),
              const SizedBox(width: 8),
              // Reading mode toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    _isVerticalMode
                        ? Icons.swap_horiz_rounded
                        : Icons.swap_vert_rounded,
                  ),
                  color: Colors.white,
                  onPressed: () {
                    setState(() {
                      _isVerticalMode = !_isVerticalMode;
                      _resetZoom();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.95), Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Page indicator
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_currentPage + 1}',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' / ${_allPages.length}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 16,
                            ),
                          ),
                          if (_loadedChapters.length > 1) ...[
                            Container(
                              width: 1,
                              height: 16,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              color: Colors.white.withOpacity(0.3),
                            ),
                            Text(
                              '${_loadedChapters.length} ch',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Progress slider
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: colorScheme.primary,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: colorScheme.primary,
                    overlayColor: colorScheme.primary.withOpacity(0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _readingProgress,
                    min: 0,
                    max: 1,
                    onChanged: (value) {
                      setState(() => _readingProgress = value);
                      if (_isVerticalMode) {
                        _jumpToProgress(value);
                      } else {
                        final pageIndex =
                            (value * (_allPages.length - 1)).round();
                        _pageController.jumpToPage(pageIndex);
                      }
                    },
                  ),
                ),
              ),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_isVerticalMode)
                    _buildActionButton(
                      icon:
                          _isAutoScrolling
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                      label: _isAutoScrolling ? 'Stop' : 'Auto',
                      enabled: true,
                      onPressed: _toggleAutoScroll,
                      colorScheme: colorScheme,
                      isActive: _isAutoScrolling,
                    ),
                  if (_currentZoom != 1.0)
                    _buildActionButton(
                      icon: Icons.zoom_out_map_rounded,
                      label: 'Reset ${_currentZoom.toStringAsFixed(1)}x',
                      enabled: true,
                      onPressed: _resetZoom,
                      colorScheme: colorScheme,
                    ),
                  if (_currentZoom == 1.0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pinch_rounded,
                            color: Colors.white.withOpacity(0.5),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pinch to zoom',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
    bool isActive = false,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color:
                isActive
                    ? colorScheme.primary
                    : (enabled
                        ? colorScheme.primary.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isActive
                      ? colorScheme.primary
                      : (enabled
                          ? colorScheme.primary.withOpacity(0.5)
                          : Colors.transparent),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    isActive
                        ? Colors.white
                        : (enabled ? colorScheme.primary : Colors.white54),
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color:
                      isActive
                          ? Colors.white
                          : (enabled ? Colors.white70 : Colors.white38),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsPanel(ColorScheme colorScheme) {
    return Positioned(
      top: 100,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Reading Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Auto-scroll speed
              if (_isVerticalMode) ...[
                const Text(
                  'Auto-scroll Speed',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: colorScheme.primary,
                          inactiveTrackColor: Colors.white.withOpacity(0.2),
                          thumbColor: colorScheme.primary,
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: _autoScrollSpeed,
                          min: 0.5,
                          max: 5.0,
                          divisions: 9,
                          onChanged:
                              (value) =>
                                  setState(() => _autoScrollSpeed = value),
                        ),
                      ),
                    ),
                    Text(
                      '${_autoScrollSpeed.toStringAsFixed(1)}x',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Zoom
              const Text(
                'Zoom Level',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_out_rounded),
                    color: Colors.white,
                    onPressed: _currentZoom > 1.0 ? _zoomOut : null,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: colorScheme.primary,
                        inactiveTrackColor: Colors.white.withOpacity(0.2),
                        thumbColor: colorScheme.primary,
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _currentZoom,
                        min: 1.0,
                        max: 4.0,
                        divisions: 6,
                        onChanged: (value) {
                          setState(() {
                            _currentZoom = value;
                            _transformationController.value =
                                Matrix4.identity()..scale(_currentZoom);
                          });
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_in_rounded),
                    color: Colors.white,
                    onPressed: _currentZoom < 4.0 ? _zoomIn : null,
                  ),
                ],
              ),
              Center(
                child: TextButton(
                  onPressed: _resetZoom,
                  child: Text(
                    'Reset (${_currentZoom.toStringAsFixed(1)}x)',
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
              ),

              const Divider(color: Colors.white24),

              // Reading mode
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _isVerticalMode
                      ? Icons.swap_vert_rounded
                      : Icons.swap_horiz_rounded,
                  color: colorScheme.primary,
                ),
                title: Text(
                  _isVerticalMode ? 'Vertical Scroll' : 'Horizontal Pages',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: Switch(
                  value: _isVerticalMode,
                  onChanged: (value) {
                    setState(() {
                      _isVerticalMode = value;
                      _resetZoom();
                    });
                  },
                  activeColor: colorScheme.primary,
                ),
              ),

              // Provider info
              const Divider(color: Colors.white24),
              Row(
                children: [
                  Icon(
                    Icons.cloud_rounded,
                    color: colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Source: ${widget.provider.name}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading pages...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chapter ${widget.chapterName}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'via ${widget.provider.name}',
            style: TextStyle(
              color: colorScheme.primary.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Failed to load chapter',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _loadInitialChapter,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class to store chapter data with pages
class _ChapterData {
  final String chapterId;
  final String chapterName;
  final List<String> pages;
  final int chapterIndex;

  _ChapterData({
    required this.chapterId,
    required this.chapterName,
    required this.pages,
    required this.chapterIndex,
  });
}
