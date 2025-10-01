import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';

class ChartController extends GetxController {
  // Observable state
  var isLoading = true.obs;
  var selectedMonthRange = 6.obs; // 3, 6, or 12 months
  var currentTabIndex = 0.obs;

  // Data arrays
  var months = <DateTime>[].obs;
  var verifiedCounts = <int>[].obs;
  var unverifiedCounts = <int>[].obs;

  // Summary data
  var totalVerified = 0.obs;
  var totalUnverified = 0.obs;
  var totalUsers = 0.obs;

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

      // Extract users array
      final List<dynamic> usersData = data['users'] as List<dynamic>;

      if (usersData.isEmpty) {
        isLoading.value = false;
        return;
      }

      // Convert timestamps to DateTime and group by month
      List<DateTime> dates = usersData
          .map(
            (user) => DateTime.fromMillisecondsSinceEpoch(
              user['createdAt'] as int,
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

      int totalV = 0;
      int totalU = 0;

      // Map each user's date to month index and increment
      for (var user in usersData) {
        final dt = DateTime.fromMillisecondsSinceEpoch(
          user['createdAt'] as int,
          isUtc: true,
        );
        final month = DateTime(dt.year, dt.month, 1);
        final idx = monthsList.indexWhere(
          (m) => m.year == month.year && m.month == month.month,
        );

        final isVerified = user['isVerified'] as bool;

        if (idx >= 0) {
          if (isVerified) {
            verifiedList[idx] += 1;
            totalV++;
          } else {
            unverifiedList[idx] += 1;
            totalU++;
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
      totalVerified.value = totalV;
      totalUnverified.value = totalU;
      totalUsers.value = totalV + totalU;
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

  // Get monthly increments (not cumulative) for bar chart
  List<int> get visibleVerifiedMonthly {
    final result = <int>[];
    for (var i = 0; i < visibleMonths.length; i++) {
      final globalIdx = startIndex + i;
      final monthly = globalIdx == 0
          ? verifiedCounts[globalIdx]
          : verifiedCounts[globalIdx] - verifiedCounts[globalIdx - 1];
      result.add(monthly);
    }
    return result;
  }

  List<int> get visibleUnverifiedMonthly {
    final result = <int>[];
    for (var i = 0; i < visibleMonths.length; i++) {
      final globalIdx = startIndex + i;
      final monthly = globalIdx == 0
          ? unverifiedCounts[globalIdx]
          : unverifiedCounts[globalIdx] - unverifiedCounts[globalIdx - 1];
      result.add(monthly);
    }
    return result;
  }

  void setMonthRange(int range) {
    selectedMonthRange.value = range;
  }

  void setTabIndex(int index) {
    currentTabIndex.value = index;
  }

  double get verifiedPercentage {
    if (totalUsers.value == 0) return 0;
    return (totalVerified.value / totalUsers.value) * 100;
  }

  double get unverifiedPercentage {
    if (totalUsers.value == 0) return 0;
    return (totalUnverified.value / totalUsers.value) * 100;
  }
}
