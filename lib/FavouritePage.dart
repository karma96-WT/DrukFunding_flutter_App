import 'package:flutter/material.dart';
import 'package:drukfunding/model/Project.dart';

// --- MOCK PROJECT MODEL DEFINITION (Inferred from usage) ---
// This class simulates the 'package:drukfunding/model/project.dart' impor

// --- MOCK PROJECT DATA (Simulating liked projects) ---
final List<Project> projects = [
  Project(
    title: 'Smart Eco-Garden Kit',
    creator: 'Green Renovations',
    // Mock image paths are replaced with placeholders for runnable code
    imageUrl: 'https://placehold.co/600x400/00A388/ffffff?text=Eco-Garden',
    category: 'Sustainable',
    raised: 7500,
    goal: 10000,
    creatorImageUrl: 'https://placehold.co/50x50/00A388/ffffff?text=GR',
  ),
  Project(
    title: 'Quest for Aethelgard (Funded!)',
    creator: 'Pixel Forge',
    imageUrl: 'https://placehold.co/600x400/9933FF/ffffff?text=Aethelgard',
    category: 'Gaming',
    raised: 28000,
    goal: 25000, // Overfunded project
    creatorImageUrl: 'https://placehold.co/50x50/9933FF/ffffff?text=PF',
  ),
  Project(
    title: 'EcoWear Apparel Line',
    creator: 'Conscious Threads',
    imageUrl: 'https://placehold.co/600x400/FF6666/ffffff?text=EcoWear',
    category: 'Fashion',
    raised: 12000,
    goal: 15000,
    creatorImageUrl: 'https://placehold.co/50x50/FF6666/ffffff?text=CT',
  ),
  Project(
    title: 'The Daily Loaf Bakery',
    creator: 'Artisan Breads Co.',
    imageUrl: 'https://placehold.co/600x400/FFCC00/000000?text=Bakery',
    category: 'Food',
    raised: 4000,
    goal: 8000,
    creatorImageUrl: 'https://placehold.co/50x50/FFCC00/000000?text=AB',
  ),
];

// --- FAVORITE PROJECT CARD WIDGET ---

class FavoriteProjectCard extends StatelessWidget {
  final Project project;

  const FavoriteProjectCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    // Determine the color for the progress bar
    Color progressColor = project.progress >= 1.0
        ? Colors.green.shade600
        : Colors.blue.shade600;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          // Action when tapping the card (e.g., navigate to project details)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Tapped on ${project.title}')));
        },
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Image (simulating NetworkImage since local assets are unavailable)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: Image.network(
                project.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                // Fallback widget in case image fails to load
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: const Text(
                    'Image Failed to Load',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),

            // Project Details Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Heart Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          project.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Simulate the "Unfavorite" button
                      Icon(
                        Icons.favorite,
                        color: Colors.pink.shade400,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Category and Creator
                  Text(
                    '${project.category} · by ${project.creator}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  LinearProgressIndicator(
                    value: project.progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),

                  // Funding Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nu. ${project.raised.toStringAsFixed(0)} raised',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        'Goal: Nu. ${project.goal.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
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

// --- FAVORITE PAGE IMPLEMENTATION ---

class FavouritePage extends StatefulWidget {
  const FavouritePage({super.key});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  // Use the mock 'projects' list for now, which simulates the user's favorites
  final List<Project> _favoriteProjects = projects;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Liked Projects (${_favoriteProjects.length})',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.pink.shade400,
        elevation: 0,
      ),
      body: _favoriteProjects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'You haven\'t liked any projects yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const Text(
                    'Start exploring and find your next favorite!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _favoriteProjects.length,
              itemBuilder: (context, index) {
                final project = _favoriteProjects[index];
                return FavoriteProjectCard(project: project);
              },
            ),
    );
  }
}
