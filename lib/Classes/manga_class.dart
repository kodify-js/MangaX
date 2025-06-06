class RelatedManga {
  String? id;
  String? title;
  String? coverImage;

  RelatedManga({this.id, this.title, this.coverImage});
}

class CharacterPreview {
  String? id;
  String? name;
  String? role;
  String? imageUrl;

  CharacterPreview({this.id, this.name, this.imageUrl, this.role});
}

class MangaClass {
  String? id;
  String? title;
  String? coverImage;
  String? description;
  String? bannerImage = '';
  String? status;
  String? author;
  List? genre;
  int? chaptersCount;
  String? color;
  List<CharacterPreview>? characters;
  double? rating;
  List<RelatedManga>? recommendations;
  List<String>? synonyms;

  MangaClass({
    this.id,
    this.title,
    this.coverImage,
    this.description,
    this.status,
    this.author,
    this.genre,
    this.chaptersCount,
    this.color,
    this.characters,
    this.rating,
    this.bannerImage,
    this.recommendations,
    this.synonyms,
  });
}
