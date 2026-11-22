import 'package:flutter/material.dart';

class MoodCategory {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const MoodCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const List<MoodCategory> moodCategories = [
  MoodCategory(id: 'all', label: 'All Vibes', icon: Icons.explore_rounded, color: Colors.blueAccent),
  MoodCategory(id: 'foodie', label: 'Foodie Cravings', icon: Icons.fastfood_rounded, color: Colors.deepOrangeAccent),
  MoodCategory(id: 'visual', label: 'Insta-Visual', icon: Icons.auto_awesome_rounded, color: Colors.pinkAccent),
  MoodCategory(id: 'heritage', label: 'Heritage & Forts', icon: Icons.castle_rounded, color: Colors.amber),
  MoodCategory(id: 'chill', label: 'Chill Cafes', icon: Icons.local_cafe_rounded, color: Colors.teal),
  MoodCategory(id: 'shopping', label: 'Bazaars & Souvenirs', icon: Icons.shopping_bag_rounded, color: Colors.purpleAccent),
  MoodCategory(id: 'nightlife', label: 'Lively Nightlife', icon: Icons.nightlife_rounded, color: Colors.indigoAccent),
  MoodCategory(id: 'museums', label: 'Museums & Art', icon: Icons.museum_rounded, color: Colors.brown),
  MoodCategory(id: 'parks', label: 'Parks & Nature', icon: Icons.park_rounded, color: Colors.green),
];

class MoodSelectorBar extends StatelessWidget {
  final String selectedMood;
  final bool onlyVisualFood;
  final bool onlyTopVisited;
  final Function(String) onSelectMood;
  final Function(bool) onToggleVisualFood;
  final Function(bool) onToggleTopVisited;

  const MoodSelectorBar({
    super.key,
    required this.selectedMood,
    required this.onlyVisualFood,
    required this.onlyTopVisited,
    required this.onSelectMood,
    required this.onToggleVisualFood,
    required this.onToggleTopVisited,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Highlight Toggles (Visual Food Stalls & Most Visited)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [
              _buildFilterBadge(
                label: 'Visual Food Stalls',
                icon: Icons.local_dining_rounded,
                isActive: onlyVisualFood,
                activeColor: Colors.deepOrange,
                onTap: () => onToggleVisualFood(!onlyVisualFood),
              ),
              const SizedBox(width: 8),
              _buildFilterBadge(
                label: 'Top Visited',
                icon: Icons.star_rounded,
                isActive: onlyTopVisited,
                activeColor: Colors.amber.shade800,
                onTap: () => onToggleTopVisited(!onlyTopVisited),
              ),
            ],
          ),
        ),

        // Horizontal Mood Slider
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: moodCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final mood = moodCategories[index];
              final isSelected = selectedMood == mood.id;

              return ChoiceChip(
                showCheckmark: false,
                avatar: Icon(
                  mood.icon,
                  size: 18,
                  color: isSelected ? Colors.white : mood.color,
                ),
                label: Text(
                  mood.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                selected: isSelected,
                selectedColor: mood.color,
                backgroundColor: Colors.white.withAlpha(235),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: isSelected ? mood.color : Colors.black12,
                    width: 1.2,
                  ),
                ),
                elevation: isSelected ? 4 : 1,
                onSelected: (_) => onSelectMood(mood.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBadge({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white.withAlpha(242),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
          border: Border.all(
            color: isActive ? activeColor : Colors.black12,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : activeColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

