import 'package:flutter/material.dart';

import 'package:carbon_emmision_app/theme/app_theme.dart';

class CO2BarChart extends StatelessWidget {
  final List<double> data;

  const CO2BarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final values = data.isEmpty ? List<double>.filled(7, 0) : data;
    final maxValue = values.fold<double>(0, (max, item) => item > max ? item : max);
    final labels = _lastSevenDayLabels();

    return SizedBox(
      height: 132,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final value = values[index];
          final percent = maxValue <= 0 ? 0.0 : value / maxValue;
          final height = value == 0 ? 10.0 : 74.0 * percent.clamp(0.12, 1.0);
          final isHigh = value >= maxValue && value > 0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    value == 0 ? '' : value.toStringAsFixed(0),
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 350 + (index * 45)),
                    curve: Curves.easeOutCubic,
                    height: height,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: isHigh
                            ? [AppTheme.warning.withOpacity(0.70), AppTheme.warning]
                            : [AppTheme.primaryDark, AppTheme.primary],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[index],
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  List<String> _lastSevenDayLabels() {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    return List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      return labels[day.weekday - 1];
    });
  }
}
