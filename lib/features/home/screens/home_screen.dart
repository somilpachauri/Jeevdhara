import 'package:flutter/material.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/feed_grid.dart';

class HomeScreen extends StatefulWidget {
  final double? userLat;
  final double? userLng;
  
  const HomeScreen({super.key, this.userLat, this.userLng});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = "";
  String _sortOption = "date_desc";

  void _updateSearch(String query) => setState(() => _searchQuery = query);
  void _updateSort(String sort) => setState(() => _sortOption = sort);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: HomeAppBar(
          onSearchChanged: _updateSearch,
          onSortChanged: _updateSort,
        ),
        body: TabBarView(
          children: [
            FeedGrid(
              collectionPath: 'plantation_requests',
              icon: Icons.park,
              searchQuery: _searchQuery,
              sortOption: _sortOption,
              userLat: widget.userLat,
              userLng: widget.userLng,
            ),
            FeedGrid(
              collectionPath: 'land_offers',
              icon: Icons.landscape,
              searchQuery: _searchQuery,
              sortOption: _sortOption,
              userLat: widget.userLat,
              userLng: widget.userLng,
            ),
          ],
        ),
      ),
    );
  }
}