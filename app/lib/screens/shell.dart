import 'package:flutter/material.dart';

import 'feed_screen.dart';
import 'profile_screen.dart';
import 'social_screen.dart';
import 'today_screen.dart';
import 'trackers_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          TodayScreen(),
          TrackersScreen(),
          FeedScreen(),
          SocialScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), label: 'Trackers'),
          NavigationDestination(icon: Icon(Icons.dynamic_feed_outlined), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Friends'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'You'),
        ],
      ),
    );
  }
}
