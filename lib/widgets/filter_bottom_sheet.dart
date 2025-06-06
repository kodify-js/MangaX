import 'package:flutter/material.dart';
import 'package:mangax/utils/constants.dart';

class FilterBottomSheet extends StatefulWidget {
  final String selectedSource;
  final List<String> selectedGenres;
  final String selectedStatus;
  final String selectedSortBy;
  final String selectedCountry;
  final Function(String, List<String>, String, String, String) onFiltersChanged;

  const FilterBottomSheet({
    super.key,
    required this.selectedSource,
    required this.selectedGenres,
    required this.selectedStatus,
    required this.selectedSortBy,
    required this.selectedCountry,
    required this.onFiltersChanged,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String selectedSource;
  late List<String> selectedGenres;
  late String selectedStatus;
  late String selectedSortBy;
  late String selectedCountry;

  @override
  void initState() {
    super.initState();
    selectedSource = widget.selectedSource;
    selectedGenres = List.from(widget.selectedGenres);
    selectedStatus = widget.selectedStatus;
    selectedSortBy = widget.selectedSortBy;
    selectedCountry = widget.selectedCountry;
  }

  void _clearAllFilters() {
    setState(() {
      selectedSource = '';
      selectedGenres.clear();
      selectedStatus = '';
      selectedSortBy = '';
      selectedCountry = '';
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(
      selectedSource,
      selectedGenres,
      selectedStatus,
      selectedSortBy,
      selectedCountry,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: Text('Clear All'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSortSection(),
                  SizedBox(height: 16),
                  _buildCountrySection(),
                  SizedBox(height: 16),
                  _buildSourceSection(),
                  SizedBox(height: 16),
                  _buildGenresSection(),
                  SizedBox(height: 16),
                  _buildPopularTagsSection(),
                  SizedBox(height: 16),
                  _buildStatusSection(),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              Sort.values
                  .map(
                    (sort) => FilterChip(
                      label: Text(sort.value.replaceAll('_', ' ')),
                      selected: selectedSortBy == sort.value,
                      onSelected: (selected) {
                        setState(() {
                          selectedSortBy = selected ? sort.value : '';
                        });
                      },
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildCountrySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Country',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              Countries.values
                  .map(
                    (country) => FilterChip(
                      label: Text(country.name),
                      selected: selectedCountry == country.code,
                      onSelected: (selected) {
                        setState(() {
                          selectedCountry = selected ? country.code : '';
                        });
                      },
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildSourceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Source',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              Sources.values
                  .map(
                    (source) => FilterChip(
                      label: Text(source.value.replaceAll('_', ' ')),
                      selected: selectedSource == source.value,
                      onSelected: (selected) {
                        setState(() {
                          selectedSource = selected ? source.value : '';
                        });
                      },
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildGenresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genres',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              Genres.values
                  .map(
                    (genre) => FilterChip(
                      label: Text(genre.value),
                      selected: selectedGenres.contains(genre.value),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedGenres.add(genre.value);
                          } else {
                            selectedGenres.remove(genre.value);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildPopularTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Tags',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              PopularTags.values
                  .map(
                    (tag) => FilterChip(
                      label: Text(tag.value),
                      selected: selectedGenres.contains(tag.value),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedGenres.add(tag.value);
                          } else {
                            selectedGenres.remove(tag.value);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              Status.values
                  .map(
                    (status) => FilterChip(
                      label: Text(status.value.replaceAll('_', ' ')),
                      selected: selectedStatus == status.value,
                      onSelected: (selected) {
                        setState(() {
                          selectedStatus = selected ? status.value : '';
                        });
                      },
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}
