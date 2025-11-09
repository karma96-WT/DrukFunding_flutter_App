import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Assuming your AppNotification model is here and has a constructor from Firestore data
import 'package:drukfunding/model/notification.dart';

import 'ProjectDetailPage.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationState();
}

class _NotificationState extends State<NotificationPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // --- Helper to map Firestore data to the AppNotification model ---
  AppNotification _mapDocumentToNotification(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    IconData icon;
    // Determine the icon based on the notification type
    switch (data['type']) {
      case 'project_accepted':
        icon = Icons.check_circle_outline;
        break;
      case 'project_declined':
        icon = Icons.cancel_outlined;
        break;
      case 'new_pledge':
        icon = Icons.wallet_giftcard;
        break;
      case 'system_alert':
        icon = Icons.settings;
        break;
      default:
        icon = Icons.notifications_none;
    }

    // ⭐ Extract read status, defaulting to false if missing (safer default for notifications)
    final bool isRead = data['read'] ?? false;

    return AppNotification(
      title: data['title'] ?? 'Notification',
      description: data['body'] ?? 'No description provided.',
      icon: icon,
      read: isRead, // Include the read status
      projectID: data['projectId'],
      notificationId: doc.id,
    );
  }
  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: const Color.fromARGB(255, 47, 117, 223),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view your notifications.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed:() {
          Navigator.pop(context);
        },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Notifications'),
        backgroundColor: const Color.fromARGB(255, 47, 117, 223),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Notifications')
        // Filter by the current user's ID
            .where('userId', isEqualTo: currentUser!.uid)
        // Order by timestamp (requires composite index)
            .orderBy('timestamp', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // Display an informative message for the required index
            return const Center(child:
            Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Error loading notifications. Please ensure the Composite Index (userId, timestamp) is created in Firestore.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            )
            );
          }

          final notificationDocs = snapshot.data?.docs ?? [];

          if (notificationDocs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 60, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      'No new notifications.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<AppNotification> notifications =
          notificationDocs.map((doc) => _mapDocumentToNotification(doc)).toList();

          return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index){
                final notification = notifications[index];
                final isUnread = !notification.read; // Check the new 'read' field

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    // ⭐ Visual feedback for unread status
                    tileColor: isUnread ? Colors.blue.shade50 : null,

                    leading: Icon(
                      notification.icon,
                      color: isUnread ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                    title: Text(
                      notification.title,
                      // Use bold font weight if unread
                      style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        notification.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(projectId: notification.projectID!),                        ),
                      );
                    },
                    contentPadding: const EdgeInsets.all(10.0),
                  ),
                );
              }
          );
        },
      ),
    );
  }
}