import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../state/app_state.dart';

// widgets
import '../widgets/filter_bar.dart';
import '../widgets/ride_list.dart';

// screens
import 'create_ride_page.dart';
import 'owner_requests_page.dart';
import 'ride_details_page.dart';
import 'my_rides_page.dart';

// 🔔 Notifier for search button
final ValueNotifier<int> searchNotifier = ValueNotifier(0);

// 🔎 Ride filters
class RideFilter {
  static String from = "Any";
  static String to = "Any";
  static DateTime? date;
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("VIT → Airport Carpool"),
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle),
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Text(user?.email ?? ''),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
          onSelected: (value) {
            if (value == 'logout') logout();
          },
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('requests')
                .where('ownerEmail', isEqualTo: user!.email)
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;

              return IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OwnerRequestsPage(),
                    ),
                  );
                },
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (count > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: const [
          Padding(
            padding: EdgeInsets.all(12),
            child: FilterBar(),
          ),
          Expanded(
            child: RideList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateRidePage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
