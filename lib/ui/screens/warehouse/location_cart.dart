import 'package:flutter/material.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/location_model.dart';

class LocationCard extends StatelessWidget {
  final LocationModel location;
  final bool isSelected;
  final VoidCallback onSelected;

  const LocationCard({
    super.key,
    required this.location,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isSelected ? Colors.green : Colors.transparent,
          width: 2.0,
        ),
      ),
      elevation: isSelected ? 3 : 1,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              // Leading icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green : Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  color: isSelected ? Colors.white : Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Location details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            location.code,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.green : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                )
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
