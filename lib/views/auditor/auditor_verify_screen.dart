import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class AuditorVerifyScreen extends StatelessWidget {
  const AuditorVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final yearCollection = 'survey_${DateTime.now().year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Field Auditor Verification"),
        backgroundColor: Colors.orange[800],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Only show items that are Level 0 (Pending Audit)
        stream: FirebaseFirestore.instance
            .collection(yearCollection)
            .where('approvalLevel', isEqualTo: 0) 
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No pending items to verify."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['description'] ?? 'Unknown'),
                  subtitle: Text("Code: ${data['newCode']}\nRegion: ${data['region']}"),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      // Approve and move to Level 1
                      firestore.auditorApprove(docId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Item Verified!")),
                      );
                    },
                    child: const Text("VERIFY", style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}