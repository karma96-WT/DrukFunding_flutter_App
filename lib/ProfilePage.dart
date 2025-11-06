import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:drukfunding/model/project.dart';

import 'ProjectDetailPage.dart';


// Mock User Profile Data (Kept for stat cards and fallback)
final Map<String, dynamic> mockUser = {
  'name': 'Alex Thompson',
  'email': 'alex.t@example.com',
  'profileImageUrl': 'https://placehold.co/100x100/3498db/FFFFFF?text=AT',
  'totalProjectsCreated': 2,
  'totalProjectsBacked': 5,
};

// Mock Created Projects (Kept as requested)
final List<Project> createdProjects = [
  Project(
    projectId: 'wewfer',
    title: 'Smart Eco-Garden Kit',
    creator: 'Alex Thompson',
    imageUrl: 'https://placehold.co/600x400/1B4D3E/FFFFFF?text=Eco+Garden',
    category: 'Sustainable',
    raised: 7500,
    likes: 9,
    goal: 10000,
    creatorImageUrl: mockUser['profileImageUrl'],
  ),
  Project(
    projectId: 'wewferrr',
    title: 'Minimalist Travel Backpack',
    creator: 'Alex Thompson',
    imageUrl: 'https://placehold.co/600x400/7F8C8D/FFFFFF?text=Backpack',
    category: 'Fashion',
    raised: 15000,
    likes: 8,
    goal: 12000, // Goal exceeded
    creatorImageUrl: mockUser['profileImageUrl'],
  ),
];

// Mock Backed Projects (Kept as requested)
final List<Project> backedProjects = [
  Project(
    projectId: 'wewfeeer',
    title: 'Quantum Computing Handbook',
    creator: 'Tech Gurus',
    imageUrl: 'https://placehold.co/600x400/F39C12/FFFFFF?text=Quantum',
    category: 'Technology',
    raised: 90000,
    likes: 7,
    goal: 100000,
    creatorImageUrl: 'https://placehold.co/50x50/e74c3c/FFFFFF?text=TG',
  ),
  Project(
    projectId: 'wewferddddd',
    title: 'Local Farm-to-Table Cafe',
    creator: 'The Daily Loaf Bakery',
    imageUrl: 'https://placehold.co/600x400/D35400/FFFFFF?text=Bakery',
    category: 'Food',
    raised: 4000,
    likes: 78,
    goal: 8000,
    creatorImageUrl: 'https://placehold.co/50x50/f1c40f/FFFFFF?text=AB',
  ),
  // Add more backed projects here...
];

// --- REUSABLE PROJECT CARD WIDGET (Simplified for list display) ---
// NOTE: Removed extraneous initState/Future properties from StatelessWidget
class ProjectCard extends StatelessWidget {
  final Project project;
  final bool isBacked;

  ProjectCard({super.key, required this.project, this.isBacked = false});


  @override
  Widget build(BuildContext context) {
    // Determine the color based on funding status
    final statusColor = project.progress >= 1.0 ? Colors.green : Colors.orange;
    final statusText = project.progress >= 1.0
        ? 'Goal Met!'
        : '${(project.progress * 100).toStringAsFixed(0)}% Funded';

    return InkWell(
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(projectId: project.projectId),
          ),
        );
      },
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
        onTap: () {
          // Placeholder for navigation to project details page
          print('Tapped on ${project.title}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(projectId: project.projectId),
            ),
          );
        },
      ),
        )
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

  late TabController _tabController;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  Future<DocumentSnapshot<Map<String, dynamic>>>? _userProfileFuture;

  // 1. NEW: Future to hold the created projects data fetched from Firebase
  Future<List<Project>>? _createdProjectsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize the Future call to fetch profile data
    if (userId != null) {
      _userProfileFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      // 2. NEW: Initialize the Future call for created projects
      _createdProjectsFuture = _getCreatedProjects();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 3. NEW: Function to fetch projects created by the current user
  Future<List<Project>> _getCreatedProjects() async {
    if (userId == null) {
      return [];
    }

    try {
      // Query the 'Projects' collection where 'creatorId' field matches the current userId
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('Projects')
          .where('userId', isEqualTo: userId)
          .get();

      // Map the document snapshots to a list of Project objects
      return snapshot.docs.map((doc) {
        // ASSUMPTION: Project.fromFirestore is implemented in your Project model
        return Project.fromFirestore(doc, null);
      }).toList();

    } catch (e) {
      print("Error fetching created projects: $e");
      // Return an empty list on error
      return [];
    }
  }

  // Widget to display user statistics in a card format (kept as requested)
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

  // 4. NEW: Widget to handle the Future for the "My Creations" tab content
  Widget _buildCreatedProjectsTab() {
    // If user is not logged in or Future wasn't initialized
    if (_createdProjectsFuture == null) {
      // This case is covered by the check in the main build method, but acts as a fallback
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

        // Use the fetched list if available, otherwise an empty list
        final List<Project> userCreations = snapshot.data ?? [];

        final int newCount = userCreations.length;
        if (newCount != _createdCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _createdCount = newCount;
            });
          });
        }

        // Call the general list builder with the fetched data
        return _buildProjectList(userCreations, isBacked: false);
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
                    // Stat Cards Row (Still using mock data)
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
                          value: mockUser['totalProjectsBacked'].toString(),
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
                    // Tab 1: Created Projects (NOW DYNAMIC)
                    _buildCreatedProjectsTab(),

                    // Tab 2: Backed Projects (STILL USING MOCK DATA)
                    _buildProjectList(backedProjects, isBacked: true),
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
  Widget _buildProjectList(List<Project> projects, {required bool isBacked}) {
    if (projects.isEmpty) {
      return Center(
        child: InkWell(
          onTap: (){

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

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return ProjectCard(project: projects[index], isBacked: isBacked);
      },
    );
  }
}