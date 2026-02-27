import 'package:flutter/material.dart';
import '../data/region_data.dart';

/// A reusable Region & Sub-Region selector widget.
///
/// Behavior:
/// - If [lockedMainRegion] is provided (e.g. from logged-in user),
///   the main region is shown as a locked/read-only chip and only
///   the sub-regions of that main region are shown for manual selection.
/// - If [lockedMainRegion] is null (e.g. Admin), both main region
///   and sub-region dropdowns are fully selectable.
/// - [initialMainRegion] and [initialSubRegion] can pre-fill values.
class RegionSelector extends StatefulWidget {
  final Function(String main, String sub) onSelectionChanged;

  /// If set, the main region is locked and only sub-regions are selectable.
  final String? lockedMainRegion;

  /// Initial values for pre-filling
  final String? initialMainRegion;
  final String? initialSubRegion;

  const RegionSelector({
    super.key,
    required this.onSelectionChanged,
    this.lockedMainRegion,
    this.initialMainRegion,
    this.initialSubRegion,
  });

  @override
  State<RegionSelector> createState() => _RegionSelectorState();
}

class _RegionSelectorState extends State<RegionSelector> {
  String? _selectedMainRegion;
  String? _selectedSubRegion;
  List<String> _currentSubRegions = [];

  @override
  void initState() {
    super.initState();

    // Determine effective main region
    final effectiveMain = widget.lockedMainRegion ?? widget.initialMainRegion;

    if (effectiveMain != null && effectiveMain.isNotEmpty) {
      _selectedMainRegion = effectiveMain;
      _currentSubRegions = sltbRegions[effectiveMain] ?? [];

      // Pre-set sub-region if provided and valid
      if (widget.initialSubRegion != null &&
          widget.initialSubRegion!.isNotEmpty &&
          _currentSubRegions.contains(widget.initialSubRegion)) {
        _selectedSubRegion = widget.initialSubRegion;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMainLocked =
        widget.lockedMainRegion != null && widget.lockedMainRegion!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. MAIN REGION ---
        const Text("Main Region",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),

        if (isMainLocked)
          // LOCKED: Show as a read-only chip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A2E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF0C3B2E).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    size: 18, color: Color(0xFF0C3B2E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedMainRegion ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0C3B2E),
                    ),
                  ),
                ),
                const Icon(Icons.lock, size: 14, color: Colors.blueGrey),
              ],
            ),
          )
        else
          // UNLOCKED: Searchable dropdown for all regions
          DropdownMenu<String>(
            width: double.infinity,
            enableFilter: true,
            hintText: "Search Region (e.g. Galle)",
            initialSelection: _selectedMainRegion,
            dropdownMenuEntries: sltbRegions.keys
                .map<DropdownMenuEntry<String>>((String region) {
              return DropdownMenuEntry<String>(value: region, label: region);
            }).toList(),
            onSelected: (String? region) {
              if (region != null) {
                setState(() {
                  _selectedMainRegion = region;
                  _currentSubRegions = sltbRegions[region] ?? [];
                  _selectedSubRegion = null; // Reset sub-region
                });
                widget.onSelectionChanged(region, "");
              }
            },
          ),

        const SizedBox(height: 16),

        // --- 2. SUB-REGION ---
        if (_selectedMainRegion != null && _currentSubRegions.isNotEmpty) ...[
          const Text("Sub-Division",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          DropdownMenu<String>(
            key: ValueKey('${_selectedMainRegion}_sub'),
            width: double.infinity,
            enableFilter: true,
            hintText: "Select Sub-Division",
            initialSelection: _selectedSubRegion,
            dropdownMenuEntries:
                _currentSubRegions.map<DropdownMenuEntry<String>>((String sub) {
              return DropdownMenuEntry<String>(value: sub, label: sub);
            }).toList(),
            onSelected: (String? sub) {
              if (sub != null) {
                setState(() => _selectedSubRegion = sub);
                widget.onSelectionChanged(_selectedMainRegion!, sub);
              }
            },
          ),

          // Show hint if sub-region not yet selected
          if (_selectedSubRegion == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text(
                    "Please select a sub-division",
                    style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
