import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Needed for FirestoreService
import 'package:flutter/material.dart';
import 'package:drukfunding/model/Project.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Project>> getFavoriteProjects() async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      return [];
    }

    // Step 1: Get list of saved project IDs
    DocumentSnapshot favoriteDoc = await _db.collection('Favorites').doc(userId).get();
    if (!favoriteDoc.exists) return [];

    final data = favoriteDoc.data() as Map<String, dynamic>?;
    final List<String> savedProjectIds =
        (data?['savedProjectIds'] as List<dynamic>?)
            ?.map((id) => id.toString())
            .toList() ?? [];
    if (savedProjectIds.isEmpty) return [];

    // Step 2: Retrieve the corresponding Projects
    final List<String> queryIds = savedProjectIds.take(10).toList();
    QuerySnapshot<Map<String, dynamic>> projectSnapshots = await _db
        .collection('Projects')
        .where(FieldPath.documentId, whereIn: queryIds)
        .get();

// Convert the documents to a list of Project objects
    return projectSnapshots.docs.map((doc) {
      // doc is now correctly typed as DocumentSnapshot<Map<String, dynamic>>
      return Project.fromFirestore(doc, null);
    }).toList();
  }
}

class FavoriteProjectCard extends StatefulWidget {
  final Project project;

  const FavoriteProjectCard({super.key, required this.project});

  @override
  State<FavoriteProjectCard> createState() => _FavoriteProjectCardState();
}

class _FavoriteProjectCardState extends State<FavoriteProjectCard> {
  @override
  Widget build(BuildContext context) {
    Color progressColor = widget.project.progress >= 1.0
        ? Colors.green.shade600
        : Colors.blue.shade600;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Tapped on ${widget.project.title}')));
        },
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: Image.network(
                widget.project.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: const Text('Image Failed to Load', style: TextStyle(color: Colors.grey)),
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
                          widget.project.title,
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
                    '${widget.project.category} · by ${widget.project.creator}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  LinearProgressIndicator(
                    value: widget.project.progress,
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
                        'Nu. ${widget.project.raised.toStringAsFixed(0)} raised',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        'Goal: Nu. ${widget.project.goal.toStringAsFixed(0)}',
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


// --- FAVORITE PAGE IMPLEMENTATION (Uses FutureBuilder) ---

class FavouritePage extends StatefulWidget {
  const FavouritePage({super.key});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  // Initialize the service and the Future
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<Project>> _favoriteProjectsFuture;

  @override
  void initState() {
    super.initState();
    // Start fetching data for the logged-in user
    _favoriteProjectsFuture = _firestoreService.getFavoriteProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Saved Projects',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.pink.shade400,
        elevation: 0,
      ),
      // Use FutureBuilder to handle the asynchronous data retrieval
      body: FutureBuilder<List<Project>>(
        future: _favoriteProjectsFuture,
        builder: (context, snapshot) {
          // A. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // B. Error State
          if (snapshot.hasError) {
            return Center(child: Text('Error loading favorites: ${snapshot.error}'));
          }

          // C. Data Available State
          final List<Project> favoriteProjects = snapshot.data ?? [];

          // D. Empty State (no favorites found or user not logged in)
          if (favoriteProjects.isEmpty) {
            return Center(
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
            );
          }

          // E. Success State: Display the list
          return ListView.builder(
            itemCount: favoriteProjects.length,
            itemBuilder: (context, index) {
              final project = favoriteProjects[index];
              return FavoriteProjectCard(project: project);
            },
          );
        },
      ),
    );
  }
}