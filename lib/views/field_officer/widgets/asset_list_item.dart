import 'package:flutter/material.dart';
import '../../../data/models/asset_model.dart';

/// Asset List Item Widget - Displays a single asset in the list
class AssetListItem extends StatelessWidget {
  final AssetModel asset;
  final VoidCallback onTap;

  const AssetListItem({
    Key? key,
    required this.asset,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSurveyed = asset.isSurveyed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Asset info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Code
                    Text(
                      asset.newCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      asset.description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Status chips
                    Row(
                      children: [
                        if (isSurveyed) ...[
                          _buildChip(
                            label: asset.surveyStatus ?? 'Surveyed',
                            color: _getStatusColor(),
                          ),
                          if (asset.hasImages) ...[
                            const SizedBox(width: 8),
                            _buildChip(
                              label: '${asset.imageCount} 📷',
                              color: const Color(0xFF8B0000),
                            ),
                          ],
                        ] else
                          _buildChip(
                            label: 'Pending',
                            color: Colors.orange,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (!asset.isSurveyed) return Colors.orange;

    switch (asset.surveyStatus) {
      case 'Good':
        return Colors.green;
      case 'Broken':
        return Colors.red;
      case 'Repairable':
        return Colors.amber;
      case 'To be Disposed':
        return Colors.purple;
      case 'New Found':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
