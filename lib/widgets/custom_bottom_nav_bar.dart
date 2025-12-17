import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      color: Colors.transparent,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(context, 0, Icons.home_rounded, Icons.home_outlined, 'Inicio'),
            _buildNavItem(context, 1, Icons.map_rounded, Icons.map_outlined, 'Mapa'),
            _buildNavItem(context, 2, Icons.notifications_active_rounded, Icons.notifications_active_outlined, 'Avisos'),
            _buildNavItem(context, 3, Icons.person_rounded, Icons.person_outline_rounded, 'Cuenta'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = currentIndex == index;
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              )
            : const BoxDecoration(
                color: Colors.transparent,
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? primaryColor : Colors.grey.shade400,
              size: 26,
            ),
            if (isSelected)
               Padding(
                 padding: const EdgeInsets.only(top: 4),
                 child: Text(
                   label,
                   style: TextStyle(
                     color: primaryColor,
                     fontSize: 10,
                     fontWeight: FontWeight.w700,
                   ),
                 ),
               ),
          ],
        ),
      ),
    );
  }
}
