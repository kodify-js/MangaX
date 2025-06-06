enum Settings {
  accentColor("accentColor"),
  isAmmoled("isAmmoled");

  final String value;
  const Settings(this.value);
}

enum Catagories {
  action("Action"),
  adventure("Adventure"),
  comedy("Comedy"),
  horror("Horror"),
  romance("Romance"),
  sports("Sports");

  final String value;
  const Catagories(this.value);
}

enum Sort {
  popular("POPULARITY_DESC"),
  latest("START_DATE_DESC"),
  trending("TRENDING_DESC"),
  top("FAVOURITES_DESC"),
  alphabetic("TITLE_ROMAJI"),
  score("SCORE_DESC"),
  added("ID_DESC");

  final String value;
  const Sort(this.value);
}

enum Genres {
  action("Action"),
  adventure("Adventure"),
  comedy("Comedy"),
  drama("Drama"),
  ecchi("Ecchi"),
  fantasy("Fantasy"),
  hentai("Hentai"),
  horror("Horror"),
  mahouShoujo("Mahou Shoujo"),
  mecha("Mecha"),
  music("Music"),
  mystery("Mystery"),
  psychological("Psychological"),
  romance("Romance"),
  sciFi("Sci-Fi"),
  sliceOfLife("Slice of Life"),
  sports("Sports"),
  supernatural("Supernatural"),
  thriller("Thriller");

  final String value;
  const Genres(this.value);
}

enum Sources {
  manga("MANGA"),
  webNovel("WEB_NOVEL"),
  original("ORIGINAL"),
  novel("NOVEL"),
  lightNovel("LIGHT_NOVEL");

  final String value;
  const Sources(this.value);
}

enum Status {
  releasing("RELEASING"),
  finished("FINISHED"),
  notYetReleased("NOT_YET_RELEASED"),
  hiatus("HIATUS"),
  cancelled("CANCELLED");

  final String value;
  const Status(this.value);
}

enum Countries {
  japan("JP", "Japan"),
  korea("KR", "Korea"),
  china("CN", "China"),
  usa("US", "USA"),
  uk("GB", "UK"),
  france("FR", "France"),
  germany("DE", "Germany"),
  thailand("TH", "Thailand"),
  indonesia("ID", "Indonesia"),
  philippines("PH", "Philippines"),
  vietnam("VN", "Vietnam"),
  malaysia("MY", "Malaysia"),
  singapore("SG", "Singapore"),
  taiwan("TW", "Taiwan"),
  hongKong("HK", "Hong Kong");

  final String code;
  final String name;
  const Countries(this.code, this.name);
}

enum PopularTags {
  school("School"),
  isekai("Isekai"),
  magic("Magic"),
  martialArts("Martial Arts"),
  cultivation("Cultivation"),
  femaleProtagonist("Female Protagonist"),
  maleProtagonist("Male Protagonist"),
  reincarnation("Reincarnation"),
  timeTravel("Time Travel"),
  overpowered("Overpowered"),
  weakToStrong("Weak to Strong"),
  system("System"),
  harem("Harem"),
  romanceTag("Romance"),
  medieval("Medieval"),
  modernDay("Modern Day"),
  demons("Demons"),
  dragons("Dragons"),
  nobles("Nobles"),
  academy("Academy");

  final String value;
  const PopularTags(this.value);
}
