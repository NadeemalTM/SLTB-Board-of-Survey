import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Access the 'assets' collection in the cloud
  final CollectionReference assetsCollection = 
      FirebaseFirestore.instance.collection('assets');

  // 1. ADD NEW ITEM (When Field Officer scans a new item)
  Future<void> addAsset(String code, String description, int quantity, String location) async {
    // We use the Barcode as the Document ID so we don't get duplicates
    await assetsCollection.doc(code).set({
      'code': code,
      'description': description,
      'physicalBalance': quantity,
      'location': location,
      'isNew': true, 
      'status': 'Pending',
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // 2. CHECK IF ITEM EXISTS (When scanning)
  Future<DocumentSnapshot> getAsset(String code) async {
    return await assetsCollection.doc(code).get();
  }

  // 3. GET ALL ASSETS (For Admin Dashboard)
  Stream<QuerySnapshot> getAssetsStream() {
    return assetsCollection.orderBy('lastUpdated', descending: true).snapshots();
  }
}