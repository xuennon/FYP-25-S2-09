import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestProgramsPage extends StatefulWidget {
  const TestProgramsPage({super.key});

  @override
  State<TestProgramsPage> createState() => _TestProgramsPageState();
}

class _TestProgramsPageState extends State<TestProgramsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _status = 'Ready to test...';
  List<Map<String, dynamic>> _documents = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Programs Connection'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: $_status',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _testAuthStatus,
              child: const Text('Check Auth Status'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _testDirectFirestoreAccess,
              child: const Text('Test Direct Firestore Access'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _testServicesCollection,
              child: const Text('Test Services Collection'),
            ),
            const SizedBox(height: 20),
            
            if (_documents.isNotEmpty) ...[
              const Text(
                'Documents found:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final doc = _documents[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ID: ${doc['id'] ?? 'Unknown'}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Name: ${doc['name'] ?? 'N/A'}'),
                            Text('Category: ${doc['category'] ?? 'N/A'}'),
                            Text('Duration: ${doc['duration'] ?? 'N/A'}'),
                            Text('CreatedBy: ${doc['createdBy'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _testAuthStatus() async {
    setState(() {
      _status = 'Checking authentication...';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _status = '❌ No user authenticated';
        });
      } else {
        setState(() {
          _status = '✅ User: ${user.uid}\nAnonymous: ${user.isAnonymous}\nEmail: ${user.email ?? 'None'}';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Auth error: $e';
      });
    }
  }

  Future<void> _testDirectFirestoreAccess() async {
    setState(() {
      _status = 'Testing Firestore access...';
    });

    try {
      // Test if we can access Firestore at all
      final testDoc = await _firestore.doc('test/test').get();
      setState(() {
        _status = '✅ Firestore accessible (test doc exists: ${testDoc.exists})';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Firestore error: $e';
      });
    }
  }

  Future<void> _testServicesCollection() async {
    setState(() {
      _status = 'Testing services collection...';
      _documents = [];
    });

    try {
      print('🔍 Testing services collection access...');
      
      final querySnapshot = await _firestore
          .collection('services')
          .get();
      
      print('✅ Got ${querySnapshot.docs.length} documents');
      
      final docs = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'],
          'category': data['category'],
          'duration': data['duration'],
          'createdBy': data['createdBy'],
          'description': data['description'],
        };
      }).toList();

      setState(() {
        _status = '✅ Found ${querySnapshot.docs.length} documents in services collection';
        _documents = docs;
      });
    } catch (e) {
      print('❌ Error accessing services collection: $e');
      setState(() {
        _status = '❌ Services collection error: $e';
      });
    }
  }
}
