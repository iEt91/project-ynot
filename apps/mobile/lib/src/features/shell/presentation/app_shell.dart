import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../activities/presentation/activities_screen.dart';
import '../../chat/presentation/chats_screen.dart';
import '../../map/presentation/map_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  final _pages = const [
    MapScreen(),
    ActivitiesScreen(),
    ChatsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          switch (_index) {
            0 => 'Mapa',
            1 => 'Actividades',
            2 => 'Chats',
            _ => 'Perfil',
          },
        ),
        actions: [
          if (_index == 0 || _index == 1)
            IconButton(
              onPressed: () => context.push('/create-activity'),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_list_outlined),
            selectedIcon: Icon(Icons.view_list_rounded),
            label: 'Actividades',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: _index == 1 || _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/create-activity'),
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
