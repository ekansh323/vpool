import 'package:flutter/material.dart';
import '../state/app_state.dart';

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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: RideFilter.from,
                items: locations
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    RideFilter.from = v!;
                  });
                },
                decoration: const InputDecoration(labelText: "From"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: RideFilter.to,
                items: locations
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    RideFilter.to = v!;
                  });
                },
                decoration: const InputDecoration(labelText: "To"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListTile(
          title: Text(
            RideFilter.date == null
                ? "Select date"
                : "${RideFilter.date!.year}-${RideFilter.date!.month.toString().padLeft(2, '0')}-${RideFilter.date!.day.toString().padLeft(2, '0')}",
          ),
          trailing: const Icon(Icons.calendar_today),
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
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text("Search rides"),
            onPressed: () {
              searchNotifier.value++;
            },
          ),
        ),
      ],
    );
  }
}
