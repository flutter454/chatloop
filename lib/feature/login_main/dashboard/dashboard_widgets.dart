import 'package:flutter/material.dart';

import 'dashboard_provider.dart';

class CustomBottomBar extends StatelessWidget {
  final DashboardProvider provider;

  const CustomBottomBar({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              index: 0,
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore_rounded,
              label: 'Explore',
              provider: provider,
            ),
            _NavItem(
              index: 1,
              icon: Icons.search_outlined,
              activeIcon: Icons.search_rounded,
              label: 'Search',
              provider: provider,
            ),
            _NavItem(
              index: 2,
              icon: Icons.play_circle_outline,
              activeIcon: Icons.play_circle_fill,
              label: 'Reels',
              provider: provider,
            ),
            _NavItem(
              index: 3,
              icon: Icons.chat_bubble_outline,
              activeIcon: Icons.chat_bubble_rounded,
              label: 'Chat',
              provider: provider,
            ),
            _NavItem(
              index: 4,
              icon: Icons.person_outline,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
              provider: provider,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final DashboardProvider provider;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = provider.selectedIndex == index;
    return GestureDetector(
      onTap: () => provider.setSelectedIndex(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF4081).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFFFF4081) : Colors.grey,
              size: 26,
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4081),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
