import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:carbon_emmision_app/models/transaction.dart';
import 'package:carbon_emmision_app/providers/wallet_provider.dart';
import 'package:carbon_emmision_app/theme/app_theme.dart';
import 'package:carbon_emmision_app/widgets/eco_bar_chart.dart';

class InsightsTab extends StatelessWidget {
  const InsightsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, wallet, _) {
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _InsightsHeader()),
            SliverToBoxAdapter(child: _InsightSummary(wallet: wallet)),
            SliverToBoxAdapter(child: _MonthlyBenchmarkCard(wallet: wallet)),
            SliverToBoxAdapter(child: _CategoryPieCard(wallet: wallet)),
            SliverToBoxAdapter(child: _TreeOffsetCard(wallet: wallet)),
            SliverToBoxAdapter(child: _FinancialCategoryGraph(wallet: wallet)),
            SliverToBoxAdapter(child: _CarbonCategoryGraph(wallet: wallet)),
            SliverToBoxAdapter(child: _HighestEmissionCard(wallet: wallet)),
            SliverToBoxAdapter(child: _TipsCard(tips: wallet.smartTips)),
            const SliverToBoxAdapter(child: SizedBox(height: 126)),
          ],
        );
      },
    );
  }
}

class _InsightsHeader extends StatelessWidget {
  const _InsightsHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Insights', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            const Text(
              'Professional visual analysis of your spending pattern, estimated carbon impact, and offset requirement.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightSummary extends StatelessWidget {
  final WalletProvider wallet;
  const _InsightSummary({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _MiniSummaryCard(
              label: 'Spending',
              value: 'RM ${wallet.totalSpent.toStringAsFixed(0)}',
              subtitle: 'This month',
              icon: Icons.account_balance_wallet_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniSummaryCard(
              label: 'Carbon',
              value: '${wallet.totalCO2.toStringAsFixed(1)} kg',
              subtitle: 'Estimated CO₂',
              icon: Icons.co2_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniSummaryCard(
              label: 'Trees',
              value: '${wallet.treesRequiredToOffsetMonthlyCO2}',
              subtitle: 'To offset',
              icon: Icons.forest_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  const _MiniSummaryCard({required this.label, required this.value, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 21),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _MonthlyBenchmarkCard extends StatelessWidget {
  final WalletProvider wallet;
  const _MonthlyBenchmarkCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final isAbove = wallet.isAboveAverageMonthlySpending;
    final color = isAbove ? AppTheme.danger : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isAbove ? AppTheme.danger.withOpacity(0.10) : AppTheme.primaryDeep,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isAbove ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: color, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wallet.monthlySpendingBenchmarkTitle, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text('Monthly benchmark: RM ${wallet.monthlyAverageSpendingBenchmark.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: wallet.spendingBenchmarkProgress,
              minHeight: 9,
              backgroundColor: AppTheme.background,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 10),
          Text(wallet.monthlySpendingBenchmarkMessage, style: const TextStyle(color: AppTheme.textSecondary, height: 1.35, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FinancialCategoryGraph extends StatelessWidget {
  final WalletProvider wallet;
  const _FinancialCategoryGraph({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final hasData = wallet.categorySpendingValues.any((value) => value > 0);

    return _GraphCard(
      title: 'Financial Graph by Category',
      subtitle: 'Top spending categories recorded through manual expenses.',
      child: hasData
          ? EcoBarChart(
              values: wallet.categorySpendingValues,
              labels: wallet.categorySpendingLabels,
              prefix: 'RM ',
              decimalPlaces: 0,
            )
          : const _EmptyGraphMessage(message: 'Add transactions to generate financial insights.'),
    );
  }
}

class _CarbonCategoryGraph extends StatelessWidget {
  final WalletProvider wallet;
  const _CarbonCategoryGraph({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final hasData = wallet.categoryCarbonValues.any((value) => value > 0);

    return _GraphCard(
      title: 'Carbon Graph by Category',
      subtitle: 'Estimated CO₂ emissions based on expense category factors.',
      child: hasData
          ? EcoBarChart(
              values: wallet.categoryCarbonValues,
              labels: wallet.categoryCarbonLabels,
              suffix: ' kg',
              decimalPlaces: 1,
            )
          : const _EmptyGraphMessage(message: 'Add transactions to generate carbon insights.'),
    );
  }
}

class _GraphCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _GraphCard({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.35)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _EmptyGraphMessage extends StatelessWidget {
  final String message;
  const _EmptyGraphMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(message, style: const TextStyle(color: AppTheme.textMuted, height: 1.4)),
    );
  }
}

class _CategoryPieCard extends StatelessWidget {
  final WalletProvider wallet;
  const _CategoryPieCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final summaries = wallet.categorySummaries;
    final total = wallet.totalCO2;
    final hasData = total > 0 && summaries.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Category Summary', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Share of total estimated CO₂ emissions.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 18),
          if (!hasData)
            const _EmptyGraphMessage(message: 'No category summary is available yet.')
          else
            Column(
              children: [
                SizedBox(
                  height: 210,
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomPaint(
                          painter: _CategoryPiePainter(summaries: summaries, total: total),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(total.toStringAsFixed(1), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w900)),
                                const Text('kg CO₂', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: summaries.take(5).map((summary) {
                            final percent = total == 0 ? 0.0 : (summary.co2Kg / total) * 100;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(width: 10, height: 10, decoration: BoxDecoration(color: summary.category.color, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(summary.category.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700))),
                                  Text('${percent.toStringAsFixed(0)}%', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryPiePainter extends CustomPainter {
  final List<CategorySummary> summaries;
  final double total;

  _CategoryPiePainter({required this.summaries, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.fill;
    var startAngle = -math.pi / 2;

    for (final summary in summaries) {
      final sweep = total <= 0 ? 0.0 : (summary.co2Kg / total) * math.pi * 2;
      paint.color = summary.category.color;
      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
    }

    final holePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.surface;
    canvas.drawCircle(center, radius * 0.58, holePaint);
  }

  @override
  bool shouldRepaint(covariant _CategoryPiePainter oldDelegate) {
    return oldDelegate.summaries != summaries || oldDelegate.total != total;
  }
}

class _TreeOffsetCard extends StatelessWidget {
  final WalletProvider wallet;
  const _TreeOffsetCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF052E16), Color(0xFF0F4B2C)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.forest_rounded, color: AppTheme.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tree Offset Estimate', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text('Plant approximately ${wallet.treesRequiredToOffsetMonthlyCO2} tree(s) to offset this month\'s recorded CO₂.', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          EcoBarChart(
            values: wallet.treeOffsetValues,
            labels: wallet.treeOffsetLabels,
            suffix: ' kg',
            decimalPlaces: 0,
          ),
          const SizedBox(height: 12),
          Text(
            'Prototype assumption: one mature tree offsets about ${WalletProvider.treeAnnualAbsorptionKg.toStringAsFixed(0)} kg CO₂ per year. This is used for academic estimation and can be adjusted in future research.',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _HighestEmissionCard extends StatelessWidget {
  final WalletProvider wallet;
  const _HighestEmissionCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final tx = wallet.highestEmissionTransaction;
    if (tx == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryDeep,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primaryDark),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, color: AppTheme.primary, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Highest Emission Transaction', style: TextStyle(color: AppTheme.accentLight, fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(tx.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('${tx.category.label} · RM ${tx.amount.toStringAsFixed(2)} · ${tx.co2Kg.toStringAsFixed(1)} kg CO₂', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final List<String> tips;
  const _TipsCard({required this.tips});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Professional Recommendations', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(tip, style: const TextStyle(color: AppTheme.textSecondary, height: 1.4, fontSize: 13))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
