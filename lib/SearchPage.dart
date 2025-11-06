import 'package:drukfunding/ProjectDetailPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drukfunding/model/Project.dart';

class ProjectCard extends StatefulWidget {
  final Project project;
  const ProjectCard({super.key, required this.project});

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  String _formatCurrency(double amount) {
    return 'Nu. ${amount.toStringAsFixed(0)}';
  }

  Widget _buildCategoryTag() {
    Color tagColor = Colors.orange;
    if (widget.project.category == 'Gaming') {
      tagColor = Colors.deepOrange;
    } else if (widget.project.category == 'Sustainable') {
      tagColor = Colors.blue[700]!;
    } else if (widget.project.category == 'Fashion') {
      tagColor = Colors.teal;
    } else if (widget.project.category == 'Food') {
      tagColor = Colors.brown;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        widget.project.category,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    // Uses the computed progress getter from the Project model
    double progressValue = widget.project.progress;
    Color barColor = progressValue >= 1.0 ? Colors.green : Colors.orange;

    return LinearProgressIndicator(
      value: progressValue,
      backgroundColor: Colors.grey[300],
      color: barColor,
      minHeight: 8,
      borderRadius: BorderRadius.circular(4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image and Creator Stack ---
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  Image.network(
                    widget.project.imageUrl,
                    fit: BoxFit.cover,
                    height: 200,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Text(
                            'Image Failed to Load',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: NetworkImage(
                            widget.project.creatorImageUrl,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.project.creator,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 12,
                    child: Text(
                      widget.project.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // --- Stats, Progress, and Button ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatCurrency(widget.project.raised),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.blue[800],
                            ),
                          ),
                          const Text(
                            'Raised',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatCurrency(widget.project.goal),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          const Text(
                            'Goal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildProgressBar(),
                  const SizedBox(height: 16),
                  _buildCategoryTag(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        String currentProjectId = widget.project.projectId;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(projectId: currentProjectId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Back Project',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final CollectionReference projectsCollection =
  FirebaseFirestore.instance.collection('Projects');

  List<Project> _allLiveProjects = [];
  List<Project> _filteredProjects = [];

  @override
  void initState() {
    super.initState();
    _filteredProjects = [];
    // Listen to the text controller to trigger filtering on every change
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Calls filterProjects whenever text changes
    _filterProjects(_searchController.text);
    // Forces a widget rebuild to correctly show/hide the clear button in the AppBar
    setState(() {});
  }

  void _filterProjects(String query) {
    final lowerCaseQuery = query.toLowerCase();
    final List<Project> newFilteredList;

    if (lowerCaseQuery.isEmpty) {
      // If the query is empty, show all live projects
      newFilteredList = _allLiveProjects;
    } else {
      // Filter the in-memory list
      newFilteredList = _allLiveProjects.where((project) {
        return project.title.toLowerCase().contains(lowerCaseQuery) ||
            project.creator.toLowerCase().contains(lowerCaseQuery) ||
            project.category.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }

    // Only update state if the visible list has actually changed
    if (_filteredProjects.length != newFilteredList.length ||
        !_listEquals(_filteredProjects, newFilteredList)) {
      setState(() {
        _filteredProjects = newFilteredList;
      });
    }
  }

  // Helper to compare two lists of Projects by ID (basic check)
  bool _listEquals(List<Project> a, List<Project> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].projectId != b[i].projectId) return false;
    }
    return true;
  }

  // Function to clear the search field and reset results
  void _clearSearch() {
    // Clearing the controller triggers the listener, which handles the reset
    _searchController.clear();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 4.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search projects, creators, or categories...',
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: _clearSearch,
                )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
              ),
            ),
          ),
        ),
        titleSpacing: 0,
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Use StreamBuilder to handle asynchronous Firebase data
      body: StreamBuilder<QuerySnapshot<Project>>(
        stream: projectsCollection
            .withConverter<Project>(
          fromFirestore: (snapshot, _) => Project.fromFirestore(snapshot),
          toFirestore: (project, _) => {},
        )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Project> fetchedProjects =
              snapshot.data?.docs.map((doc) => doc.data()).toList() ?? [];

          // Core Logic: Update source list and re-filter
          if (_allLiveProjects.length != fetchedProjects.length ||
              !_listEquals(_allLiveProjects, fetchedProjects)) {

            _allLiveProjects = fetchedProjects;

            // Re-run the filter on the new data after the frame is built
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _filterProjects(_searchController.text);
            });
          }

          return _buildSearchBody(context);
        },
      ),
    );
  }

  Widget _buildSearchBody(BuildContext context) {
    // Case 1: Search performed but no results found
    if (_searchController.text.isNotEmpty && _filteredProjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sentiment_dissatisfied,
                size: 60,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No results found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Try searching for a different keyword or category.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
    // Case 2: No data fetched yet AND no projects available
    else if (_filteredProjects.isEmpty && _searchController.text.isEmpty && _allLiveProjects.isEmpty) {
      return const Center(child: Text('No projects available yet!'));
    }

    // Case 3: Display results (either filtered or all projects)
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredProjects.length,
      itemBuilder: (context, index) {
        return ProjectCard(project: _filteredProjects[index]);
      },
    );
  }
}