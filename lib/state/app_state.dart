import 'package:flutter/material.dart';

final ValueNotifier<int> searchNotifier = ValueNotifier(0);

class RideFilter {
  static String from = "Any";
  static String to = "Any";
  static DateTime? date;
}
