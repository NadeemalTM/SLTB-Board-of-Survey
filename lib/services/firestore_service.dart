import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- HELPER: GET COLLECTION BY CURRENT YEAR ---
  // This automatically switches the storage bucket every year (e.g., 'survey_2026')
  CollectionReference get _currentCollection {
    final String currentYear = DateTime.now().year.toString();
    return _db.collection('survey_$currentYear');
  }

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
    final docRef = _currentCollection.doc(newCode);

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
    return await _currentCollection.doc(code).get();
  }

  // --- 3. UPDATE ASSET ---
  Future<void> updateAsset(String code, int quantity, String status, String remarks) async {
    await _currentCollection.doc(code).update({
      'physicalBalance': quantity,
      'status': status,
      'remarks': remarks,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // --- 4. APPROVAL WORKFLOW ---
  Future<void> auditorApprove(String barcode) async {
    await _currentCollection.doc(barcode).update({
      'approvalLevel': 1,
      'approvalStatus': 'Verified by Auditor',
      'auditedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminFinalApprove(String barcode) async {
    await _currentCollection.doc(barcode).update({
      'approvalLevel': 2,
      'approvalStatus': 'Approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- 5. DATA STREAMS ---
  Stream<QuerySnapshot> getAssetsStream() {
    return _currentCollection.orderBy('lastUpdated', descending: true).snapshots();
  }

  Stream<QuerySnapshot> getPendingAuditStream() {
    return _currentCollection.where('approvalLevel', isEqualTo: 0).snapshots();
  }

  Stream<QuerySnapshot> getPendingAdminApprovalStream() {
    return _currentCollection.where('approvalLevel', isEqualTo: 1).snapshots();
  }
}