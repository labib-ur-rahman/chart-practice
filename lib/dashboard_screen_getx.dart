import 'package:dashboard/controllers/dashboard_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardScreenGetx extends StatelessWidget {
  const DashboardScreenGetx({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(DashboardController());

    return Scaffold(
      appBar: AppBar(title: const Text('User Analytics'), elevation: 2),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(controller),
              const SizedBox(height: 24),
              _buildChart(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(DashboardController controller) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'User Trends',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Row(
            children: [
              _buildLegend(),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: controller.selectedMonthRange.value,
                items: const [
                  DropdownMenuItem(value: 3, child: Text('Last 3 Months')),
                  DropdownMenuItem(value: 6, child: Text('Last 6 Months')),
                  DropdownMenuItem(value: 12, child: Text('Last 12 Months')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.setMonthRange(value);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _legendItem(const Color(0xff23b6e6), 'Verified'),
        const SizedBox(width: 12),
        _legendItem(const Color(0xfff8b250), 'Unverified'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildChart(DashboardController controller) {
    return Obx(
      () => AspectRatio(
        aspectRatio: 1.23,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, left: 6),
                    child: _LineChart(controller: controller),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: controller.isShowingMainData.value
                      ? Colors.blue
                      : Colors.grey,
                ),
                onPressed: () => controller.toggleDataView(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => LineChart(
        controller.isShowingMainData.value ? mainData : monthlyData,
        duration: const Duration(milliseconds: 250),
      ),
    );
  }

  LineChartData get mainData => LineChartData(
    lineTouchData: lineTouchData,
    gridData: gridData,
    titlesData: titlesData,
    borderData: borderData,
    lineBarsData: mainLineBarsData,
    minX: 0,
    maxX: (controller.visibleMonths.length - 1).toDouble(),
    maxY: _calculateMaxY() + 2,
    minY: 0,
  );

  LineChartData get monthlyData => LineChartData(
    lineTouchData: lineTouchData,
    gridData: gridData,
    titlesData: titlesData,
    borderData: borderData,
    lineBarsData: monthlyLineBarsData,
    minX: 0,
    maxX: (controller.visibleMonths.length - 1).toDouble(),
    maxY: _calculateMonthlyMaxY() + 2,
    minY: 0,
  );

  double _calculateMaxY() {
    if (controller.visibleVerified.isEmpty) return 10;
    final maxVerified = controller.visibleVerified.reduce(
      (a, b) => a > b ? a : b,
    );
    final maxUnverified = controller.visibleUnverified.reduce(
      (a, b) => a > b ? a : b,
    );
    return (maxVerified > maxUnverified ? maxVerified : maxUnverified)
        .toDouble();
  }

  double _calculateMonthlyMaxY() {
    if (controller.visibleVerified.isEmpty) return 10;
    var maxMonthly = 0;
    for (var i = 0; i < controller.visibleVerified.length; i++) {
      final globalIdx = controller.startIndex + i;
      final vMonthly = globalIdx == 0
          ? controller.verifiedCounts[globalIdx]
          : controller.verifiedCounts[globalIdx] -
                controller.verifiedCounts[globalIdx - 1];
      final uMonthly = globalIdx == 0
          ? controller.unverifiedCounts[globalIdx]
          : controller.unverifiedCounts[globalIdx] -
                controller.unverifiedCounts[globalIdx - 1];
      if (vMonthly > maxMonthly) maxMonthly = vMonthly;
      if (uMonthly > maxMonthly) maxMonthly = uMonthly;
    }
    return maxMonthly.toDouble();
  }

  LineTouchData get lineTouchData => LineTouchData(
    handleBuiltInTouches: true,
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (touchedSpot) => Colors.blueGrey.withValues(alpha: 0.8),
      getTooltipItems: (touchedSpots) {
        return touchedSpots.map((spot) {
          final idx = spot.x.toInt();
          if (idx < 0 || idx >= controller.visibleMonths.length) {
            return null;
          }
          final month = controller.visibleMonths[idx];
          const months = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
          final label = '${months[month.month - 1]} ${month.year}';
          return LineTooltipItem(
            '$label\n${spot.y.toInt()}',
            const TextStyle(color: Colors.white, fontSize: 12),
          );
        }).toList();
      },
    ),
  );

  FlTitlesData get titlesData => FlTitlesData(
    bottomTitles: AxisTitles(sideTitles: bottomTitles),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(sideTitles: leftTitles()),
  );

  List<LineChartBarData> get mainLineBarsData {
    final verifiedSpots = <FlSpot>[];
    final unverifiedSpots = <FlSpot>[];

    for (var i = 0; i < controller.visibleMonths.length; i++) {
      final globalIdx = controller.startIndex + i;
      verifiedSpots.add(
        FlSpot(i.toDouble(), controller.verifiedCounts[globalIdx].toDouble()),
      );
      unverifiedSpots.add(
        FlSpot(i.toDouble(), controller.unverifiedCounts[globalIdx].toDouble()),
      );
    }

    return [
      LineChartBarData(
        isCurved: true,
        color: const Color(0xff23b6e6),
        barWidth: 8,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: const Color(0xff23b6e6).withValues(alpha: 0.3),
        ),
        spots: verifiedSpots,
      ),
      LineChartBarData(
        isCurved: true,
        color: const Color(0xfff8b250),
        barWidth: 8,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: const Color(0xfff8b250).withValues(alpha: 0.3),
        ),
        spots: unverifiedSpots,
      ),
    ];
  }

  List<LineChartBarData> get monthlyLineBarsData {
    final verifiedSpots = <FlSpot>[];
    final unverifiedSpots = <FlSpot>[];

    for (var i = 0; i < controller.visibleMonths.length; i++) {
      final globalIdx = controller.startIndex + i;
      final vMonthly = globalIdx == 0
          ? controller.verifiedCounts[globalIdx]
          : controller.verifiedCounts[globalIdx] -
                controller.verifiedCounts[globalIdx - 1];
      final uMonthly = globalIdx == 0
          ? controller.unverifiedCounts[globalIdx]
          : controller.unverifiedCounts[globalIdx] -
                controller.unverifiedCounts[globalIdx - 1];

      verifiedSpots.add(FlSpot(i.toDouble(), vMonthly.toDouble()));
      unverifiedSpots.add(FlSpot(i.toDouble(), uMonthly.toDouble()));
    }

    return [
      LineChartBarData(
        isCurved: true,
        curveSmoothness: 0,
        color: const Color(0xff23b6e6).withValues(alpha: 0.5),
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
        spots: verifiedSpots,
      ),
      LineChartBarData(
        isCurved: true,
        color: const Color(0xfff8b250).withValues(alpha: 0.5),
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: const Color(0xfff8b250).withValues(alpha: 0.2),
        ),
        spots: unverifiedSpots,
      ),
    ];
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);

    if (value == 0) return Container();

    return SideTitleWidget(
      meta: meta,
      child: Text(
        value.toInt().toString(),
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }

  SideTitles leftTitles() => SideTitles(
    getTitlesWidget: leftTitleWidgets,
    showTitles: true,
    interval: _calculateMaxY() / 4,
    reservedSize: 40,
  );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);

    final i = value.toInt();
    if (i < 0 || i >= controller.visibleMonths.length) {
      return const Text('');
    }

    // Show every Nth label based on visible months
    final interval = controller.visibleMonths.length > 6
        ? (controller.visibleMonths.length / 4).floor()
        : 1;
    if (i % interval != 0 && i != controller.visibleMonths.length - 1) {
      return const Text('');
    }

    final month = controller.visibleMonths[i];
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final label = months[month.month - 1];

    return SideTitleWidget(
      meta: meta,
      space: 10,
      child: Text(label, style: style),
    );
  }

  SideTitles get bottomTitles => SideTitles(
    showTitles: true,
    reservedSize: 32,
    interval: 1,
    getTitlesWidget: bottomTitleWidgets,
  );

  FlGridData get gridData => const FlGridData(show: false);

  FlBorderData get borderData => FlBorderData(
    show: true,
    border: Border(
      bottom: BorderSide(color: Colors.blue.withValues(alpha: 0.2), width: 4),
      left: const BorderSide(color: Colors.transparent),
      right: const BorderSide(color: Colors.transparent),
      top: const BorderSide(color: Colors.transparent),
    ),
  );
}
