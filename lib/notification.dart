import 'package:flutter/material.dart';

class Notification {
  final String title;
  final String description;
  final IconData icon;
  Notification({
    required this.title,
    required this.description,
    required this.icon,
  });
}

List<Notification> notifications = [
  Notification(
    title: "New Project: Eco-friendly electric scooter",
    description: "I am making this scooter for urban transport using recycled materials.",
    icon: Icons.electric_scooter,
  ),
  Notification(
    title: "Campaign Update: Funding Goal Reached!",
    description: "The 'drukfunding' project successfully reached its funding goal of \$5000!",
    icon: Icons.check_circle_outline,
  ),
  Notification(
    title: "Message from Creator: Ugyen Dorji",
    description: "Thank you for your support! I've posted an update on the progress.",
    icon: Icons.mail_outline,
  ),
  Notification(
    title: "New Follower: Kinley Wangmo",
    description: "Kinley Wangmo just started following your 'Smart Farm' project.",
    icon: Icons.person_add_alt,
  ),
  Notification(
    title: "System Alert: Maintenance Scheduled",
    description: "Our services will undergo brief maintenance on Friday at 2:00 AM.",
    icon: Icons.settings,
  ),
];

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationState();
}

class _NotificationState extends State<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed:() {
            Navigator.pop(context,true);
          },
            icon: Icon(Icons.arrow_back),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,

        ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index){
            final notification = notifications[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                // Display the dynamic icon
                leading: Icon(
                  notification.icon,
                  color: Theme.of(context).primaryColor,
                ),
                // Display the notification title
                title: Text(
                  notification.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                // Display the notification description
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    notification.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis, // Prevents text overflow
                  ),
                ),
                // Optional: Handle the tap event for the notification
                onTap: () {
                  // You can add logic here to navigate to the related project/message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tapped on: ${notification.title}')),
                  );
                },
                contentPadding: const EdgeInsets.all(10.0),
              ),
            );
        }),
      );
  }
}
