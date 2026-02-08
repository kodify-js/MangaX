# MangaX 📚

<p align="center">
  <img src="assets/images/icon.png" alt="MangaX Logo" width="120"/>
</p>

<p align="center">
  A beautiful, open-source manga reader app built with Flutter. Browse, search, and read manga from multiple sources with a modern, customizable UI.
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#installation">Installation</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#contributing">Contributing</a>
</p>

---

## ✨ Features

- 🔍 **Multi-Source Support** - Browse manga from multiple providers (MangaDex, MangaKakalot, and more)
- 🌐 **Multi-Language Support** - Read chapters in 50+ languages
- 🎨 **Customizable Themes** - Dynamic accent colors and AMOLED dark mode
- 📖 **Advanced Reader** - Vertical/horizontal reading modes, zoom, auto-scroll
- 🔎 **Smart Search** - Filter by genre, status, source, country, and more
- 📱 **Cross-Platform** - Android, iOS, Web, Windows, macOS, and Linux
- ⚡ **Optimized Performance** - Image caching, lazy loading, and rate limiting
- 🎯 **Modern UI** - Material Design 3 with smooth animations

---

## 🏗️ Architecture

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── api/
│   ├── api.dart              # Main API service class
│   └── providers/            # Manga source providers
│       ├── base_provider.dart
│       ├── mangadex.dart
│       ├── mangakakalot.dart
│       └── provider_manager.dart
├── Classes/                  # Data models
│   ├── manga_class.dart
│   ├── Chapters_class.dart
│   └── character_class.dart
├── components/               # Reusable UI components
│   ├── carousel.dart
│   └── horizontal_list.dart
├── models/                   # State models
│   └── search_filter_state.dart
├── pages/                    # App screens
│   ├── home.dart
│   ├── search.dart
│   ├── infopage.dart
│   ├── chapters_page.dart
│   ├── reading_page.dart
│   ├── catagory_page.dart
│   └── character_info.dart
├── providers/                # State management
│   └── theme_provider.dart
├── utils/                    # Utilities
│   ├── constants.dart
│   └── utils.dart
└── widgets/                  # Custom widgets
    ├── cached_image.dart
    ├── filter_bottom_sheet.dart
    └── skeleton_loaders.dart
```

---

## 📦 Data Models

### MangaClass
Represents a manga with all its metadata:

```dart
class MangaClass {
  String? id;              // Unique identifier (prefixed by source)
  String? title;           // Manga title
  String? coverImage;      // Cover image URL
  String? description;     // Synopsis/description
  String? bannerImage;     // Banner image URL
  String? status;          // RELEASING, FINISHED, HIATUS, etc.
  String? author;          // Author name
  List? genre;             // List of genres
  int? chaptersCount;      // Total chapters
  double? rating;          // Rating (0-10)
  List<CharacterPreview>? characters;
  List<RelatedManga>? recommendations;
  List<String>? synonyms;  // Alternative titles
}
```

### ChaptersClass
Represents a manga chapter:

```dart
class ChaptersClass {
  String? chapterName;        // Chapter number/title
  String? chapterId;          // Unique chapter ID
  String? chapterUrl;         // API endpoint URL
  String? translatedLanguage; // Language code (en, ja, ko, etc.)
}
```

---

## 🔌 Provider System

MangaX uses a flexible provider system to support multiple manga sources.

### Base Provider Interface

```dart
abstract class MangaProvider {
  String get name;
  String get baseUrl;
  
  Future<List<ChaptersClass>> getAllChapters(String mangaId, {int offset, String? language});
  Future<List<ChaptersClass>> getChapters(String query, {String? language});
  Future searchManga(String query);
  Future<List<String>> getChapterPages(String chapterId);
  
  // Language support
  String get selectedLanguage;
  void setLanguage(String languageCode);
  Map<String, String> get supportedLanguages;
}
```

### Adding a New Provider

1. Create a new file in `lib/api/providers/`:

```dart
import 'base_provider.dart';

class MyNewProvider extends MangaProvider {
  @override
  String get name => 'MyProvider';

  @override
  String get baseUrl => 'https://api.myprovider.com';

  @override
  Future<List<ChaptersClass>> getAllChapters(String mangaId, {int offset = 0, String? language}) async {
    // Implementation
  }

  // Implement other required methods...
}
```

2. Register in `provider_manager.dart`:

```dart
static final List<MangaProvider> _providers = [
  Mangadex(),
  MangaKakalot(),
  MyNewProvider(), // Add your provider here
];
```

### Supported Providers

| Provider | Status | Features |
|----------|--------|----------|
| MangaDex | ✅ Full | 50+ languages, ratings, statistics |
| MangaKakalot | 🚧 Partial | English only, basic functionality |

---

## 🌐 API Service

The main `Api` class (`lib/api/api.dart`) provides methods for fetching manga data:

### Available Methods

```dart
// Trending & Popular
Future<List<MangaClass>> getTrendingManga(int page, int perPage)
Future<List<MangaClass>> getPopularManga(int page, int perPage)
Future<List<MangaClass>> getTrendingByCountry(String country, int page, int perPage)

