import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../state/app_state.dart';
import '../screens/ride_details_page.dart';
import '../screens/create_ride_page.dart';


class RideList extends StatelessWidget {
  const RideList({super.key});

  @override
  Widget build(BuildContext context) {
    // Forces rebuild when search button is pressed
    final _ = searchNotifier.value;

    Query query = FirebaseFirestore.instance.collection('rides');

    if (RideFilter.from != "Any") {
      query = query.where('from', isEqualTo: RideFilter.from);
    }

    if (RideFilter.to != "Any") {
      query = query.where('to', isEqualTo: RideFilter.to);
    }

    if (RideFilter.date != null) {
      final d = RideFilter.date!;
      final dateStr =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      query = query.where('date', isEqualTo: dateStr);
    }

    query = query.orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rides = snapshot.data!.docs;

        if (rides.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("No rides found"),
                const SizedBox(height: 10),
                ElevatedButton(
                  child: const Text("Be the first — create a ride"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateRidePage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.directions_car),
                title: Text("${ride['from']} → ${ride['to']}"),
                subtitle: Text(
                  "${ride['date']} at ${ride['time']} • ${ride['seats']} seats",
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RideDetailsPage(rideId: ride.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
