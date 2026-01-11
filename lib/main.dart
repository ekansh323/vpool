import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

final ValueNotifier<int> searchNotifier = ValueNotifier(0);

class RideFilter {
  static String from = "Any";
  static String to = "Any";
  static DateTime? date;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🔥 THIS LINE FIXES THE WHITE BAR
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xFF00E5A8),
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VPool',
      theme: ThemeData(
        useMaterial3: true,

        scaffoldBackgroundColor: const Color(0xFF0E0E12),

        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00E5A8),
          secondary: const Color(0xFF4FC3F7),
          background: const Color(0xFF0E0E12),
          surface: const Color(0xFF1A1A22),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        cardTheme: const CardThemeData(
          color: const Color(0xFF1A1A22),
          elevation: 10,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5A8),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
        ),
      ),

      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          Future.microtask(() {
            FirebaseFirestore.instance.collection('users').doc(user.email).set({
              'email': user.email,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          });
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
//

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: index == 0 ? const ExplorePage() : const MyRidesPage(),

      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: "Explore"),
          NavigationDestination(icon: Icon(Icons.person), label: "My Rides"),
        ],
      ),
    );
  }
}

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExploreRideScreen();
  }
}

class ExploreRideScreen extends StatefulWidget {
  const ExploreRideScreen({super.key});

  @override
  State<ExploreRideScreen> createState() => _ExploreRideScreenState();
}

