import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        const SnackBar(content: Text("Enter a valid 10-digit WhatsApp number")),
      );
      return;
    }

    if (date == null || time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select date and time")),
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
      'passengers': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
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
                    : const Text("Post Ride"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
