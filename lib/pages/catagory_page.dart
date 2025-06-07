import 'package:mangax/api/api.dart';
import 'package:mangax/pages/infopage.dart';
import 'package:mangax/Classes/manga_class.dart';
import 'package:flutter/material.dart';

class CatagoryPage extends StatefulWidget {
  final List<String>? catagory;
  final String? sort;
  final String? country;
  final String? title;
  const CatagoryPage({
    super.key,
    this.catagory,
    this.sort,
    this.country,
    this.title,
  });

  @override
  State<CatagoryPage> createState() => _CatagoryPageState();
}

class _CatagoryPageState extends State<CatagoryPage> {
  List<MangaClass> mangaList = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMangaData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is 200 pixels from bottom
      _loadMoreData();
    }
  }

  Future<void> _loadMangaData() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });
    try {
      final newManga = await Api().searchManga(
        page: currentPage,
        perPage: 18,
        genre: widget.catagory,
        sort: widget.sort,
        countryOfOrigin: widget.country,
      );

      setState(() {
        if (currentPage == 1) {
          mangaList = newManga;
        } else {
          mangaList.addAll(newManga);
        }

        // Check if we have more data
        hasMoreData = newManga.length == 18;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error loading manga: $error');
    }
  }

  Future<void> _loadMoreData() async {
    if (!hasMoreData || isLoading) return;

    currentPage++;
    await _loadMangaData();
  }

  Future<void> _refreshData() async {
    setState(() {
      currentPage = 1;
      mangaList.clear();
      hasMoreData = true;
    });
    await _loadMangaData();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        widget.title != null
                            ? widget.title!
                            : widget.catagory != null
                            ? widget.catagory!.join(",").toString()
                            : "Category",
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Sayyeda',
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child:
                    mangaList.isEmpty && isLoading
                        ? Center(child: CircularProgressIndicator())
                        : mangaList.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text('No manga found for this category'),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshData,
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        )
                        : CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.all(8.0),
                              sliver: SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 0.6,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final manga = mangaList[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  Infopage(mangaId: manga.id!),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              color: Colors.grey[300],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              child: Image.network(
                                                manga.coverImage!,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Container(
                                                    color: Colors.grey[300],
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey[600],
                                                      size: 40,
                                                    ),
                                                  );
                                                },
                                                loadingBuilder: (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Container(
                                                    color: Colors.grey[200],
                                                    child: Center(
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        value:
                                                            loadingProgress
                                                                        .expectedTotalBytes !=
                                                                    null
                                                                ? loadingProgress
                                                                        .cumulativeBytesLoaded /
                                                                    loadingProgress
                                                                        .expectedTotalBytes!
                                                                : null,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 8.0),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          child: Text(
                                            manga.title!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              overflow: TextOverflow.ellipsis,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withAlpha(150),
                                            ),
                                            maxLines: 1,
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }, childCount: mangaList.length),
                              ),
                            ),
                            if (hasMoreData && isLoading)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                          ],
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
