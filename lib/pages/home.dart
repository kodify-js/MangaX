import 'package:mangax/Classes/manga_class.dart';
import 'package:mangax/api/api.dart';
import 'package:mangax/components/carousel.dart';
import 'package:mangax/components/horizontal_list.dart';
import 'package:mangax/pages/search.dart';
import 'package:mangax/utils/constants.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    Api api = Api();
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  FutureBuilder<List<MangaClass>>(
                    future: api.getTrendingManga(1, 10),
                    builder: (context, index) {
                      if (index.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (index.hasError) {
                        return Center(child: Text('Error: ${index.error}'));
                      } else if (!index.hasData || index.data!.isEmpty) {
                        return Center(child: Text('No data found'));
                      } else {
                        final mangaList = index.data!;
                        return SizedBox(
                          width: double.infinity,
                          height: 400,
                          child: Carousel(mangaList: mangaList),
                        );
                      }
                    },
                  ),
                  FutureBuilder<List<MangaClass>>(
                    future: api.getPopularManga(1, 10),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('No data found'));
                      } else {
                        final mangaList = snapshot.data!;
                        return SizedBox(
                          width: double.infinity,
                          child: HorizontalList(
                            mangaList: mangaList,
                            title: "Popular Manga",
                            sort: Sort.popular.value,
                          ),
                        );
                      }
                    },
                  ),
                  FutureBuilder<List<MangaClass>>(
                    future: api.getTrendingByCountry("KR", 1, 10),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('No data found'));
                      } else {
                        final mangaList = snapshot.data!;
                        return SizedBox(
                          width: double.infinity,
                          child: HorizontalList(
                            mangaList: mangaList,
                            title: 'Trending Manhwa',
                            country: "KR",
                            sort: Sort.trending.value,
                          ),
                        );
                      }
                    },
                  ),
                  FutureBuilder<List<MangaClass>>(
                    future: api.getTrendingByCountry("CN", 1, 10),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('No data found'));
                      } else {
                        final mangaList = snapshot.data!;
                        return SizedBox(
                          width: double.infinity,
                          child: HorizontalList(
                            mangaList: mangaList,
                            country: "CN",
                            sort: Sort.trending.value,
                            title: "Trending Manhua",
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Row(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Manga',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            fontSize: 32,
                            fontFamily: 'MangaX',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'X',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 40,
                            fontFamily: 'MangaX',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(flex: 1, child: Container()),
                        IconButton(
                          icon: Icon(Icons.shuffle, color: Colors.white),
                          onPressed: () {
                            // Implement settings functionality
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.search, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SearchPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
