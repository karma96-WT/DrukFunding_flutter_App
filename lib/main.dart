import 'package:drukfunding/create_page.dart';
import 'package:flutter/material.dart';
import 'ProfilePage.dart';
import 'SearchPage.dart';
import 'FavouritePage.dart';
import 'package:drukfunding/model/Project.dart';

// Mock Data List
final List<Project> projects = [
  Project(
    title: 'Smart Eco-Garden Kit',
    creator: 'Green Renovations',
    imageUrl: 'assets/images/OIP.webp',
    category: 'Sustainable',
    raised: 7500,
    goal: 10000,
    creatorImageUrl: 'assets/images/OIP.webp',
  ),
  Project(
    title: 'Quest for Aethelgard',
    creator: 'Pixel Forge',
    imageUrl: 'assets/images/image2.webp',
    category: 'Gaming',
    raised: 28000,
    goal: 25000,
    creatorImageUrl: 'assets/images/OIP.webp',
  ),
  Project(
    title: 'EcoWear Apparel Line',
    creator: 'Conscious Threads',
    imageUrl: 'assets/images/image3.webp',
    category: 'Fashion',
    raised: 12000,
    goal: 15000,
    creatorImageUrl: 'assets/images/OIP.webp',
  ),
  Project(
    title: 'The Daily Loaf Bakery',
    creator: 'Artisan Breads Co.',
    imageUrl: 'assets/images/image4.webp',
    category: 'Food',
    raised: 4000,
    goal: 8000,
    creatorImageUrl: 'assets/images/OIP.webp',
  ),
];

// --- 2. Main Application Structure ---

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
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            child: ClipOval(
              child: Image.asset(
                'assets/images/OIP.webp', // Placeholder for user avatar
                fit: BoxFit.cover,
                width: 32,
                height: 32,
              ),
            ),
          ),
        ),
      ],
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

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return ProjectCard(project: projects[index]);
      },
    );
  }
}

// --- 3. Project Card Component ---

class ProjectCard extends StatelessWidget {
  final Project project;
  const ProjectCard({super.key, required this.project});

  // Helper to format currency
  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0)}';
  }

  // Helper to build the category tag (e.g., "Gaming")
  Widget _buildCategoryTag() {
    // Determine color based on category
    Color tagColor = Colors.orange;
    if (project.category == 'Gaming') {
      tagColor = Colors.deepOrange;
    } else if (project.category == 'Sustainable') {
      tagColor = Colors.blue[700]!;
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

  // Helper to build the progress indicator
  Widget _buildProgressBar() {
    // Ensure progress is not capped at 1.0 (for over-funded projects)
    double progressValue = project.progress.clamp(0.0, 1.0);
    // Determine color for the bar
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
                    project.imageUrl,
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
                  // Project Title (Overlayed on image)
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

                  // Progress Bar
                  _buildProgressBar(),
                  const SizedBox(height: 16),

                  // Category Tag
                  _buildCategoryTag(),
                  const SizedBox(height: 20),

                  // Back Project Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Action for Back Project
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
