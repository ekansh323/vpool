import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class RideDetailsPage extends StatelessWidget {
  final String rideId;

  const RideDetailsPage({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final requestStream = FirebaseFirestore.instance
        .collection('requests')
        .where('rideId', isEqualTo: rideId)
        .where('requesterEmail', isEqualTo: user?.email)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Ride Details")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .doc(rideId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final passengers = List<String>.from(data['passengers'] ?? []);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${data['from']} → ${data['to']}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text("Date: ${data['date']}"),
                Text("Time: ${data['time']}"),
                Text("Seats left: ${data['seats']}"),
                Text("Posted by: ${data['owner']}"),

                // ---------------- OWNER VIEW ----------------
                if (data['owner'] == user?.email) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const Text(
                    "Passengers",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (passengers.isEmpty)
                    const Text("No one has joined yet"),

                  ...passengers.map((email) {
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(email),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          removePassenger(context, rideId, email);
                        },
                      ),
                    );
                  }).toList(),
                ],

                const Spacer(),

                // ---------------- REQUEST STATUS ----------------
                StreamBuilder<QuerySnapshot>(
                  stream: requestStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      if (data['seats'] <= 0) {
                        return const Text(
                          "No seats left",
                          style: TextStyle(color: Colors.red),
                        );
                      }

                      return ElevatedButton(
                        onPressed: () {
                          requestRide(context, rideId, data);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text("Request to Join"),
                      );
                    }

                    final status = snapshot.data!.docs.first['status'];

                    if (status == 'pending') {
                      return const Text(
                        "Request Pending ⏳",
                        style: TextStyle(color: Colors.orange, fontSize: 16),
                      );
                    }

                    if (status == 'approved') {
                      return const Text(
                        "Approved ✅",
                        style: TextStyle(color: Colors.green, fontSize: 16),
                      );
                    }

                    return const Text(
                      "Rejected ❌",
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // ---------------- WHATSAPP ----------------
                OutlinedButton.icon(
                  icon: const Icon(Icons.chat),
                  label: const Text("Chat on WhatsApp"),
                  onPressed: () async {
                    final number = data['whatsapp'];
                    final message =
                        "Hi, I saw your ${data['from']} → ${data['to']} ride on VIT Carpool.";

                    final url =
                        "https://wa.me/$number?text=${Uri.encodeComponent(message)}";

                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------- SEND REQUEST ----------------
  static Future<void> requestRide(
    BuildContext context,
    String rideId,
    Map<String, dynamic> ride,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email!;

    if (ride['owner'] == email) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't request your own ride")),
      );
      return;
    }

    final requestId = "${rideId}_$email";
    final ref =
        FirebaseFirestore.instance.collection('requests').doc(requestId);

    final existing = await ref.get();
    if (existing.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You already requested this ride")),
      );
      return;
    }

    await ref.set({
      'rideId': rideId,
      'requesterEmail': email,
      'ownerEmail': ride['owner'],
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request sent")),
    );
  }

  // ---------------- REMOVE PASSENGER ----------------
  static Future<void> removePassenger(
    BuildContext context,
    String rideId,
    String email,
  ) async {
    final ref = FirebaseFirestore.instance.collection('rides').doc(rideId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final seats = snap['seats'];

      tx.update(ref, {
        'seats': seats + 1,
        'passengers': FieldValue.arrayRemove([email]),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Passenger removed")),
    );
  }
}
