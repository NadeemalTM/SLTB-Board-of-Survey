import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- HELPER: GET COLLECTION BY CURRENT YEAR ---
  // This automatically switches the storage bucket every year (e.g., 'survey_2026')
  CollectionReference get _currentCollection {
    final String currentYear = DateTime.now().year.toString();
    return _db.collection('survey_$currentYear');
  }

  // Hierarchical path: survey_YEAR/{mainRegion}/subRegions/{subRegion}/assets/{newCode}
  DocumentReference<Map<String, dynamic>> _assetDocRef({
    required String mainRegion,
    required String subRegion,
    required String newCode,
  }) {
    return _currentCollection
        .doc(mainRegion)
        .collection('subRegions')
        .doc(subRegion)
        .collection('assets')
        .doc(newCode);
  }

  // Query across all 'assets' subcollections
  Query<Map<String, dynamic>> get _assetsGroupQuery => _db.collectionGroup('assets');

  // --- 1. ADD NEW ITEM (Updated for Hierarchy) ---
  Future<void> addAsset({
    required String newCode,
    required String oldCode,
    required String description,
    
    // CHANGED: We now ask for specific hierarchy details
    required String mainRegion, // e.g., "Galle"
    required String subRegion,  // e.g., "Galle Depot"
    
    required int bookBalance,
    required int physicalBalance,
    required String status,
    required List<String> imagePaths,
    String? remarks,
  }) async {
    final docRef = _assetDocRef(mainRegion: mainRegion, subRegion: subRegion, newCode: newCode);

    await docRef.set({
      'newCode': newCode,
      'oldCode': oldCode,
      'description': description,
      
      // --- HIERARCHY FIELDS ---
      'mainRegion': mainRegion, 
      'subRegion': subRegion,
      'region': '$mainRegion - $subRegion', // Kept for display purposes
      
      'bookBalance': bookBalance,
      'physicalBalance': physicalBalance,
      
      // Auto-calculate Excess/Shortage
      'excess': (physicalBalance - bookBalance) > 0 ? (physicalBalance - bookBalance) : 0,
      'shortage': (bookBalance - physicalBalance) > 0 ? (bookBalance - physicalBalance) : 0,
      
      'status': status,
      'images': imagePaths,
      'remarks': remarks ?? '',
      
      // --- WORKFLOW FIELDS ---
      'approvalLevel': 0, // 0 = Region Officer, 1 = Auditor, 2 = Admin
      'approvalStatus': 'Pending Audit', 
      'isNew': true,
      
      // TIMESTAMPS
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // --- 2. CHECK IF ITEM EXISTS ---
  Future<DocumentSnapshot> getAsset(String code) async {
    final snap = await _assetsGroupQuery.where('newCode', isEqualTo: code).limit(1).get();
    if (snap.docs.isNotEmpty) {
      return snap.docs.first;
    }
    // Fallback: flat collection (legacy)
    return await _currentCollection.doc(code).get();
  }

  // --- 3. UPDATE ASSET ---
  Future<void> updateAsset(String code, int quantity, String status, String remarks) async {
    // Find by code in hierarchical structure
    final snap = await _assetsGroupQuery.where('newCode', isEqualTo: code).limit(1).get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({
        'physicalBalance': quantity,
        'status': status,
        'remarks': remarks,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return;
    }
    // Fallback to legacy flat doc
    await _currentCollection.doc(code).update({
      'physicalBalance': quantity,
      'status': status,
      'remarks': remarks,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // --- 4. APPROVAL WORKFLOW ---
  Future<void> auditorApprove(String barcode) async {
    final snap = await _assetsGroupQuery.where('newCode', isEqualTo: barcode).limit(1).get();
    final ref = snap.docs.isNotEmpty ? snap.docs.first.reference : _currentCollection.doc(barcode);
    await ref.update({
      'approvalLevel': 1,
      'approvalStatus': 'Verified by Auditor',
      'auditedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminFinalApprove(String barcode) async {
    final snap = await _assetsGroupQuery.where('newCode', isEqualTo: barcode).limit(1).get();
    final ref = snap.docs.isNotEmpty ? snap.docs.first.reference : _currentCollection.doc(barcode);
    await ref.update({
      'approvalLevel': 2,
      'approvalStatus': 'Approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- 5. DATA STREAMS ---
  Stream<QuerySnapshot> getAssetsStream() {
    // Uses collection group to stream all assets across regions
    return _assetsGroupQuery.orderBy('lastUpdated', descending: true).snapshots();
  }

  Stream<QuerySnapshot> getPendingAuditStream() {
    return _assetsGroupQuery.where('approvalLevel', isEqualTo: 0).snapshots();
  }

  Stream<QuerySnapshot> getPendingAdminApprovalStream() {
    return _assetsGroupQuery.where('approvalLevel', isEqualTo: 1).snapshots();
  }

  // --- 6. MIGRATION: FLAT -> HIERARCHICAL ---
  Future<void> migrateFlatToHierarchy({bool deleteSource = false}) async {
    final flatDocs = await _currentCollection.get();
    for (final d in flatDocs.docs) {
      final data = d.data() as Map<String, dynamic>;
      final code = data['newCode']?.toString();
      final mainRegion = data['mainRegion']?.toString();
      final subRegion = data['subRegion']?.toString();
      if (code == null || mainRegion == null || subRegion == null) {
        continue;
      }
      final dest = _assetDocRef(mainRegion: mainRegion, subRegion: subRegion, newCode: code);
      await dest.set(data, SetOptions(merge: true));
      if (deleteSource) {
        await d.reference.delete();
      }
    }
  }
}