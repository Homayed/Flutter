import 'package:flutter/material.dart';

import 'package:carbon_emmision_app/theme/app_theme.dart';

class EcoBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final String prefix;
  final String suffix;
  final double? highlightAbove;
  final Color? highlightColor;
  final int decimalPlaces;

  const EcoBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.prefix = '',
    this.suffix = '',
    this.highlightAbove,
    this.highlightColor,
    this.decimalPlaces = 0,
  });

  @override
  Widget build(BuildContext context) {
    final safeValues = values.isEmpty ? [0.0] : values;
    final safeLabels = labels.length == safeValues.length
        ? labels
        : List.generate(safeValues.length, (index) => '${index + 1}');
    final maxValue = safeValues.fold<double>(0, (max, item) => item > max ? item : max);

    return SizedBox(
      height: 142,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(safeValues.length, (index) {
          final value = safeValues[index];
          final percent = maxValue <= 0 ? 0.0 : value / maxValue;
          final height = value == 0 ? 10.0 : 80.0 * percent.clamp(0.14, 1.0);
          final isHighlighted = highlightAbove != null && value > highlightAbove!;
          final topColor = isHighlighted ? (highlightColor ?? AppTheme.danger) : AppTheme.primary;
          final bottomColor = isHighlighted ? (highlightColor ?? AppTheme.danger).withOpacity(0.55) : AppTheme.primaryDark;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value == 0 ? '' : '$prefix${value.toStringAsFixed(decimalPlaces)}$suffix',
                      style: TextStyle(color: isHighlighted ? topColor : AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 350 + (index * 45)),
                    curve: Curves.easeOutCubic,
                    height: height,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [bottomColor, topColor],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    safeLabels[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
