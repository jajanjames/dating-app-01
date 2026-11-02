// FILE: lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/discovery/discovery_screen.dart';
import '../../features/matches/chats_screen.dart';
import '../../features/matches/likes_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../theme/app_theme.dart';

/// Named route paths for Naam (Onboarding + 4-Tab Navigation: Discover, Likes, Chats, You).
abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String discover = '/discover';
  static const String likes = '/likes';
  static const String chats = '/chats';
  static const String profile = '/you';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');
final _discoverNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'discoverNav');
final _likesNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'likesNav');
final _chatsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'chatsNav');
final _profileNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'profileNav');

/// Provides the configured [GoRouter] instance for the Naam application.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.onboarding,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _DockedBottomTabMainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _discoverNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.discover,
                builder: (context, state) => const DiscoveryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _likesNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.likes,
                builder: (context, state) => const LikesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _chatsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.chats,
                builder: (context, state) => const ChatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Docked 4-Tab Bottom Navigation Bar matching the Naam Figma mockup:
/// `Discover` (compass), `Likes` (heart), `Chats` (chat bubble), `You` (person).
class _DockedBottomTabMainScaffold extends ConsumerWidget {
  const _DockedBottomTabMainScaffold({
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onSelectTab(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadChats = ref.watch(unreadChatsCountProvider);

    return Scaffold(
      extendBody: false,
      backgroundColor: Colors.white,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFEFEFF4), width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                Expanded(
                  child: _DockedBottomTabItem(
                    label: 'Discover',
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore_rounded,
                    isSelected: navigationShell.currentIndex == 0,
                    onTap: () => _onSelectTab(0),
                  ),
                ),
                Expanded(
                  child: _DockedBottomTabItem(
                    label: 'Likes',
                    icon: Icons.favorite_border_rounded,
                    activeIcon: Icons.favorite_rounded,
                    isSelected: navigationShell.currentIndex == 1,
                    onTap: () => _onSelectTab(1),
                  ),
                ),
                Expanded(
                  child: _DockedBottomTabItem(
                    label: 'Chats',
                    icon: Icons.chat_bubble_outline_rounded,
                    activeIcon: Icons.chat_bubble_rounded,
                    badgeCount: unreadChats,
                    isSelected: navigationShell.currentIndex == 2,
                    onTap: () => _onSelectTab(2),
                  ),
                ),
                Expanded(
                  child: _DockedBottomTabItem(
                    label: 'You',
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    isSelected: navigationShell.currentIndex == 3,
                    onTap: () => _onSelectTab(3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockedBottomTabItem extends StatelessWidget {
  const _DockedBottomTabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    const activeColor = JDateTokens.brandRose;
    const inactiveColor = Color(0xFF71717A);
    final itemColor = isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 23,
                  color: itemColor,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: itemColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
