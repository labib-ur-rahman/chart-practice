import 'package:dashboard/controllers/chart_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChartController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'User Analytics Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Summary Cards
            _buildSummaryCards(controller),
            // Tab Bar
            _buildTabBar(controller),
            // Chart Content
            Expanded(child: _buildChartContent(controller)),
          ],
        );
      }),
    );
  }

  Widget _buildSummaryCards(ChartController controller) {
    return Obx(
      () => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Users',
                controller.totalUsers.value.toString(),
                Icons.people,
                Colors.blue,
                Colors.blue[50]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Verified',
                '${controller.totalVerified.value} (${controller.verifiedPercentage.toStringAsFixed(1)}%)',
                Icons.verified_user,
                Colors.green,
                Colors.green[50]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Unverified',
                '${controller.totalUnverified.value} (${controller.unverifiedPercentage.toStringAsFixed(1)}%)',
                Icons.person_off,
                Colors.orange,
                Colors.orange[50]!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ChartController controller) {
    return Obx(
      () => Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  _buildTabButton(
                    controller,
                    0,
                    'Line Chart',
                    Icons.show_chart,
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(controller, 1, 'Bar Chart', Icons.bar_chart),
                  const SizedBox(width: 8),
                  _buildTabButton(controller, 2, 'Pie Chart', Icons.pie_chart),
                ],
              ),
            ),
            const SizedBox(width: 16),
            DropdownButton<int>(
              value: controller.selectedMonthRange.value,
              underline: Container(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
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
      ),
    );
  }

  Widget _buildTabButton(
    ChartController controller,
    int index,
    String label,
    IconData icon,
  ) {
    final isSelected = controller.currentTabIndex.value == index;
    return Expanded(
      child: InkWell(
        onTap: () => controller.setTabIndex(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartContent(ChartController controller) {
    return Obx(() {
      switch (controller.currentTabIndex.value) {
        case 0:
          return _LineChartWidget(controller: controller);
        case 1:
          return _BarChartWidget(controller: controller);
        case 2:
          return _PieChartWidget(controller: controller);
        default:
          return const SizedBox();
      }
    });
  }
}

// LINE CHART WIDGET
class _LineChartWidget extends StatelessWidget {
  final ChartController controller;

  const _LineChartWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Growth Trends',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cumulative user registrations over time',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  _buildLegend(),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: LineChart(
                  _buildLineChartData(),
                  duration: const Duration(milliseconds: 250),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _legendItem(const Color(0xff7B61FF), 'Verified'),
        const SizedBox(width: 16),
        _legendItem(const Color(0xff4DB8FF), 'Unverified'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  LineChartData _buildLineChartData() {
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

    final maxY = _calculateMaxY();

    return LineChartData(
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) =>
              Colors.blueGrey.withValues(alpha: 0.9),
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
                '$label\n${spot.y.toInt()} users',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 5,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey[200]!, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 1,
            getTitlesWidget: _bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxY / 5,
            reservedSize: 40,
            getTitlesWidget: _leftTitleWidgets,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
          left: BorderSide(color: Colors.grey[300]!, width: 1),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      ),
      minX: 0,
      maxX: (controller.visibleMonths.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        // Unverified (blue) - drawn first so verified overlays
        LineChartBarData(
          spots: unverifiedSpots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: const Color(0xff4DB8FF),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xff4DB8FF).withValues(alpha: 0.4),
                const Color(0xff4DB8FF).withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
        // Verified (purple)
        LineChartBarData(
          spots: verifiedSpots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: const Color(0xff7B61FF),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xff7B61FF).withValues(alpha: 0.5),
                const Color(0xff7B61FF).withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _calculateMaxY() {
    if (controller.visibleVerified.isEmpty) return 100;
    final maxVerified = controller.visibleVerified.reduce(
      (a, b) => a > b ? a : b,
    );
    final maxUnverified = controller.visibleUnverified.reduce(
      (a, b) => a > b ? a : b,
    );
    final max = maxVerified > maxUnverified ? maxVerified : maxUnverified;
    return (max * 1.2).ceilToDouble();
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final i = value.toInt();
    if (i < 0 || i >= controller.visibleMonths.length) {
      return const SizedBox();
    }

    final interval = controller.visibleMonths.length > 6
        ? (controller.visibleMonths.length / 4).floor()
        : 1;
    if (i % interval != 0 && i != controller.visibleMonths.length - 1) {
      return const SizedBox();
    }

    final month = controller.visibleMonths[i];
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

    return SideTitleWidget(
      meta: meta,
      child: Text(
        months[month.month - 1],
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      child: Text(
        value.toInt().toString(),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// BAR CHART WIDGET
class _BarChartWidget extends StatelessWidget {
  final ChartController controller;

  const _BarChartWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly User Registrations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'New users per month',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  _buildLegend(),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: BarChart(
                  _buildBarChartData(),
                  duration: const Duration(milliseconds: 250),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _legendItem(const Color(0xff7B61FF), 'Verified'),
        const SizedBox(width: 16),
        _legendItem(const Color(0xff4DB8FF), 'Unverified'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  BarChartData _buildBarChartData() {
    final barGroups = <BarChartGroupData>[];

    for (var i = 0; i < controller.visibleMonths.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: controller.visibleVerifiedMonthly[i].toDouble(),
              color: const Color(0xff7B61FF),
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: controller.visibleUnverifiedMonthly[i].toDouble(),
              color: const Color(0xff4DB8FF),
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
          barsSpace: 4,
        ),
      );
    }

    final maxY = _calculateMaxY();

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      minY: 0,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => Colors.blueGrey.withValues(alpha: 0.9),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final month = controller.visibleMonths[groupIndex];
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
            final type = rodIndex == 0 ? 'Verified' : 'Unverified';
            return BarTooltipItem(
              '$label\n$type: ${rod.toY.toInt()}',
              const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: _bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxY / 5,
            reservedSize: 40,
            getTitlesWidget: _leftTitleWidgets,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
          left: BorderSide(color: Colors.grey[300]!, width: 1),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 5,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey[200]!, strokeWidth: 1),
      ),
      barGroups: barGroups,
    );
  }

  double _calculateMaxY() {
    if (controller.visibleVerifiedMonthly.isEmpty) return 20;
    final allValues = [
      ...controller.visibleVerifiedMonthly,
      ...controller.visibleUnverifiedMonthly,
    ];
    final max = allValues.reduce((a, b) => a > b ? a : b);
    return (max * 1.3).ceilToDouble();
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final i = value.toInt();
    if (i < 0 || i >= controller.visibleMonths.length) {
      return const SizedBox();
    }

    final month = controller.visibleMonths[i];
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

    return SideTitleWidget(
      meta: meta,
      child: Text(
        months[month.month - 1],
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      child: Text(
        value.toInt().toString(),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// PIE CHART WIDGET
class _PieChartWidget extends StatelessWidget {
  final ChartController controller;

  const _PieChartWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'User Distribution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Verified vs Unverified users',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 280,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: PieChart(
                        _buildPieChartData(),
                        duration: const Duration(milliseconds: 250),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _buildPieLegend()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          const Color(0xff7B61FF),
          'Verified Users',
          controller.totalVerified.value,
          controller.verifiedPercentage,
        ),
        const SizedBox(height: 20),
        _buildLegendItem(
          const Color(0xff4DB8FF),
          'Unverified Users',
          controller.totalUnverified.value,
          controller.unverifiedPercentage,
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    Color color,
    String label,
    int count,
    double percentage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count users',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  PieChartData _buildPieChartData() {
    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 60,
      sections: [
        PieChartSectionData(
          color: const Color(0xff7B61FF),
          value: controller.totalVerified.value.toDouble(),
          title: '${controller.verifiedPercentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: _buildBadge(
            Icons.verified_user,
            const Color(0xff7B61FF),
          ),
          badgePositionPercentageOffset: 1.3,
        ),
        PieChartSectionData(
          color: const Color(0xff4DB8FF),
          value: controller.totalUnverified.value.toDouble(),
          title: '${controller.unverifiedPercentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: _buildBadge(Icons.person_off, const Color(0xff4DB8FF)),
          badgePositionPercentageOffset: 1.3,
        ),
      ],
      pieTouchData: PieTouchData(
        touchCallback: (FlTouchEvent event, pieTouchResponse) {},
      ),
    );
  }

  Widget _buildBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