class _ExploreRideScreenState extends State<ExploreRideScreen> {
  void refresh() {
    setState(() {}); // forces Firestore query to re-run
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("VPool", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.account_circle),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
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
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 350),
                      pageBuilder: (_, __, ___) => OwnerRequestsPage(),
                      transitionsBuilder: (_, anim, __, child) {
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.08),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        );
                      },
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
        children: [
          Padding(padding: const EdgeInsets.all(12), child: const FilterBar()),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: searchNotifier,
              builder: (_, __, ___) {
                return RideList();
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 350),
              pageBuilder: (_, __, ___) => CreateRidePage(),
              transitionsBuilder: (_, anim, __, child) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                );
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

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
      extendBody: true,

      appBar: AppBar(title: const Text("Ride Details")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .doc(rideId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView.builder(
              itemCount: 6,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final passengers = List<String>.from(data['passengers'] ?? []);
          final hostedStream = FirebaseFirestore.instance
              .collection('rides')
              .where('owner', isEqualTo: data['owner'])
              .snapshots();

          final joinedStream = FirebaseFirestore.instance
              .collection('rides')
              .where('passengers', arrayContains: data['owner'])
              .snapshots();

          final ownerName = getNameFromEmail(data['owner']);
          final ownerBatch = getBatchFromEmail(data['owner']);

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
                Text(
                  "Date: ${data['date']}",
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  "Time: ${data['time']}",
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  "Seats available: ${data['seats']}",
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  "$ownerName (Batch $ownerBatch)",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: hostedStream,
                      builder: (_, snap) {
                        final count = snap.data?.docs.length ?? 0;
                        return Text(
                          "Hosted $count rides",
                          style: TextStyle(color: Colors.white),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: joinedStream,
                      builder: (_, snap) {
                        final count = snap.data?.docs.length ?? 0;

                        return Text(
                          "Joined $count rides",
                          style: TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ],
                ),
                if (data['owner'] == user?.email && passengers.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  Text(
                    "Passengers",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  if (passengers.isEmpty)
                    const Text(
                      "No one has joined yet",
                      style: TextStyle(color: Colors.white),
                    ),
                  Column(
                    children: passengers.map((email) {
                      final isOwner =
                          data['owner'] ==
                          FirebaseAuth.instance.currentUser!.email;

                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(email),
                        trailing: isOwner
                            ? IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  removePassenger(context, rideId, email);
                                },
                              )
                            : null,
                      );
                    }).toList(),
                  ),

                  const Text(
                    "Passengers",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  ...List.from(data['passengers']).map((p) {
                    return ListTile(
                      title: Text(p),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          RideDetailsPage.removePassenger(context, rideId, p);
                        },
                      ),
                    );
                  }).toList(),
                ],

                const Spacer(),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102A43),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                                style: TextStyle(color: Colors.redAccent),
                              );
                            }

                            return SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () {
                                  RideDetailsPage.requestRide(
                                    context,
                                    rideId,
                                    data,
                                  );
                                },
                                child: const Text(
                                  "Request to Join",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }

                          final status = snapshot.data!.docs.first['status'];

                          if (status == 'pending') {
                            return const Text(
                              "Request Pending ⏳",
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 16,
                              ),
                            );
                          }

                          if (status == 'approved') {
                            return const Text(
                              "Approved ✅",
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 16,
                              ),
                            );
                          }

                          return const Text(
                            "Rejected ❌",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 16,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      OutlinedButton.icon(
                        icon: const Icon(Icons.chat, color: Colors.white),
                        label: const Text(
                          "Chat on WhatsApp",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () async {
                          final number = data['whatsapp'];
                          final message =
                              "Hi, I saw your ${data['from']} → ${data['to']} ride on VITPool.";

                          final url =
                              "https://wa.me/$number?text=${Uri.encodeComponent(message)}";

                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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
        const SnackBar(
          content: Text(
            "You can't request your own ride",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    // Unique request id: one user → one request → one ride
    final requestId = "${rideId}_$email";

    final requestRef = FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId);

    final existing = await requestRef.get();

    if (existing.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You already requested this ride",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    await requestRef.set({
      'rideId': rideId,
      'requesterEmail': email,
      'ownerEmail': ride['owner'],
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Request sent to ride owner",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

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
      const SnackBar(
        content: Text(
          "Passenger removed",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class CreateRidePage extends StatefulWidget {
  const CreateRidePage({super.key});

  @override
  State<CreateRidePage> createState() => _CreateRidePageState();
}

class _CreateRidePageState extends State<CreateRidePage> {
  String from = "VIT";
  String to = "Chennai Airport";
  DateTime? date;
  TimeOfDay? time;
  int seats = 3;
  bool loading = false;

  final whatsappController = TextEditingController();

  final locations = [
    "VIT",
    "Katpadi Station",
    "Chennai Airport",
    "Bangalore Airport",
  ];

  Future<void> saveRide() async {
    final phone = whatsappController.text.trim();

    if (phone.length != 10 || int.tryParse(phone) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Enter a valid 10-digit WhatsApp number",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    if (date == null || time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Select date and time",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    setState(() => loading = true);

    final user = FirebaseAuth.instance.currentUser;

    final dateStr =
        "${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}";

    final timeStr =
        "${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}";

    await FirebaseFirestore.instance.collection('rides').add({
      'from': from,
      'to': to,
      'date': dateStr,
      'time': timeStr,
      'seats': seats,
      'owner': user?.email,
      'whatsapp': "91$phone",
      'requests': [],
      'passengers': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post a Ride")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField(
              value: from,
              items: locations
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => from = v!),
              decoration: const InputDecoration(labelText: "From"),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField(
              value: to,
              items: locations
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => to = v!),
              decoration: const InputDecoration(labelText: "To"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: whatsappController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "Your WhatsApp number",
                hintText: "10-digit mobile number (e.g. 9876543210)",
                prefixText: "+91 ",
                prefixIcon: Icon(Icons.phone),
                counterText: "",
              ),
            ),
            const SizedBox(height: 12),

            ListTile(
              title: Text(
                date == null
                    ? "Select Date"
                    : "${date!.day}/${date!.month}/${date!.year}",
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2027),
                  initialDate: DateTime.now(),
                );
                if (picked != null) setState(() => date = picked);
              },
            ),

            ListTile(
              title: Text(time == null ? "Select Time" : time!.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) setState(() => time = picked);
              },
            ),

            Row(
              children: [
                const Text("Seats"),
                Expanded(
                  child: Slider(
                    value: seats.toDouble(),
                    min: 1,
                    max: 6,
                    divisions: 5,
                    label: seats.toString(),
                    onChanged: (v) => setState(() => seats = v.toInt()),
                  ),
                ),
              ],
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : saveRide,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Post Ride",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isLoading = false;
  String error = '';

  Future<void> login() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } catch (_) {
      setState(() {
        error = 'Invalid email or password';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final email = userCred.user!.email ?? '';

      if (!email.endsWith('@vitstudent.ac.in')) {
        await FirebaseAuth.instance.signOut();
        throw 'Only VIT student emails allowed';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black54,
              Color(0xFF7B1FA2),
              Colors.purple,
              Colors.black,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 14,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5A8), Color(0xFF4FC3F7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.directions_car,
                            size: 44,
                            color: Colors.black,
                          ),

                          // V overlay
                          Positioned(
                            bottom: 18,
                            child: Text(
                              'V',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                shadows: [
                                  Shadow(
                                    color: Colors.white.withOpacity(0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'VPool',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'VIT Airport Carpool',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 30),

                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'VIT Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => isPasswordVisible = !isPasswordVisible,
                          ),
                        ),
                      ),
                    ),

                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(error, style: const TextStyle(color: Colors.red)),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: signInWithGoogle,
                      icon: Image.asset('assets/google.png', height: 20),
                      label: const Text(
                        'Sign in with VIT Mail ID',
                        style: TextStyle(fontSize: 15),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OwnerRequestsPage extends StatelessWidget {
  const OwnerRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ride Requests",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('ownerEmail', isEqualTo: user!.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView.builder(
              itemCount: 6,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            );
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                "No pending requests",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];

              return Card(
                child: ListTile(
                  title: Text(req['requesterEmail']),
                  subtitle: Text(
                    "Wants to join your ride",
                    style: TextStyle(color: Colors.white),
                  ),
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

  Future<void> approve(String requestId, String rideId) async {
    final rideRef = FirebaseFirestore.instance.collection('rides').doc(rideId);
    final reqRef = FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final rideSnap = await tx.get(rideRef);
      final reqSnap = await tx.get(reqRef);

      final seats = rideSnap['seats'];
      final status = reqSnap['status'];
      final requester = reqSnap['requesterEmail'];

      // Stop double-approval
      if (status != 'pending') return;

      if (seats <= 0) {
        tx.update(reqRef, {'status': 'rejected'});
        return;
      }

      tx.update(rideRef, {
        'seats': seats - 1,
        'passengers': FieldValue.arrayUnion([requester]),
      });

      tx.update(reqRef, {'status': 'approved'});
    });
  }

  Future<void> reject(String requestId) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }
}

class MyRidesPage extends StatelessWidget {
  const MyRidesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                  MyPostedRides(user!.email!),
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
          return ListView.builder(
            itemCount: 6,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          );
        }
        final rides = snapshot.data!.docs;

        if (rides.isEmpty) {
          return const Center(
            child: Text(
              "You haven’t posted any rides",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView(
          children: rides.map((ride) {
            return ListTile(
              title: Text(
                "${ride['from']} → ${ride['to']}",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                "${ride['date']} at ${ride['time']}",
                style: TextStyle(color: Colors.white),
              ),
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
          return ListView.builder(
            itemCount: 6,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          );
        }
        final reqs = snapshot.data!.docs;

        if (reqs.isEmpty) {
          return const Center(
            child: Text(
              "No requests sent",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView(
          children: reqs.map((r) {
            return ListTile(
              title: Text(
                "Ride: ${r['rideId']}",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                "Status: ${r['status']}",
                style: TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

Map<String, String> parseVitEmail(String email) {
  final local = email.split('@')[0];
  final namePart = local.replaceAll(RegExp(r'\d'), '');
  final yearPart = local.replaceAll(RegExp(r'\D'), '');

  final names = namePart.split('.');
  final first = names.isNotEmpty ? names[0] : '';
  final last = names.length > 1 ? names[1] : '';

  return {
    'name':
        "${first[0].toUpperCase()}${first.substring(1)} ${last[0].toUpperCase()}${last.substring(1)}",
    'batch': yearPart,
  };
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
          return ListView.builder(
            itemCount: 6,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          );
        }
        final rides = snapshot.data!.docs;

        if (rides.isEmpty) {
          return const Center(
            child: Text(
              "No confirmed rides",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView(
          children: rides.map((ride) {
            return ListTile(
              title: Text(
                "${ride['from']} → ${ride['to']}",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                "${ride['date']} at ${ride['time']}",
                style: TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class FilterBar extends StatefulWidget {
  const FilterBar({super.key});

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  final locations = [
    "Any",
    "VIT",
    "Katpadi Station",
    "Chennai Airport",
    "Bangalore Airport",
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A22).withOpacity(0.9),
          boxShadow: [
            BoxShadow(blurRadius: 30, color: Colors.black.withOpacity(0.6)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: RideFilter.from,
                    dropdownColor: const Color(0xFF1A1A22),
                    style: const TextStyle(color: Colors.white),
                    items: locations
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        RideFilter.from = v!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "From",
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: RideFilter.to,
                    dropdownColor: const Color(0xFF1A1A22),
                    style: const TextStyle(color: Colors.white),
                    items: locations
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        RideFilter.to = v!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "To",
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            ListTile(
              title: Text(
                RideFilter.date == null
                    ? "Select date"
                    : "${RideFilter.date!.year}-${RideFilter.date!.month.toString().padLeft(2, '0')}-${RideFilter.date!.day.toString().padLeft(2, '0')}",
                style: const TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.calendar_today, color: Colors.white70),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2027),
                  initialDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    RideFilter.date = picked;
                  });
                }
              },
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text(
                  "Search rides",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  searchNotifier.value++;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RideList extends StatelessWidget {
  const RideList({super.key});

  @override
  Widget build(BuildContext context) {
    final _ = searchNotifier.value; // 👈 makes widget depend on notifier

    // force rebuild when search button is pressed

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
          return ListView.builder(
            itemCount: 6,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          );
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
                  child: const Text(
                    "Be the first — create a ride",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 350),
                        pageBuilder: (_, __, ___) => CreateRidePage(),
                        transitionsBuilder: (_, anim, __, child) {
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(0, 0.08),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          );
                        },
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
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 350),
                      pageBuilder: (_, __, ___) =>
                          RideDetailsPage(rideId: ride.id),
                      transitionsBuilder: (_, anim, __, child) {
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.08),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        );
                      },
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5A8).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Color(0xFF00E5A8),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${ride['from']} → ${ride['to']}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${ride['date']} at ${ride['time']}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${ride['seats']} seats",
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

String getNameFromEmail(String email) {
  // ekansh.yadav2024@vitstudent.ac.in
  final local = email.split('@')[0];
  final namePart = local.replaceAll(RegExp(r'\d'), '');
  final parts = namePart.split('.');

  final first = parts.isNotEmpty ? parts[0] : '';
  final last = parts.length > 1 ? parts[1] : '';

  return "${capitalize(first)} ${capitalize(last)}".trim();
}

String getBatchFromEmail(String email) {
  final local = email.split('@')[0];
  final match = RegExp(r'\d{4}').firstMatch(local);
  return match != null ? match.group(0)! : "—";
}

String capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final email = user.email!;
    final name = getNameFromEmail(email);
    final batch = getBatchFromEmail(email);

    final postedStream = FirebaseFirestore.instance
        .collection('rides')
        .where('owner', isEqualTo: email)
        .snapshots();

    final joinedStream = FirebaseFirestore.instance
        .collection('rides')
        .where('passengers', arrayContains: email)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF00E5A8),
              child: Text(
                name.isNotEmpty ? name[0] : "V",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text("Batch $batch", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(color: Colors.white54)),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCard(title: "Posted", stream: postedStream),
                _StatCard(title: "Joined", stream: joinedStream),
              ],
            ),

            const SizedBox(height: 30),

            _SectionTitle("Connect"),
            _ProfileTile(
              icon: Icons.link,
              title: "LinkedIn",
              onTap: () => launchUrl(
                Uri.parse("https://www.linkedin.com/in/ekansh-yadav/"),
                mode: LaunchMode.externalApplication,
              ),
            ),
            _ProfileTile(
              icon: Icons.code,
              title: "GitHub Project",
              onTap: () => launchUrl(
                Uri.parse("https://github.com/ekansh323/vpool"),
                mode: LaunchMode.externalApplication,
              ),
            ),

            const SizedBox(height: 20),

            _SectionTitle("Feedback"),
            _ProfileTile(
              icon: Icons.feedback,
              title: "Send feedback / report bug",
              onTap: () => launchUrl(
                Uri.parse("https://github.com/YOUR_REPO/issues"),
                mode: LaunchMode.externalApplication,
              ),
            ),

            const SizedBox(height: 30),

            _ProfileTile(
              icon: Icons.logout,
              title: "Logout",
              isDestructive: true,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}


class _StatCard extends StatelessWidget {
  final String title;
  final Stream<QuerySnapshot> stream;

  const _StatCard({required this.title, required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (_, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white70)),
          ],
        );
      },
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.redAccent : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.redAccent : Colors.white,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
