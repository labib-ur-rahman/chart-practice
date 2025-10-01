import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';

class DashboardController extends GetxController {
  // Observable state
  var isLoading = true.obs;
  var months = <DateTime>[].obs;
  var verifiedCounts = <int>[].obs;
  var unverifiedCounts = <int>[].obs;
  var selectedMonthRange = 6.obs; // 3, 6, or 12 months
  var isShowingMainData = true.obs; // toggle between cumulative and monthly

  @override
  void onInit() {
    super.onInit();
    loadAndProcessData();
  }

  Future<void> loadAndProcessData() async {
    try {
      isLoading.value = true;

      // Load JSON from assets
      final raw = await rootBundle.loadString('lib/users.json');
      final Map<String, dynamic> data = json.decode(raw);

      // Extract timestamps and verification status
      final users = data.values
          .map(
            (e) => {
              'createdAt': (e['createdAt'] as num).toInt(),
              'isVerified': e['isVerified'] as bool,
            },
          )
          .toList();

      if (users.isEmpty) {
        isLoading.value = false;
        return;
      }

      // Convert timestamps to DateTime and group by month
      List<DateTime> dates = users
          .map(
            (u) => DateTime.fromMillisecondsSinceEpoch(
              u['createdAt'] as int,
              isUtc: true,
            ),
          )
          .toList();

      dates.sort();

      // Build list of month buckets from startMonth..endMonth
      DateTime start = DateTime(dates.first.year, dates.first.month, 1);
      DateTime end = DateTime(dates.last.year, dates.last.month, 1);

      final monthsList = <DateTime>[];
      for (
        var m = start;
        !m.isAfter(end);
        m = DateTime(m.year, m.month + 1, 1)
      ) {
        monthsList.add(m);
      }

      // Count verified/unverified per month
      final verifiedList = List<int>.filled(monthsList.length, 0);
      final unverifiedList = List<int>.filled(monthsList.length, 0);

      // Map each user's date to month index and increment
      for (var u in users) {
        final dt = DateTime.fromMillisecondsSinceEpoch(
          u['createdAt'] as int,
          isUtc: true,
        );
        final month = DateTime(dt.year, dt.month, 1);
        final idx = monthsList.indexWhere(
          (m) => m.year == month.year && m.month == month.month,
        );
        if (idx >= 0) {
          if (u['isVerified'] as bool) {
            verifiedList[idx] += 1;
          } else {
            unverifiedList[idx] += 1;
          }
        }
      }

      // Make cumulative (running total across months)
      for (var i = 1; i < monthsList.length; i++) {
        verifiedList[i] += verifiedList[i - 1];
        unverifiedList[i] += unverifiedList[i - 1];
      }

      // Update observables
      months.value = monthsList;
      verifiedCounts.value = verifiedList;
      unverifiedCounts.value = unverifiedList;
      isLoading.value = false;
    } catch (e) {
      // Error loading data
      isLoading.value = false;
    }
  }

  // Get visible data based on selected month range
  List<DateTime> get visibleMonths {
    if (months.isEmpty) return [];
    final startIndex = (months.length - selectedMonthRange.value).clamp(
      0,
      months.length,
    );
    return months.sublist(startIndex);
  }

  List<int> get visibleVerified {
    if (verifiedCounts.isEmpty) return [];
    final startIndex = (months.length - selectedMonthRange.value).clamp(
      0,
      months.length,
    );
    return verifiedCounts.sublist(startIndex);
  }

  List<int> get visibleUnverified {
    if (unverifiedCounts.isEmpty) return [];
    final startIndex = (months.length - selectedMonthRange.value).clamp(
      0,
      months.length,
    );
    return unverifiedCounts.sublist(startIndex);
  }

  int get startIndex {
    if (months.isEmpty) return 0;
    return (months.length - selectedMonthRange.value).clamp(0, months.length);
  }

  void toggleDataView() {
    isShowingMainData.value = !isShowingMainData.value;
  }

  void setMonthRange(int range) {
    selectedMonthRange.value = range;
  }
}
