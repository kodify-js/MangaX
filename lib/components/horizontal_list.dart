import 'package:mangax/Classes/manga_class.dart';
import 'package:mangax/pages/catagory_page.dart';
import 'package:mangax/pages/infopage.dart';
import 'package:flutter/material.dart';

class HorizontalList extends StatefulWidget {
  final List<MangaClass> mangaList;
  final String title;
  final String? sort;
  final String? country;
  const HorizontalList({
    super.key,
    required this.mangaList,
    required this.title,
    this.sort,
    this.country,
  });

  @override
  State<HorizontalList> createState() => _HorizontalListState();
}

class _HorizontalListState extends State<HorizontalList> {
  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollBehavior(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Sayyeda',
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.start,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) => CatagoryPage(
                              sort: widget.sort,
                              title: widget.title,
                              country: widget.country,
                            ),
                      ),
                    );
                  },
                  child: Text('See All'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 250,
            child: ListView.builder(
              itemCount: widget.mangaList.length,
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final manga = widget.mangaList[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Infopage(mangaId: manga.id!),
                      ),
                    );
                  },
                  child: Container(
                    width: 150,
                    margin: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              manga.coverImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          manga.title!,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.bodyLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
}
