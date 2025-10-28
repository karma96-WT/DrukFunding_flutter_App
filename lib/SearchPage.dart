import 'package:flutter/material.dart';
import 'package:drukfunding/model/project.dart';

// --- MOCK DATA FOR SEARCH PAGE ---
final List<Project> allProjects = [
  Project(
    title: 'Smart Eco-Garden Kit',
    creator: 'Green Renovations',
    imageUrl: 'https://placehold.co/600x400/1B4D3E/FFFFFF?text=Eco+Garden',
    category: 'Sustainable',
    raised: 7500,
    goal: 10000,
    creatorImageUrl: 'https://placehold.co/50x50/3498db/FFFFFF?text=GR',
  ),
  Project(
    title: 'Quest for Aethelgard: The RPG',
    creator: 'Pixel Forge',
    imageUrl: 'https://placehold.co/600x400/8E44AD/FFFFFF?text=Fantasy+Game',
    category: 'Gaming',
    raised: 28000,
    goal: 25000,
    creatorImageUrl: 'https://placehold.co/50x50/e74c3c/FFFFFF?text=PF',
  ),
  Project(
    title: 'EcoWear Apparel Line',
    creator: 'Conscious Threads',
    imageUrl: 'https://placehold.co/600x400/2C3E50/FFFFFF?text=Eco+Wear',
    category: 'Fashion',
    raised: 12000,
    goal: 15000,
    creatorImageUrl: 'https://placehold.co/50x50/2ecc71/FFFFFF?text=CT',
  ),
  Project(
    title: 'The Daily Loaf Bakery',
    creator: 'Artisan Breads Co.',
    imageUrl: 'https://placehold.co/600x400/D35400/FFFFFF?text=Bakery',
    category: 'Food',
    raised: 4000,
    goal: 8000,
    creatorImageUrl: 'https://placehold.co/50x50/f1c40f/FFFFFF?text=AB',
  ),
];

// PROJECT CARD WIDGET
class ProjectCard extends StatelessWidget {
  final Project project;
  const ProjectCard({super.key, required this.project});

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0)}';
  }

  Widget _buildCategoryTag() {
    Color tagColor = Colors.orange;
    if (project.category == 'Gaming') {
      tagColor = Colors.deepOrange;
    } else if (project.category == 'Sustainable') {
      tagColor = Colors.blue[700]!;
    } else if (project.category == 'Fashion') {
      tagColor = Colors.teal;
    } else if (project.category == 'Food') {
      tagColor = Colors.brown;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        project.category,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    double progressValue = project.progress.clamp(0.0, 1.0);
    Color barColor = project.progress >= 1.0 ? Colors.green : Colors.orange;

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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  Image.network(
                    project.imageUrl,
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
                            project.creatorImageUrl,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          project.creator,
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
                      project.title,
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
                            _formatCurrency(project.raised),
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
                            _formatCurrency(project.goal),
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
                      onPressed: () {},
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

// --- FUNCTIONAL SEARCH PAGE ---

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Controller to manage the text field input
  final TextEditingController _searchController = TextEditingController();

  // List to hold the current filtered search results
  List<Project> _filteredProjects = allProjects;

  @override
  void initState() {
    super.initState();
    // Initialize the filtered list to show all projects when the page loads
    _filteredProjects = allProjects;
  }

  // Function to perform the search/filtering
  void _filterProjects(String query) {
    // Convert query to lower case for case-insensitive matching
    final lowerCaseQuery = query.toLowerCase();

    setState(() {
      if (lowerCaseQuery.isEmpty) {
        // If the query is empty, show all projects
        _filteredProjects = allProjects;
      } else {
        // Filter the list based on title or creator containing the query
        _filteredProjects = allProjects.where((project) {
          return project.title.toLowerCase().contains(lowerCaseQuery) ||
              project.creator.toLowerCase().contains(lowerCaseQuery) ||
              project.category.toLowerCase().contains(lowerCaseQuery);
        }).toList();
      }
    });
  }

  // Function to clear the search field and reset results
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _filteredProjects = allProjects;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Set the title widget to a functional search bar
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
          child: TextField(
            controller: _searchController,
            autofocus: true, // Focus on search bar immediately
            decoration: InputDecoration(
              hintText: 'Search projects, creators, or categories...',
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: Colors.blue),
              // Show a clear button only when text is present
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: _clearSearch,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
            ),
            // Call filter function whenever the text changes
            onChanged: _filterProjects,
          ),
        ),
        titleSpacing: 0,
        backgroundColor: Colors.blue,
      ),
      body: _buildSearchBody(),
    );
  }

  // Separate method to build the main body content
  Widget _buildSearchBody() {
    if (_searchController.text.isNotEmpty && _filteredProjects.isEmpty) {
      // Case 1: Search performed but no results found
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
    } else if (_searchController.text.isEmpty && _filteredProjects.isEmpty) {
      // Case 2: Should not happen with initial setup, but good for safety
      return const Center(child: Text('Start searching to find projects!'));
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
