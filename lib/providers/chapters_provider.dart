import 'package:flutter/foundation.dart';
import '../api/providers/base_provider.dart';
import '../api/providers/provider_manager.dart';
import '../api/providers/mangadex.dart';
import '../Classes/chapters_class.dart';

class ChaptersProvider extends ChangeNotifier {
  List<ChaptersClass> _chapters = [];
  List<ChaptersClass> _filteredChapters = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  MangaProvider _currentProvider = ProviderManager.defaultProvider;
  String _searchQuery = '';
  String _selectedLanguage = 'en';
  Set<String> _availableLanguages = {'en'};
  bool _isLoadingLanguages = false;
  String? _currentMangaId; // Cache the manga ID
  int _totalChapters = 0;
  int _loadedChapters = 0;

  List<ChaptersClass> get chapters => _chapters;
  List<ChaptersClass> get filteredChapters => _filteredChapters;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  MangaProvider get currentProvider => _currentProvider;
  String get searchQuery => _searchQuery;
  String get selectedLanguage => _selectedLanguage;
  Set<String> get availableLanguages => _availableLanguages;
  bool get isLoadingLanguages => _isLoadingLanguages;
  int get totalChapters => _totalChapters;
  int get loadedChapters => _loadedChapters;
  String? get currentMangaId => _currentMangaId;

  // Check if current provider supports language selection
  bool get supportsLanguageSelection => _currentProvider is Mangadex;

  Future<void> loadChapters(String name) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      if (_currentProvider is Mangadex) {
        final mangadex = _currentProvider as Mangadex;
        mangadex.setLanguage(_selectedLanguage);

        // First search to get the manga ID if we don't have it
        if (_currentMangaId == null) {
          final search = await mangadex.searchManga(name);
          if (search['data'] == null || search['data'].isEmpty) {
            _chapters = [];
            _filteredChapters = [];
            _isLoading = false;
            notifyListeners();
            return;
          }
          _currentMangaId = search['data'][0]['id'];
        }

        // Now load all chapters using the manga ID
        _chapters = await mangadex.getAllChapters(
          _currentMangaId!,
          language: _selectedLanguage,
        );
      } else {
        _chapters = await _currentProvider.getChapters(
          name,
          language: _selectedLanguage,
        );
      }

      // If no chapters found and current provider is not MangaDex, fallback to MangaDex
      if (_chapters.isEmpty && _currentProvider is! Mangadex) {
        print(
          'No chapters found with ${_currentProvider.name}, falling back to MangaDex',
        );
        final mangadexProvider = ProviderManager.getProviderByName('MangaDex');
        if (mangadexProvider != null && mangadexProvider is Mangadex) {
          final mangadex = mangadexProvider as Mangadex;
          mangadex.setLanguage(_selectedLanguage);

          final search = await mangadex.searchManga(name);
          if (search['data'] != null && search['data'].isNotEmpty) {
            _currentMangaId = search['data'][0]['id'];
            _chapters = await mangadex.getAllChapters(
              _currentMangaId!,
              language: _selectedLanguage,
            );

            // Only switch provider if we found chapters
            if (_chapters.isNotEmpty) {
              _currentProvider = mangadexProvider;
              print(
                'Successfully loaded ${_chapters.length} chapters from MangaDex',
              );
            }
          }
        }
      }

      _totalChapters = _chapters.length;
      _loadedChapters = _chapters.length;
      _filterChapters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadAvailableLanguages(String mangaTitle) async {
    if (_currentProvider is! Mangadex) return;

    _isLoadingLanguages = true;
    notifyListeners();

    try {
      final mangadex = _currentProvider as Mangadex;

      // First search to get the manga ID if we don't have it
      if (_currentMangaId == null) {
        final search = await mangadex.searchManga(mangaTitle);
        if (search['data'] != null && search['data'].isNotEmpty) {
          _currentMangaId = search['data'][0]['id'];
        }
      }

      if (_currentMangaId != null) {
        _availableLanguages = await mangadex.getAvailableLanguages(
          _currentMangaId!,
        );
        if (_availableLanguages.isNotEmpty &&
            !_availableLanguages.contains(_selectedLanguage)) {
          _selectedLanguage =
              _availableLanguages.contains('en')
                  ? 'en'
                  : _availableLanguages.first;
        }
      }
    } catch (e) {
      // Keep default language if loading fails
      _availableLanguages = {'en'};
    }

    _isLoadingLanguages = false;
    notifyListeners();
  }

  void changeLanguage(String languageCode, String mangaTitle) {
    if (_selectedLanguage != languageCode) {
      _selectedLanguage = languageCode;
      if (_currentProvider is Mangadex) {
        (_currentProvider as Mangadex).setLanguage(languageCode);
      }
      // Use cached manga ID if available
      if (_currentMangaId != null) {
        _loadChaptersByMangaId(_currentMangaId!);
      } else {
        loadChapters(mangaTitle);
      }
    }
  }

  Future<void> _loadChaptersByMangaId(String mangaId) async {
    if (_currentProvider is! Mangadex) return;

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final mangadex = _currentProvider as Mangadex;
      _chapters = await mangadex.getAllChapters(
        mangaId,
        language: _selectedLanguage,
      );
      _totalChapters = _chapters.length;
      _loadedChapters = _chapters.length;
      _filterChapters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void searchChapters(String query) {
    _searchQuery = query.toLowerCase();
    _filterChapters();
    notifyListeners();
  }

  void _filterChapters() {
    if (_searchQuery.isEmpty) {
      _filteredChapters = _chapters;
    } else {
      _filteredChapters =
          _chapters.where((chapter) {
            final chapterName = chapter.chapterName?.toLowerCase() ?? '';
            final chapterId = chapter.chapterId?.toLowerCase() ?? '';
            return chapterName.contains(_searchQuery) ||
                chapterId.contains(_searchQuery);
          }).toList();
    }
  }

  void changeProvider(MangaProvider provider, String mangaId) {
    if (provider.name != _currentProvider.name) {
      _currentProvider = provider;
      _currentMangaId = null; // Reset cached manga ID when provider changes
      _availableLanguages = {'en'};
      _selectedLanguage = 'en';
      loadChapters(mangaId);
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _filterChapters();
    notifyListeners();
  }

  // Reset state when leaving the page
  void reset() {
    _currentMangaId = null;
    _chapters = [];
    _filteredChapters = [];
    _availableLanguages = {'en'};
    _selectedLanguage = 'en';
  }
}
