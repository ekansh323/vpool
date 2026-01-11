import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerRequestsPage extends StatelessWidget {
  const OwnerRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Ride Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('ownerEmail', isEqualTo: user!.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(child: Text("No pending requests"));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];

              return Card(
                child: ListTile(
                  title: Text(req['requesterEmail']),
                  subtitle: Text("Wants to join your ride"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => approve(req.id, req['rideId']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => reject(req.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static Future<void> approve(String requestId, String rideId) async {
    final rideRef = FirebaseFirestore.instance.collection('rides').doc(rideId);
    final reqRef =
        FirebaseFirestore.instance.collection('requests').doc(requestId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final rideSnap = await tx.get(rideRef);
      final reqSnap = await tx.get(reqRef);

      final seats = rideSnap['seats'];
      final status = reqSnap['status'];
      final requester = reqSnap['requesterEmail'];

      if (status != 'pending') return;

      if (seats <= 0) {
        tx.update(reqRef, {'status': 'rejected'});
        return;
      }

      tx.update(rideRef, {
        'seats': seats - 1,
        'passengers': FieldValue.arrayUnion([requester])
      });

      tx.update(reqRef, {'status': 'approved'});
    });
  }

  static Future<void> reject(String requestId) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }
}
