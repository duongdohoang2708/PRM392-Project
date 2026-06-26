import 'package:flutter/material.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () => Navigator.pushNamed(context, '/notifications'),
    );
  }
}
