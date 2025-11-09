import 'package:flutter/material.dart';

class AppNotification {
  final String title;
  final String description;
  final IconData icon;
  final bool read;
  final String projectID;
  final String notificationId;

  AppNotification({
    required this.title,
    required this.description,
    required this.icon,
    required this.read,
    required this.projectID,
    required this.notificationId,
  });
}