// Search & Discovery
Future<List<MangaClass>> searchManga(String query, {filters})
Future<List<MangaClass>> getMangaByGenre(String genre, int page, int perPage)

// Details
Future<MangaClass> getMangaDetails(String mangaId)
Future<List<ChaptersClass>> getChapters(String mangaId)
Future<List<String>> getChapterPages(String chapterId)

// Statistics
Future<Map<String, double>> getMangaStatistics(List<String> mangaIds)
```

### Rate Limiting

The API implements automatic rate limiting for MangaDex requests (500ms minimum between requests) to comply with API guidelines.

---

## 🎨 Theming

MangaX uses Material Design 3 with dynamic theming.

### Theme Provider

```dart
class TheameProvider extends ChangeNotifier {
  // Customizable accent color
  void setAccentColor(Color color);
  
  // AMOLED black mode
  void setIsAmmoled(bool isAmmoled);
  
  // Get current theme
  ThemeData getTheme();
}
```

### Settings Persistence

Settings are persisted using `SharedPreferences`:
- `accentColor` - Custom accent color
- `isAmmoled` - AMOLED dark mode toggle

---

## 📱 Pages

### Home Page (`home.dart`)
- Featured manga carousel
- Popular manga horizontal list
- Trending Manhwa (Korean) section
- Trending Manhua (Chinese) section
- Pull-to-refresh functionality

### Search Page (`search.dart`)
- Real-time search with debouncing
- Advanced filters:
  - Source type (Manga, Web Novel, Light Novel, etc.)
  - Genres (19 categories)
  - Status (Releasing, Finished, Hiatus, etc.)
  - Sort options (Popularity, Rating, Latest, etc.)
  - Country of origin
- Infinite scroll pagination

### Info Page (`infopage.dart`)
- Detailed manga information
- Chapter list with language selection
- Recommendations section
- Character previews
- Action buttons (Read, Bookmark, Share)

### Reading Page (`reading_page.dart`)
- Vertical and horizontal reading modes
- Pinch-to-zoom
- Auto-scroll with adjustable speed
- Progress tracking
- Continuous chapter loading
- Immersive fullscreen mode

### Category Page (`catagory_page.dart`)
- Browse by genre
- Grid/list view toggle
- Sorting options

---

## 🧩 Components

### Carousel
A featured manga carousel with:
- Auto-advancement
- Smooth page transitions
- Gradient overlays
- Tap-to-view functionality

### HorizontalList
A horizontal scrollable list for manga collections with:
- Lazy image loading
- Shimmer loading effects
- Quick navigation

### CachedImage
Optimized network image widget with:
- Disk caching via `cached_network_image`
- Placeholder shimmer effect
- Error handling

### Skeleton Loaders
Beautiful loading states using `shimmer` package for:
- Carousel skeleton
- Info page skeleton
- List item skeletons

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8      # iOS-style icons
  provider: ^6.1.5             # State management
  shared_preferences: ^2.5.3   # Local storage
  http: ^1.4.0                 # HTTP client
  cached_network_image: ^3.3.1 # Image caching
  shimmer: ^3.0.0              # Loading effects

dev_dependencies:
  flutter_lints: ^5.0.0        # Code quality
  change_app_package_name: ^1.5.0
  rename_app: ^1.6.3
```

---

## 🚀 Installation

### Prerequisites

- Flutter SDK ^3.7.2
- Dart SDK ^3.7.2
- Android Studio / VS Code with Flutter extensions

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/mangax.git
   cd mangax
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # Debug mode
   flutter run
   
   # Release mode
   flutter run --release
   ```

### Building

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Adding New Features

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Run tests: `flutter test`
5. Commit: `git commit -m 'Add amazing feature'`
6. Push: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Adding New Manga Sources

1. Create a new provider in `lib/api/providers/`
2. Implement the `MangaProvider` interface
3. Register in `ProviderManager`
4. Test thoroughly with various manga IDs
5. Submit a PR with documentation

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use the included `analysis_options.yaml` for linting
- Write meaningful commit messages
- Add comments for complex logic

### Reporting Issues

- Use the GitHub issue tracker
- Include device/OS information
- Provide steps to reproduce
- Include error logs if available

---

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

---

## 🙏 Acknowledgments

- [MangaDex API](https://api.mangadex.org/docs/) for providing manga data
- Flutter team for the amazing framework
- All contributors who help improve this project

---

## 📞 Contact

- Create an issue for bug reports or feature requests
- Star ⭐ this repo if you find it useful!

