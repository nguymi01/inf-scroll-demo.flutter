import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

class InfiniteScrollWidget extends StatefulWidget {
  const InfiniteScrollWidget({super.key});

  @override
  State<InfiniteScrollWidget> createState() => _InfiniteScrollWidgetState();
}

class _InfiniteScrollWidgetState extends State<InfiniteScrollWidget> {
  final ScrollController _scrollController = ScrollController();
  final BehaviorSubject<List<String>> _dataStreamController =
      BehaviorSubject<List<String>>.seeded([]);
  final List<String> _data = [];
  List<String> _filteredData = [];
  int _dataCount = 0;
  final int _pageSize = 15;
  bool _isLoading = false;
  int _firstVisibleIndex = 0;
  TextEditingController _searchController = TextEditingController();
  bool isSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadData();
    _searchController.addListener(_searchListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dataStreamController.close();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Bottom of list reached, load more data
      if (!_isLoading) {
        setState(() {
          _firstVisibleIndex = (_scrollController.offset / 50)
              .floor(); // Assuming each item's height is 50
        });
        _data.removeRange(0, _firstVisibleIndex);
        _loadData();
      }
    }
  }

  // Handle search event, filtered out the data that match the search field
  void _searchListener() {
    String query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredData =
          List.from(_data); // If search query is empty, show all data
    } else {
      _filteredData =
          _data.where((item) => item.toLowerCase().contains(query)).toList();
    }
    _dataStreamController.add(_filteredData);
  }

  Future<void> _loadData() async {
    _isLoading = true;
    // Loading 3 data sources
    final jsonStr = await rootBundle.loadString('assets/MOCK_DATA.json');
    final jsonStr2 = await rootBundle.loadString('assets/MOCK_DATA2.json');
    final jsonStr3 = await rootBundle.loadString('assets/MOCK_DATA3.json');

    final jsonData = jsonDecode(jsonStr) as List<dynamic>;
    final jsonData2 = jsonDecode(jsonStr2) as List<dynamic>;
    final jsonData3 = jsonDecode(jsonStr3) as List<dynamic>;

    // Adding the data to array then shuffle them
    List<String> nameData = [];
    for (dynamic d in jsonData) {
      nameData.add(d['first_name'] + ' ' + d['last_name']);
    }
    for (dynamic d in jsonData2) {
      nameData.add(d['model'] + ' ' + d['company']);
    }
    for (dynamic d in jsonData3) {
      nameData.add(d['name']);
    }
    nameData.shuffle();
    
    // Load the next page of data
    final newData =
        nameData.sublist(_dataCount, _dataCount + _pageSize).cast<String>();
    newData.sort((a, b) {
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    _isLoading = false;
    Future.delayed(const Duration(seconds: 1), () {
      _data.addAll(newData);
      _dataCount++; // Increment counter for pagination
      _dataStreamController.add(_data);
      _filteredData.addAll(newData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite Scroll with JSON Data'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: isSearch
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        isSearch=!isSearch;
                      });
                      _searchController.clear();
                      _searchListener();
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        isSearch=!isSearch;
                      });

                    },
                  ),
          ),
        ],
        bottom: isSearch? PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search...',
              ),
            ),
          ),
        ):null,
      ),
      body: StreamBuilder<List<String>>(
        stream: _dataStreamController.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: snapshot.data!.length + 1, // +1 for progress indicator
            itemBuilder: (context, index) {
              if (index < snapshot.data!.length) {
                return ListTile(
                  title: Text(snapshot.data![index]),
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(), // Show loading indicator
                );
              }
            },
          );
        },
      ),
    );
  }
}
