import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class CourseDistributionChart extends StatefulWidget {
  final Map<String, double> distribution;

  const CourseDistributionChart({
    Key? key,
    required this.distribution,
  }) : super(key: key);

  @override
  State<CourseDistributionChart> createState() => _CourseDistributionChartState();
}

class _CourseDistributionChartState extends State<CourseDistributionChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          const SizedBox(width: 30),

          // Chart
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Donut chart
                SizedBox(
                  height: 140,
                  width: 140,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = null;
                              return;
                            }
                            touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _buildPieChartSections(),
                    ),
                  ),
                ),

                Center(
                  child: SizedBox(
                    height: 20,
                    child: touchedIndex != null
                        ? Text(
                      _getPercentageText(touchedIndex!),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                        : null,
                  ),
                ),

                Positioned(
                  right: 0,
                  top: 40,
                  child: _buildLegendItem('EECS', const Color(0xFF9BAEFF)),
                ),
                Positioned(
                  right: 0,
                  bottom: 40,
                  child: _buildLegendItem('CS', const Color(0xFF73B679)),
                ),
                Positioned(
                  left: 0,
                  top: 40,
                  child: _buildLegendItem('EE', const Color(0xFFFFA978)),
                ),
                Positioned(
                  left: 0,
                  bottom: 40,
                  child: _buildLegendItem('Others', const Color(0xFFD9BBFF)),
                ),
              ],
            ),
          ),

          // Right spacing
          const SizedBox(width: 30),
        ],
      ),
    );
  }

  String _getPercentageText(int index) {
    final segments = _getSegments();
    final validSegments = segments.where((segment) => segment.value > 0.01).toList();

    if (index < 0 || index >= validSegments.length) return "0.0%";

    double total = segments.fold(0, (sum, segment) => sum + segment.value);
    if (total == 0) return "0.0%";

    double segmentValue = validSegments[index].value;
    double percentage = (segmentValue / total) * 100;
    return "${percentage.toStringAsFixed(1)}%";
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final segments = _getSegments();

    final validSegments = segments.where((segment) => segment.value > 0.01).toList();

    return validSegments.asMap().entries.map((entry) {
      final int index = entry.key;
      final segment = entry.value;

      final isTouched = touchedIndex == index;
      final radius = isTouched ? 35.0 : 30.0;

      return PieChartSectionData(
        color: segment.color,
        value: segment.value,
        title: '',
        radius: radius,
        titleStyle: GoogleFonts.poppins(
          fontSize: 0.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isTouched ? _Badge(segment.color) : null,
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }

  List<ChartSegment> _getSegments() {
    return [
      ChartSegment(
        color: const Color(0xFF9BAEFF),
        value: widget.distribution['EECS'] ?? 0,
        label: 'EECS',
      ),
      ChartSegment(
        color: const Color(0xFF73B679),
        value: widget.distribution['CS'] ?? 0,
        label: 'CS',
      ),
      ChartSegment(
        color: const Color(0xFFFFA978),
        value: widget.distribution['EE'] ?? 0,
        label: 'EE',
      ),
      ChartSegment(
        color: const Color(0xFFD9BBFF),
        value: widget.distribution['Others'] ?? 0,
        label: 'Others',
      ),
    ];
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final Color color;

  const _Badge(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }
}

class ChartSegment {
  final Color color;
  final double value;
  final String label;

  ChartSegment({
    required this.color,
    required this.value,
    required this.label,
  });
}