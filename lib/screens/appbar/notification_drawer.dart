import 'package:flutter/material.dart';

class NotificationDrawer extends StatelessWidget {
  const NotificationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.8,
      decoration: BoxDecoration(
        color: Color.fromRGBO(201, 201, 201, 1.000),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notification 1'),
            onTap: () {
              // Handle tap
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Notification 2'),
            onTap: () {
              // Handle tap
            },
          ),
        ],
      ),
    );
  }
}
