import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyRidesPage extends StatelessWidget {
  const MyRidesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text("My Rides")),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: "Posted"),
                Tab(text: "Requested"),
                Tab(text: "Joined"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  MyPostedRides(user.email!),
                  MyRequestedRides(user.email!),
                  MyJoinedRides(user.email!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyPostedRides extends StatelessWidget {
  final String email;
  const MyPostedRides(this.email, {super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .where('owner', isEqualTo: email)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rides = snapshot.data!.docs;

        if (rides.isEmpty) {
          return const Center(child: Text("You haven’t posted any rides"));
        }

        return ListView(
          children: rides.map((ride) {
            return ListTile(
              title: Text("${ride['from']} → ${ride['to']}"),
              subtitle: Text("${ride['date']} at ${ride['time']}"),
            );
          }).toList(),
        );
      },
    );
  }
}

class MyRequestedRides extends StatelessWidget {
  final String email;
  const MyRequestedRides(this.email, {super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('requesterEmail', isEqualTo: email)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reqs = snapshot.data!.docs;

        if (reqs.isEmpty) {
          return const Center(child: Text("No requests sent"));
        }

        return ListView(
          children: reqs.map((r) {
            return ListTile(
              title: Text("Ride: ${r['rideId']}"),
              subtitle: Text("Status: ${r['status']}"),
            );
          }).toList(),
        );
      },
    );
  }
}

class MyJoinedRides extends StatelessWidget {
  final String email;
  const MyJoinedRides(this.email, {super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .where('passengers', arrayContains: email)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rides = snapshot.data!.docs;

        if (rides.isEmpty) {
          return const Center(child: Text("No confirmed rides"));
        }

        return ListView(
          children: rides.map((ride) {
            return ListTile(
              title: Text("${ride['from']} → ${ride['to']}"),
              subtitle: Text("${ride['date']} at ${ride['time']}"),
            );
          }).toList(),
        );
      },
    );
  }
}
