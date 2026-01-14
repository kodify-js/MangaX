import 'base_provider.dart';
import 'mangadex.dart';
import 'mangakakalot.dart';

class ProviderManager {
  static final List<MangaProvider> _providers = [
    Mangadex(),
    MangaKakalot(),
    // Add more providers here in the future
  ];

  static List<MangaProvider> get providers => _providers;

  static MangaProvider get defaultProvider => _providers.first;

  static MangaProvider? getProviderByName(String name) {
    try {
      return _providers.firstWhere((provider) => provider.name == name);
    } catch (e) {
      return null;
    }
  }
}
