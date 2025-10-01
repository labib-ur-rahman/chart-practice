import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  List<DateTime> _days = [];
  List<int> _verified = [];
  List<int> _unverified = [];
  // gradient colors for the two series
  // purple (verified) and blue (unverified) gradients to match example
  final List<Color> _verifiedGradient = [Color(0xff7B61FF), Color(0xffB78BFF)];
  final List<Color> _unverifiedGradient = [
    Color(0xff4DB8FF),
    Color(0xff67D8FF),
  ];
  bool _showDaily = false;
  // show last N months in the chart, null = all
  int? _monthsToShow = 6;

  @override
  void initState() {
    super.initState();
    _loadAndProcess();
  }

  Future<void> _loadAndProcess() async {
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
      setState(() {
        _loading = false;
      });
      return;
    }

    // Convert timestamps to DateTime (UTC) and group by month
    List<DateTime> dates = users
        .map(
          (u) => DateTime.fromMillisecondsSinceEpoch(
            u['createdAt'] as int,
            isUtc: true,
          ).toLocal(),
        )
        .toList();

    dates.sort();

    // Build list of month buckets from startMonth..endMonth (each item is first day of month)
    DateTime start = DateTime(dates.first.year, dates.first.month, 1);
    DateTime end = DateTime(dates.last.year, dates.last.month, 1);

    final months = <DateTime>[];
    for (var m = start; !m.isAfter(end); m = DateTime(m.year, m.month + 1, 1)) {
      months.add(m);
    }

    // Count cumulative verified/unverified per month
    final verifiedCounts = List<int>.filled(months.length, 0);
    final unverifiedCounts = List<int>.filled(months.length, 0);

    // Map each user's date to month index and increment
    for (var u in users) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        u['createdAt'] as int,
        isUtc: true,
      ).toLocal();
      final month = DateTime(dt.year, dt.month, 1);
      final idx = months.indexWhere(
        (m) => m.year == month.year && m.month == month.month,
      );
      if (idx >= 0) {
        if (u['isVerified'] as bool) {
          verifiedCounts[idx] += 1;
        } else {
          unverifiedCounts[idx] += 1;
        }
      }
    }

    // Make cumulative (running total across months)
    for (var i = 1; i < months.length; i++) {
      verifiedCounts[i] += verifiedCounts[i - 1];
      unverifiedCounts[i] += unverifiedCounts[i - 1];
    }

    setState(() {
      _days =
          months; // reuse _days variable name but now it holds first-day-of-month buckets
      _verified = verifiedCounts;
      _unverified = unverifiedCounts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users - Verified vs Unverified')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with title, dropdown and legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sale Trends',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          _buildHeaderLegend(),
                          const SizedBox(width: 12),
                          DropdownButton<int?>(
                            value: _monthsToShow,
                            items: const [
                              DropdownMenuItem(
                                value: 6,
                                child: Text('Last 6 Months'),
                              ),
                              DropdownMenuItem(
                                value: 12,
                                child: Text('Last 12 Months'),
                              ),
                              DropdownMenuItem(value: null, child: Text('All')),
                            ],
                            onChanged: (v) => setState(() => _monthsToShow = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Card-like container for the chart
                  Expanded(
                    child: Card(
                      color: Theme.of(context).colorScheme.surface,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Stack(
                          children: [
                            AspectRatio(aspectRatio: 1.7, child: _buildChart()),
                            Positioned(
                              right: 6,
                              top: 6,
                              child: SizedBox(
                                width: 100,
                                height: 36,
                                child: TextButton(
                                  onPressed: () =>
                                      setState(() => _showDaily = !_showDaily),
                                  child: Text(
                                    _showDaily ? 'Monthly' : 'Cumulative',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderLegend() {
    return Row(
      children: [
        _legendItem(_verifiedGradient[0], 'Verified'),
        const SizedBox(width: 12),
        _legendItem(_unverifiedGradient[0], 'Unverified'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 18, height: 6, color: color),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }

  Widget _buildChart() {
    if (_days.isEmpty) {
      return const Center(child: Text('No data'));
    }

    // Map days to x values 0..n-1
    final spotsVerified = <FlSpot>[];
    final spotsUnverified = <FlSpot>[];

    // compute daily or cumulative values depending on _showDaily
    for (var i = 0; i < _days.length; i++) {
      final vCumulative = _verified[i];
      final uCumulative = _unverified[i];
      final vDaily = i == 0 ? vCumulative : vCumulative - _verified[i - 1];
      final uDaily = i == 0 ? uCumulative : uCumulative - _unverified[i - 1];
      final vVal = _showDaily ? vDaily.toDouble() : vCumulative.toDouble();
      final uVal = _showDaily ? uDaily.toDouble() : uCumulative.toDouble();
      spotsVerified.add(FlSpot(i.toDouble(), vVal));
      spotsUnverified.add(FlSpot(i.toDouble(), uVal));
    }

    // determine visible range based on _monthsToShow
    final startIndex = (_monthsToShow == null)
        ? 0
        : (_days.length - (_monthsToShow!.clamp(0, _days.length)));
    final visibleDays = _days.sublist(startIndex);
    final visibleVerified = _verified.sublist(startIndex);
    final visibleUnverified = _unverified.sublist(startIndex);

    final maxY = ([
      ...visibleVerified,
      ...visibleUnverified,
    ].fold<int>(0, (p, e) => e > p ? e : p)).toDouble();

    // helper getters used by title widgets
    int chartMaxY() => maxY.ceil();
    int bottomInterval() =>
        visibleDays.length > 6 ? (visibleDays.length / 6).floor() : 1;

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((t) {
                final idx = t.x.toInt();
                final day = _days[idx];
                final label = '${day.month}/${day.day}';
                return LineTooltipItem(
                  '$label\n${t.y.toInt()}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: Color(0xff37434d), strokeWidth: 1),
          getDrawingVerticalLine: (value) =>
              const FlLine(color: Color(0xff37434d), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: bottomInterval().toDouble(),
              getTitlesWidget: (value, meta) =>
                  bottomTitleWidgets(value, meta, startIndex),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (chartMaxY() / 4).ceilToDouble(),
              reservedSize: 42,
              getTitlesWidget: (value, meta) => leftTitleWidgets(value, meta),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d)),
        ),
        minX: 0,
        maxX: (_days.length - 1).toDouble(),
        minY: 0,
        maxY: maxY + 1,
        lineBarsData: [
          // draw unverified (blue) first so verified purple overlays it like the screenshot
          LineChartBarData(
            spots: spotsUnverified.sublist(startIndex),
            isCurved: true,
            gradient: LinearGradient(colors: _unverifiedGradient),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: _unverifiedGradient
                    .map((c) => c.withValues(alpha: 0.35))
                    .toList(),
              ),
            ),
          ),
          LineChartBarData(
            spots: spotsVerified.sublist(startIndex),
            isCurved: true,
            gradient: LinearGradient(colors: _verifiedGradient),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: _verifiedGradient
                    .map((c) => c.withValues(alpha: 0.45))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta, int startIndex) {
    final i = value.toInt();
    final visibleDays = _days.sublist(startIndex);
    if (i < 0 || i >= visibleDays.length) return const SizedBox.shrink();
    // show up to 6 labels evenly spaced on visible range
    final interval = visibleDays.length > 6
        ? (visibleDays.length / 6).floor()
        : 1;
    if (i % interval != 0 && i != visibleDays.length - 1) {
      return const SizedBox.shrink();
    }
    final d = visibleDays[i];
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
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
    final label = months[d.month - 1];
    return SideTitleWidget(
      meta: meta,
      child: Text(label, style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    final max = ([
      ..._verified,
      ..._unverified,
    ].fold<int>(0, (p, e) => e > p ? e : p));
    if (max == 0) return Container();
    final step = (max / 4).ceil();
    if (step == 0) return Container();
    if ((value % step).abs() > 0.001) return Container();
    return Text(
      value.toInt().toString(),
      style: style,
      textAlign: TextAlign.left,
    );
  }
}
