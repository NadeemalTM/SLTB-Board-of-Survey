import 'package:flutter/material.dart';

class StatisticOverviewCard extends StatefulWidget {
  final int totalItems;
  final int surveyedItems;
  final int pendingItems;
  final double completionPercentage;

  const StatisticOverviewCard({
    Key? key,
    required this.totalItems,
    required this.surveyedItems,
    required this.pendingItems,
    required this.completionPercentage,
  }) : super(key: key);

  @override
  State<StatisticOverviewCard> createState() => _StatisticOverviewCardState();
}

class _StatisticOverviewCardState extends State<StatisticOverviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.completionPercentage / 100,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1B5E20),
                    const Color(0xFF0D1B0E),
                  ]
                : [
                    const Color(0xFF66BB6A),
                    const Color(0xFF2E7D32),
                  ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Survey Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Overall completion status',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total',
                      widget.totalItems.toString(),
                      Icons.inventory_2,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white24,
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Completed',
                      widget.surveyedItems.toString(),
                      Icons.check_circle,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white24,
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Pending',
                      widget.pendingItems.toString(),
                      Icons.pending,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Completion Rate',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Text(
                            '${(_progressAnimation.value * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          minHeight: 12,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFFD700),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
