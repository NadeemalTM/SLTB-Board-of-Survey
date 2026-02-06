import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

// NOTE: This is essentially a clone of RegionDashboard logic 
// but tailored for the Field Officer's view.

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String get _collectionName => 'survey_${DateTime.now().year}';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Field Officer Dashboard", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Auditor: ${user.username}", style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: const Color(0xFF0C3B2E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // FETCH DATA: If user is assigned to "Galle", show all Galle items
        stream: FirebaseFirestore.instance
            .collection(_collectionName)
            .where('mainRegion', isEqualTo: user.mainRegion)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          // --- STATS LOGIC ---
          final totalAssets = docs.length;
          // Verified = Approval Level is 1 (Auditor) or 2 (Admin)
          final verifiedCount = docs.where((d) => (d['approvalLevel'] ?? 0) >= 1).length;
          // Pending = Approval Level 0 (Waiting for Auditor)
          final pendingCount = docs.where((d) => (d['approvalLevel'] ?? 0) == 0).length;
          
          final completionRate = totalAssets == 0 ? 0.0 : (verifiedCount / totalAssets);

          // --- BREAKDOWN LOGIC ---
          int good = 0, broken = 0, missing = 0, dispose = 0;
          for (var doc in docs) {
            final status = (doc['status'] ?? '').toString().toLowerCase();
            if (status == 'good') good++;
            else if (status == 'broken') broken++;
            else if (status == 'missing') missing++;
            else dispose++;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 1. SUMMARY CARDS
                Row(
                  children: [
                    _buildStatCard("Total Assets", totalAssets.toString(), Colors.blue, Icons.folder),
                    const SizedBox(width: 12),
                    _buildStatCard("Verified", verifiedCount.toString(), Colors.green, Icons.fact_check),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard("To Verify", pendingCount.toString(), Colors.orange, Icons.pending),
                    const SizedBox(width: 12),
                    _buildStatCard("Progress", "${(completionRate * 100).toStringAsFixed(0)}%", Colors.purple, Icons.percent),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. CONDITION REPORT (Replaces Quick Actions)
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Condition Report", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                ),
                const SizedBox(height: 16),
                
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildStatusBar("Good", good, totalAssets, Colors.green),
                        const SizedBox(height: 16),
                        _buildStatusBar("Broken", broken, totalAssets, Colors.red),
                        const SizedBox(height: 16),
                        _buildStatusBar("Missing", missing, totalAssets, Colors.orange),
                        const SizedBox(height: 16),
                        _buildStatusBar("Disposal", dispose, totalAssets, Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Reuse the same widget helper functions
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3)),
          ],
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(String label, int count, int total, Color color) {
    double pct = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text("$count", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: pct,
          backgroundColor: Colors.grey[100],
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}