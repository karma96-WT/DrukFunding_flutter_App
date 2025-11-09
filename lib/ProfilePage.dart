import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:drukfunding/model/project.dart';

import 'ProjectDetailPage.dart';
import 'backing_details.dart';
import 'creators_analytics.dart';


// Mock User Profile Data (Kept for stat cards and fallback)
final Map<String, dynamic> mockUser = {
  'name': 'Alex Thompson',
  'email': 'alex.t@example.com',
  'profileImageUrl': 'https://placehold.co/100x100/3498db/FFFFFF?text=AT',
  'totalProjectsCreated': 2,
  'totalProjectsBacked': 5,
};

// --- REUSABLE PROJECT CARD WIDGET (FIXED onTap structure) ---
class ProjectCard extends StatelessWidget {
  final Project project;
  final bool isBacked;
  final VoidCallback onTap;

  ProjectCard({super.key, required this.project, this.isBacked = false, required this.onTap});


  @override
  Widget build(BuildContext context) {
    // Determine the color based on funding status
    final statusColor = project.progress >= 1.0 ? Colors.green : Colors.orange;
    final statusText = project.progress >= 1.0
        ? 'Goal Met!'
        : '${(project.progress * 100).toStringAsFixed(0)}% Funded';

    return InkWell(
      onTap: onTap, // ⭐ THE CRITICAL FIX: Directly use the onTap callback passed from the parent widget
      child: Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Icon(
              isBacked ? Icons.favorite_border : Icons.star_border,
              color: Colors.blue,
            ),
          ),
          title: Text(
            project.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Goal: Nu. ${project.goal.toStringAsFixed(0)}'),
              Text(
                'Status: $statusText',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: isBacked
              ? Text(
            'Backed!',
            style: TextStyle(
              color: Colors.pink.shade700,
              fontWeight: FontWeight.bold,
            ),
          )
              : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ),
      ),
    );
  }
}

