import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  // --- CRUD FUNCTIONS ---

  // Function to change the project status to 'accepted' AND create a notification
  Future<void> _acceptProject(String projectId) async {
    // ... (unchanged) ...
    final projectRef = FirebaseFirestore.instance.collection('Projects').doc(projectId);
    final notificationCollection = FirebaseFirestore.instance.collection('Notifications');

    final projectDoc = await projectRef.get();
    if (!projectDoc.exists) {
      print('Error: Project $projectId not found.');
      return;
    }
    final projectData = projectDoc.data() as Map<String, dynamic>;
    final projectTitle = projectData['title'] ?? 'Your Project';
    final creatorUid = projectData['creatorId'] ?? projectData['userId'];

    if (creatorUid == null || creatorUid is! String) {
      print('Error: Creator UID is missing or invalid for project $projectId.');
      return;
    }

    await projectRef.update({
      'status': 'accepted',
      'acceptedAt': Timestamp.now(),
    });

    await notificationCollection.add({
      'userId': creatorUid,
      'type': 'project_accepted',
      'title': 'Project Approved! 🎉',
      'body': 'Your project "$projectTitle" has been reviewed and accepted. It is now live and accepting pledges!',
      'projectId': projectId,
      'timestamp': Timestamp.now(),
      'read': false,
    });
  }

  // Function to change the project status to 'declined'
  Future<void> _declineProject(String projectId) async {
    await FirebaseFirestore.instance.collection('Projects').doc(projectId).update({
      'status': 'declined',
      'declinedAt': Timestamp.now(),
    });
  }

  // Function to delete the project entirely
  Future<void> _deleteProject(BuildContext context, String projectId) async {
    // This is only called after confirmation.
    try {
      await FirebaseFirestore.instance.collection('Projects').doc(projectId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project successfully deleted.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting project: $e')),
      );
    }
  }

  // ⭐ NEW FUNCTION: Confirmation Dialog Implementation
  Future<void> _confirmDelete(BuildContext context, String projectId, String projectTitle) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to permanently delete the project "$projectTitle"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false), // Dismiss and return false
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true), // Confirm and return true
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('DELETE', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      // If the admin confirmed, proceed with deletion
      await _deleteProject(context, projectId);
    }
  }

  // --- WIDGET BUILDERS ---

  Widget _buildProjectCard({
    required BuildContext context,
    required String projectId,
    required Map<String, dynamic> data,
    required bool isPending,
  }) {
    final title = data['title'] ?? 'N/A';
    final creator = data['creator'] ?? 'Unknown Creator';
    final status = data['status'] ?? 'unknown';
    final goal = data['goal'] is num ? (data['goal'] as num).toStringAsFixed(0) : '0';
    final raised = data['raised'] is num ? (data['raised'] as num).toStringAsFixed(0) : '0';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          isPending ? Icons.pending : Icons.check_circle,
          color: isPending ? Colors.orange : Colors.green,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Creator: $creator | Status: ${status.toUpperCase()}'),
        trailing: isPending
            ? const Icon(Icons.keyboard_arrow_down)
            : IconButton(
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          // ⭐ UPDATED: Call confirmation function instead of direct deletion
          onPressed: () => _confirmDelete(context, projectId, title),
        ),

        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ⭐ ADMIN DATA VIEW
                Text('Goal: Nu. $goal | Raised: Nu. $raised', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Category: ${data['category'] ?? 'N/A'}'),
                Text('Submission Date: ${data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate().toString().split(' ')[0] : 'N/A'}'),
                Text('Description: ${data['description'] ?? 'No Description'}', style: const TextStyle(fontStyle: FontStyle.italic)),

                // --- ACTION BUTTONS ---
                if (isPending) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.thumb_down, color: Colors.red),
                        label: const Text('Decline'),
                        onPressed: () => _declineProject(projectId),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Accept', style: TextStyle(color: Colors.white)),
                        onPressed: () => _acceptProject(projectId),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MAIN BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    // ... (Main build method logic is unchanged, remains the same as before) ...
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch all projects ordered by creation date
        stream: FirebaseFirestore.instance.collection('Projects').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No projects found.'));
          }

          final allProjects = snapshot.data!.docs;

          // Separate projects into categories
          final pendingProjects = allProjects.where((doc) => doc['status'] == 'pending').toList();
          final acceptedProjects = allProjects.where((doc) => doc['status'] == 'accepted').toList();
          final declinedProjects = allProjects.where((doc) => doc['status'] == 'declined').toList();


          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- STATS & OVERVIEW ---
              Card(
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Platform Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const SizedBox(height: 10),
                      Text('Total Projects: ${allProjects.length}', style: const TextStyle(fontSize: 16)),
                      Text('Pending Review: ${pendingProjects.length}', style: const TextStyle(fontSize: 16, color: Colors.orange)),
                      Text('Live Projects (Accepted): ${acceptedProjects.length}', style: const TextStyle(fontSize: 16, color: Colors.green)),
                      Text('Declined Projects: ${declinedProjects.length}', style: const TextStyle(fontSize: 16, color: Colors.red)),
                    ],
                  ),
                ),
              ),

              const Divider(height: 30),

              // --- PENDING PROJECTS SECTION (WITH BUTTONS) ---
              const Text('Pending Projects (Requires Action)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
              const SizedBox(height: 10),

              if (pendingProjects.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No projects currently pending review. ✅'),
                )
              else
                ...pendingProjects.map((doc) => _buildProjectCard(
                  context: context,
                  projectId: doc.id,
                  data: doc.data() as Map<String, dynamic>,
                  isPending: true,
                )).toList(),

              const Divider(height: 30),

              // --- ACCEPTED PROJECTS SECTION (WITH DELETE BUTTON) ---
              const Text('Accepted Projects (Live)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 10),

              if (acceptedProjects.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No live projects yet.'),
                )
              else
                ...acceptedProjects.map((doc) => _buildProjectCard(
                  context: context,
                  projectId: doc.id,
                  data: doc.data() as Map<String, dynamic>,
                  isPending: false, // Accepted projects have delete button
                )).toList(),

              const Divider(height: 30),

              // --- DECLINED PROJECTS SECTION (READ-ONLY) ---
              const Text('Declined Projects', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 10),

              if (declinedProjects.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No projects have been declined.'),
                )
              else
                ...declinedProjects.map((doc) => _buildProjectCard(
                  context: context,
                  projectId: doc.id,
                  data: doc.data() as Map<String, dynamic>,
                  isPending: false, // No action buttons needed
                )).toList(),
              const Divider(height: 30),

              // ⭐ NEW SECTION: REGISTERED USERS

              const Text('Registered Users & Metrics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 10),

              // StreamBuilder to fetch all users
              StreamBuilder<QuerySnapshot>(
                // Assuming your user collection is named 'Users'
                stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Text('Loading users...'));
                  }
                  if (userSnapshot.hasError) {
                    return Center(child: Text('Error loading users: ${userSnapshot.error}'));
                  }
                  if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No registered users found.'));
                  }

                  final users = userSnapshot.data!.docs;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: users.map((userDoc) {
                      final userData = userDoc.data() as Map<String, dynamic>;
                      final userId = userDoc.id; // The document ID should be the UID
                      final userName = userData['name'] ?? userData['email'] ?? 'User ID: $userId';

                      return UserProjectStats(
                        userId: userId,
                        userName: userName,
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

// Place this outside the AdminPage class, perhaps at the bottom of the file

class UserProjectStats extends StatelessWidget {
  final String userId;
  final String userName;

  const UserProjectStats({super.key, required this.userId, required this.userName});

  // Function to fetch project stats for a single user
  Future<Map<String, dynamic>> _fetchUserStats() async {
    // 1. Fetch all projects created by this user
    final projectsSnapshot = await FirebaseFirestore.instance
        .collection('Projects')
        .where('userId', isEqualTo: userId)
        .get();

    final totalProjects = projectsSnapshot.docs.length;
    double totalFundsRaised = 0.0;
    int acceptedProjects = 0;
    int pendingProjects = 0;

    // 2. Aggregate data from user's projects
    for (var doc in projectsSnapshot.docs) {
      final data = doc.data();

      // Calculate total funds raised across all projects (if 'raised' field exists)
      final raised = data['raised'] as num? ?? 0.0;
      totalFundsRaised += raised.toDouble();

      // Count status
      final status = data['status'] as String? ?? 'unknown';
      if (status == 'accepted') {
        acceptedProjects++;
      } else if (status == 'pending') {
        pendingProjects++;
      }
    }

    return {
      'totalProjects': totalProjects,
      'totalFundsRaised': totalFundsRaised,
      'acceptedProjects': acceptedProjects,
      'pendingProjects': pendingProjects,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchUserStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            title: Text(userName),
            subtitle: const Text('Loading stats...'),
            trailing: const CircularProgressIndicator.adaptive(),
          );
        }

        if (snapshot.hasError) {
          return ListTile(
            title: Text(userName),
            subtitle: Text('Error: ${snapshot.error}'),
            trailing: const Icon(Icons.error, color: Colors.red),
          );
        }

        final stats = snapshot.data!;
        final raised = stats['totalFundsRaised'] as double;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          color: Colors.blue.shade50,
          child: ExpansionTile(
            leading: const Icon(Icons.person_pin, color: Colors.indigo),
            title: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Total Projects Created: ${stats['totalProjects']}'),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User ID (UID): $userId', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const Divider(),
                    Text('Total Funds Raised: Nu. ${raised.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.green)),
                    Text('Accepted Projects: ${stats['acceptedProjects']}', style: const TextStyle(fontSize: 16)),
                    Text('Pending Projects: ${stats['pendingProjects']}', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}