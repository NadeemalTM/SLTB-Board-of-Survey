import 'package:flutter/material.dart';
import '../data/region_data.dart'; // Import the data file we just made

class RegionSelector extends StatefulWidget {
  final Function(String main, String sub) onSelectionChanged;

  const RegionSelector({super.key, required this.onSelectionChanged});

  @override
  State<RegionSelector> createState() => _RegionSelectorState();
}

class _RegionSelectorState extends State<RegionSelector> {
  String? _selectedMainRegion;
  String? _selectedSubRegion;
  
  // To update the list of sub-regions based on main selection
  List<String> _currentSubRegions = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. MAIN REGION SEARCHABLE DROPDOWN ---
        const Text("Select Main Region", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownMenu<String>(
          width: double.infinity, // Make it fill width
          enableFilter: true,     // <--- THIS ENABLES SEARCH
          hintText: "Search Region (e.g. Galle)",
          dropdownMenuEntries: sltbRegions.keys.map<DropdownMenuEntry<String>>((String region) {
            return DropdownMenuEntry<String>(value: region, label: region);
          }).toList(),
          onSelected: (String? region) {
            if (region != null) {
              setState(() {
                _selectedMainRegion = region;
                // Update sub-regions list automatically
                _currentSubRegions = sltbRegions[region] ?? [];
                _selectedSubRegion = null; // Reset sub-region
              });
              // Notify parent widget
              widget.onSelectionChanged(region, "");
            }
          },
        ),

        const SizedBox(height: 16),

        // --- 2. SUB-REGION SEARCHABLE DROPDOWN ---
        // Only show this if a Main Region is selected
        if (_selectedMainRegion != null) ...[
          const Text("Select Sub-Division", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownMenu<String>(
            key: ValueKey(_selectedMainRegion), // Forces rebuild when main changes
            width: double.infinity,
            enableFilter: true,
            hintText: "Search Sub-Division",
            dropdownMenuEntries: _currentSubRegions.map<DropdownMenuEntry<String>>((String sub) {
              return DropdownMenuEntry<String>(value: sub, label: sub);
            }).toList(),
            onSelected: (String? sub) {
              if (sub != null) {
                setState(() => _selectedSubRegion = sub);
                // Send full data back (Main + Sub)
                widget.onSelectionChanged(_selectedMainRegion!, sub);
              }
            },
          ),
        ],
      ],
    );
  }
}