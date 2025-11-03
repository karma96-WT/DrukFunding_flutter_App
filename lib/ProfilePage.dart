import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- MOCK DATA STRUCTURES FOR PROFILE PAGE ---
import 'package:drukfunding/model/project.dart';


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
    title: 'Smart Eco-Garden Kit',
    creator: 'Alex Thompson',
    imageUrl: 'https://placehold.co/600x400/1B4D3E/FFFFFF?text=Eco+Garden',
    category: 'Sustainable',
    raised: 7500,
    goal: 10000,
    creatorImageUrl: mockUser['profileImageUrl'],
  ),
  Project(
    title: 'Minimalist Travel Backpack',
    creator: 'Alex Thompson',
    imageUrl: 'https://placehold.co/600x400/7F8C8D/FFFFFF?text=Backpack',
    category: 'Fashion',
    raised: 15000,
    goal: 12000, // Goal exceeded
    creatorImageUrl: mockUser['profileImageUrl'],
  ),
];

// Mock Backed Projects (Kept as requested)
final List<Project> backedProjects = [
  Project(
    title: 'Quantum Computing Handbook',
    creator: 'Tech Gurus',
    imageUrl: 'https://placehold.co/600x400/F39C12/FFFFFF?text=Quantum',
    category: 'Technology',
    raised: 90000,
    goal: 100000,
    creatorImageUrl: 'https://placehold.co/50x50/e74c3c/FFFFFF?text=TG',
  ),
  Project(
    title: 'Local Farm-to-Table Cafe',
    creator: 'The Daily Loaf Bakery',
    imageUrl: 'https://placehold.co/600x400/D35400/FFFFFF?text=Bakery',
    category: 'Food',
    raised: 4000,
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

    return Card(
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
        },
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

  late TabController _tabController;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  Future<DocumentSnapshot<Map<String, dynamic>>>? _userProfileFuture;

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
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    if (userId == null || _userProfileFuture == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your profile.')),
      );
    }

    // Wrap the content in FutureBuilder to fetch and display data
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.blue,
      ),
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

          // --- Data Extraction ---
          final realUserData = snapshot.data!.data()!;
          // Use username from Firestore (or mock name as fallback if data is null)
          final realName = realUserData['username'] ?? mockUser['name'];
          // Use email from Firestore (or mock email as fallback if data is null)
          final realEmail = realUserData['email'] ?? mockUser['email'];
          final profileImage = realUserData['profileImageUrl'] ?? mockUser['profileImageUrl'];

          return Column(
            children: [
              // 1. User Header Section (Using REAL Name and Email)
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
                      realName, // 👈 DISPLAY REAL NAME/USERNAME
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      realEmail, // 👈 DISPLAY REAL EMAIL
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    // Stat Cards Row (Kept as requested, still using mock data)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          label: 'Created',
                          value: mockUser['totalProjectsCreated'].toString(),
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
                    // Tab 1: Created Projects (Still using mock data)
                    _buildProjectList(createdProjects, isBacked: false),

                    // Tab 2: Backed Projects (Still using mock data)
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