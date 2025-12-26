import 'package:flutter/material.dart';
import '../../../core/constants/survey_status.dart';

/// Filter Chip Bar - Displays filter chips for status and survey state
class FilterChipBar extends StatelessWidget {
  final String? selectedStatus;
  final bool? selectedSurveyFilter;
  final Function(String?) onStatusChanged;
  final Function(bool?) onSurveyFilterChanged;
  final VoidCallback onClearFilters;

  const FilterChipBar({
    Key? key,
    this.selectedStatus,
    this.selectedSurveyFilter,
    required this.onStatusChanged,
    required this.onSurveyFilterChanged,
    required this.onClearFilters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Survey state filters
          _buildFilterChip(
            label: 'All',
            isSelected: selectedSurveyFilter == null,
            onTap: () => onSurveyFilterChanged(null),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Verified',
            isSelected: selectedSurveyFilter == true,
            onTap: () => onSurveyFilterChanged(true),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Pending',
            isSelected: selectedSurveyFilter == false,
            onTap: () => onSurveyFilterChanged(false),
          ),
          const SizedBox(width: 16),

          // Divider
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.grey[300],
          ),
          const SizedBox(width: 16),

          // Status filters
          ...SurveyStatus.values.map((status) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                label: status.englishLabel,
                isSelected: selectedStatus == status.englishLabel,
                onTap: () {
                  if (selectedStatus == status.englishLabel) {
                    onStatusChanged(null);
                  } else {
                    onStatusChanged(status.englishLabel);
                  }
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue[700] : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
