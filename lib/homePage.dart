import 'package:drukfunding/create_page.dart';
import 'package:drukfunding/notification.dart';
import 'package:flutter/material.dart';
import 'ProfilePage.dart';
import 'ProjectDetailPage.dart';
import 'SearchPage.dart';
import 'FavouritePage.dart';
import 'package:drukfunding/model/Project.dart';
import 'loginPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


void main() {
  runApp(const CrowdfundingApp());
}

class CrowdfundingApp extends StatelessWidget {
  const CrowdfundingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crowdfunding UI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(
          0xFFF5F5F5,
        ), // Light gray background
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  void _handleMenuSelection(String value) {
    if (value == 'logout') {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          // DetailPage is the widget (the "new page") we want to show
          builder: (context) => const LoginPage(),
        ),
      );
      // or navigate to login page
    } else if (value == 'profile') {
      // navigate to profile page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile clicked')),
      );
    }
  }
  // list of pages
  final List<Widget> _pages = [
    const HomeContent(),
    const SearchPage(),
    const CreatePage(),
    const FavouritePage(),
    const ProfilePage(),
  ];

  // Builds the custom AppBar to match the image
  AppBar _buildAppBar() {
    return AppBar(
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 47, 117, 223),
        title: const Text(
          'DrukFunding',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        centerTitle: true,
        leadingWidth: 40,
        // User Profile and Notification Icons
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.black87,
            ),
            onPressed: () {
              // navigate to notification page
              Navigator.push(
                context,
                MaterialPageRoute(
                  // DetailPage is the widget (the "new page") we want to show
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle), // Profile icon
              onSelected: _handleMenuSelection,
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Logout'),
                    ],
                  ),
                ),
              ]
          ),
        ]
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: const <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(leading: Icon(Icons.person), title: Text('Profile Setting')),
          ListTile(leading: Icon(Icons.help), title: Text('Help')),
          ListTile(leading: Icon(Icons.question_answer), title: Text('FAQ')),
          ListTile(leading: Icon(Icons.star), title: Text('Rating')),
        ],
      ),
    );
  }

  // Builds the Bottom Navigation Bar
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue[600],
      unselectedItemColor: Colors.grey[400],
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      showSelectedLabels: true,
      showUnselectedLabels: false, // Matches the look in the image
      elevation: 4.0,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Create'),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          label: 'Favourite',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  Widget build(BuildContext context) {
    // Listen to Firestore "Projects" collection
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Projects')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading projects'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No projects available yet.\nCreate one to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          );
        }


        // Convert Firestore documents into Project objects
        final List<Project> projects = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final Timestamp? timestamp = data['createdAt'] as Timestamp?;
          return Project(
            projectId: doc.id,
            title: data['title'] ?? 'Untitled Project',
            creator: data['creator'] ?? 'Unknown Creator',
            imageUrl: 'assets/images/OIP.webp',
            category: data['category'] ?? 'Other',
            raised: (data['raised'] ?? 0).toDouble(),
            goal: (data['goal'] ?? 0).toDouble(),
            creatorImageUrl: data['creatorImageUrl'] ?? 'https://placehold.co/50x50',
            createdAt: timestamp?.toDate(), // convert Timestamp to DateTime
          );
        }).toList();


        // Display list of project cards
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            return ProjectCard(project: projects[index]);
          },
        );
      },
    );
  }
}


// --- 3. Project Card Component ---

class ProjectCard extends StatefulWidget {
  final Project project;
  const ProjectCard({super.key, required this.project});

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool isLiked = false;
  // Helper to format currency
  String _formatCurrency(double amount) {
    return 'Nu. ${amount.toStringAsFixed(0)}';
  }

  // Helper to build the category tag (e.g., "Gaming")
  Widget _buildCategoryTag() {
    // Determine color based on category
    Color tagColor = Colors.orange;
    if (widget.project.category == 'Gaming') {
      tagColor = Colors.deepOrange;
    } else if (widget.project.category == 'Sustainable') {
      tagColor = Colors.blue[700]!;
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

  Widget _buildLikeTag() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isLiked = !isLiked; // Toggle state
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedScale(
          scale: isLiked ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : Colors.grey,
            size: 22,
          ),
        )
      ),

    );
  }


  // Helper to build the progress indicator
  Widget _buildProgressBar() {
    // Ensure progress is not capped at 1.0 (for over-funded projects)
    double progressValue = widget.project.progress.clamp(0.0, 1.0);
    // Determine color for the bar
    Color barColor = widget.project.progress >= 1.0 ? Colors.green : Colors.orange;

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
            // --- Image Section with Overlay ---
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  // Project Image
                  Image.asset(
                    widget.project.imageUrl,
                    fit: BoxFit.cover,
                    height: 200,
                    width: double.infinity,
                  ),
                  // Gradient Overlay for readability (optional, but good practice)
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
                  // Creator Info (Overlayed on image)
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
                  // Project Title (Overlayed on image)
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

            // --- Content Section (Below Image) ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Raised & Goal Amounts
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

                  // Progress Bar
                  _buildProgressBar(),
                  const SizedBox(height: 16),

                  // Category Tag and Like
                  Row(
                    children: [
                      _buildCategoryTag(),
                      const Spacer(),
                      _buildLikeTag(),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Back Project Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(projectId: widget.project.projectId),
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