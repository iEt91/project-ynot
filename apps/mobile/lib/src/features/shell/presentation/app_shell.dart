import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activities/presentation/activities_screen.dart';
import '../../chat/presentation/chats_screen.dart';
import '../../map/presentation/map_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../../shared/widgets/kawaii_bottom_nav.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;
  late final PageController _pageController;

  final List<Widget> _pages = const [
    MapScreen(),
    ActivitiesScreen(),
    ChatsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (value) {
              if (_index == value) return;
              setState(() => _index = value);
            },
            children: _pages,
          ),
          Positioned.fill(
            child: _EdgeSwipeLayer(
              onSwipeLeft: () => _goToPage(_index + 1),
              onSwipeRight: () => _goToPage(_index - 1),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        left: false,
        right: false,
        child: KawaiiBottomNav(
          index: _index,
          onChanged: _goToPage,
        ),
      ),
    );
  }

  void _goToPage(int nextIndex) {
    if (nextIndex < 0 || nextIndex >= _pages.length || nextIndex == _index) {
      return;
    }

    setState(() => _index = nextIndex);
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }
}

class _EdgeSwipeLayer extends StatelessWidget {
  const _EdgeSwipeLayer({
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  static const double _edgeWidth = 40;
  static const double _distanceThreshold = 80;
  static const double _velocityThreshold = 300;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _edgeWidth,
            child: _EdgeDragZone(
              allowedDirection: _SwipeDirection.right,
              onSwipeAccepted: onSwipeRight,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: _edgeWidth,
            child: _EdgeDragZone(
              allowedDirection: _SwipeDirection.left,
              onSwipeAccepted: onSwipeLeft,
            ),
          ),
        ],
      ),
    );
  }
}

class _EdgeDragZone extends StatefulWidget {
  const _EdgeDragZone({
    required this.allowedDirection,
    required this.onSwipeAccepted,
  });

  final _SwipeDirection allowedDirection;
  final VoidCallback onSwipeAccepted;

  @override
  State<_EdgeDragZone> createState() => _EdgeDragZoneState();
}

class _EdgeDragZoneState extends State<_EdgeDragZone> {
  double _distanceX = 0;
  double _distanceY = 0;
  double _velocityX = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) {
        _distanceX = 0;
        _distanceY = 0;
        _velocityX = 0;
      },
      onHorizontalDragUpdate: (details) {
        _distanceX += details.delta.dx;
        _distanceY += details.delta.dy.abs();
      },
      onHorizontalDragEnd: (details) {
        _velocityX = details.primaryVelocity ?? 0;
        final clearHorizontalSwipe = _distanceX.abs() > _EdgeSwipeLayer._distanceThreshold &&
            _distanceX.abs() > _distanceY * 1.2 &&
            _velocityX.abs() > _EdgeSwipeLayer._velocityThreshold;

        final accepted = clearHorizontalSwipe &&
            ((widget.allowedDirection == _SwipeDirection.left && _distanceX < 0 && _velocityX < 0) ||
                (widget.allowedDirection == _SwipeDirection.right && _distanceX > 0 && _velocityX > 0));

        if (accepted) {
          widget.onSwipeAccepted();
        }
      },
    );
  }
}

enum _SwipeDirection { left, right }
