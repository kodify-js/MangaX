class CharacterName {
  final String first;
  final String name;
  final String middle;
  final String last;
  final String userPreferred;
  final List<String> alternative;

  CharacterName({
    required this.first,
    required this.name,
    required this.middle,
    required this.last,
    required this.userPreferred,
    required this.alternative,
  });
}

class CharacterClass {
  final int id;
  final CharacterName name;
  final String age;
  final String imageUrl;
  final String gender;
  final String bloodType;

  CharacterClass({
    required this.id,
    required this.name,
    required this.age,
    required this.imageUrl,
    required this.gender,
    required this.bloodType,
  });
}