// --- PROFILE PAGE IMPLEMENTATION ---

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {

  int _createdCount = 0;
  int _backedCount = 0; // NEW: For backed project count

  late TabController _tabController;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  Future<DocumentSnapshot<Map<String, dynamic>>>? _userProfileFuture;

  Future<List<Project>>? _createdProjectsFuture;
  // ⭐ NEW: Future to hold the backed projects data fetched from Firebase
  Future<List<Project>>? _backedProjectsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (userId != null) {
      _userProfileFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      _createdProjectsFuture = _getCreatedProjects();
      // ⭐ NEW: Initialize the Future call for backed projects
      _backedProjectsFuture = _getBackedProjects();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Function to fetch projects created by the current user (unchanged)
  Future<List<Project>> _getCreatedProjects() async {
    if (userId == null) {
      return [];
    }

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('Projects')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) {
        // ASSUMPTION: Project.fromFirestore is implemented in your Project model
        return Project.fromFirestore(doc, null);
      }).toList();

    } catch (e) {
      print("Error fetching created projects: $e");
      return [];
    }
  }

  // ⭐ NEW: Function to fetch projects backed by the current user
  Future<List<Project>> _getBackedProjects() async {
    if (userId == null) {
      return [];
    }

    try {
      // 1. Fetch Pledges made by this user
      final pledgesSnapshot = await FirebaseFirestore.instance
          .collection('Pledges')
          .where('userId', isEqualTo: userId)
          .get();

      if (pledgesSnapshot.docs.isEmpty) {
        return []; // No pledges found
      }

      // 2. Extract unique Project IDs from the pledges
      final Set<String> projectIds = pledgesSnapshot.docs
          .map((doc) => doc.data()['projectId'] as String)
          .toSet();

      // Firestore limits 'in' queries to 10 IDs, so we use a batch fetch if necessary.
      // For simplicity, we'll assume the projectIds list is small enough.

      final List<Project> backedProjects = [];

      // 3. Fetch the actual Project documents using the Project IDs
      for (final id in projectIds) {
        final projectDoc = await FirebaseFirestore.instance
            .collection('Projects')
            .doc(id)
            .get();

        if (projectDoc.exists) {
          // Map the document to the Project model
          backedProjects.add(Project.fromFirestore(projectDoc, null));
        }
      }

      return backedProjects;

    } catch (e) {
      print("Error fetching backed projects: $e");
      return [];
    }
  }


  // Widget to display user statistics in a card format (unchanged)
  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, color: Colors.blue, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget to handle the Future for the "My Creations" tab content (updated count logic)
  Widget _buildCreatedProjectsTab() {
    if (_createdProjectsFuture == null) {
      return const Center(child: Text('User not authenticated.'));
    }

    return FutureBuilder<List<Project>>(
      future: _createdProjectsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading creations: ${snapshot.error}'));
        }

        final List<Project> userCreations = snapshot.data ?? [];

        // Update the count for the header asynchronously
        final int newCount = userCreations.length;
        if (newCount != _createdCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _createdCount = newCount;
            });
          });
        }

        return _buildProjectList(userCreations, isBacked: false);
      },
    );
  }

  // ⭐ NEW: Widget to handle the Future for the "Backed Projects" tab content
  Widget _buildBackedProjectsTab() {
    if (_backedProjectsFuture == null) {
      return const Center(child: Text('User not authenticated.'));
    }

    return FutureBuilder<List<Project>>(
      future: _backedProjectsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading backed projects: ${snapshot.error}'));
        }

        final List<Project> userBacked = snapshot.data ?? [];

        // Update the count for the header asynchronously
        final int newCount = userBacked.length;
        if (newCount != _backedCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _backedCount = newCount;
            });
          });
        }

        return _buildProjectList(userBacked, isBacked: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null || _userProfileFuture == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your profile.')),
      );
    }

    // Main FutureBuilder for Profile Header Data
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          // ... (Error handling and loading states remain the same) ...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Profile data not found.'));
          }

          // --- Data Extraction for Header ---
          final realUserData = snapshot.data!.data()!;
          final realName = realUserData['username'] ?? mockUser['name'];
          final realEmail = realUserData['email'] ?? mockUser['email'];
          final profileImage = realUserData['profileImageUrl'] ?? mockUser['profileImageUrl'];

          return Column(
            children: [
              // 1. User Header Section (Profile Image, Name, Email, Stat Cards)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(profileImage),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      realName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      realEmail,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    // Stat Cards Row (Now uses real count for created, and new count for backed)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          label: 'Created',
                          value: _createdCount.toString(),
                          icon: Icons.lightbulb_outline,
                        ),
                        _buildStatCard(
                          label: 'Backed',
                          value: _backedCount.toString(), // ⭐ UPDATED TO USE REAL COUNT
                          icon: Icons.wallet_giftcard,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Tab Bar for Projects
              TabBar(
                controller: _tabController,
                labelColor: Colors.blue[700],
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue[700],
                tabs: const [
                  Tab(text: 'My Creations'),
                  Tab(text: 'Backed Projects'),
                ],
              ),

              // 3. Tab Content (Expandable ListView)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Created Projects (Dynamic)
                    _buildCreatedProjectsTab(),

                    // Tab 2: Backed Projects (NOW DYNAMIC)
                    _buildBackedProjectsTab(), // ⭐ USING NEW DYNAMIC WIDGET
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper widget to build the ListView for the tab content (kept same)
  // Helper widget to build the ListView for the tab content (UPDATED navigation)
  // ... inside _ProfilePageState
  // Helper widget to build the ListView for the tab content (Complete and Robust)
  Widget _buildProjectList(List<Project> projects, {required bool isBacked}) {
    // 1. **CRITICAL CHECK: Handle the empty state immediately.**
    if (projects.isEmpty) {
      return Center(
          child: InkWell(
            onTap: (){
              // Optional: action for tapping the empty state message
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isBacked
                      ? Icons.monetization_on_outlined
                      : Icons.palette_outlined,
                  size: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 10),
                Text(
                  isBacked
                      ? 'No projects backed yet.'
                      : 'Time to launch your first project!',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          )
      );
    }

    // 2. Build the list only if projects is NOT empty
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: projects.length, // List length is guaranteed > 0 here
      itemBuilder: (context, index) {
        // Ensure index access is safe (it is, since itemCount == projects.length)
        final project = projects[index];

        void navigationCallback() {
          if (!isBacked) {
            // My Creations Tab: Go to Creator Analytics Page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreatorAnalyticsPage(
                  projectId: project.projectId,
                  projectTitle: project.title,
                ),
              ),
            );
          } else {
            // Backed Projects Tab: Go to DEDICATED Pledge Details Page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BackedPledgeDetailsPage(
                  projectId: project.projectId,
                  projectTitle: project.title,
                ),
              ),
            );
          }
        }

        return ProjectCard(
          project: project,
          isBacked: isBacked,
          onTap: navigationCallback,
        );
      },
    );
  }
}