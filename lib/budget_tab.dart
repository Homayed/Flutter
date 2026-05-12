import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:carbon_emmision_app/providers/wallet_provider.dart';
import 'package:carbon_emmision_app/theme/app_theme.dart';
import 'package:carbon_emmision_app/widgets/eco_bar_chart.dart';

class BudgetTab extends StatelessWidget {
  const BudgetTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, wallet, _) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Budget', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 6),
                      const Text(
                        'Set fixed monthly limits for both money spent and estimated CO₂ footprint.',
                        style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _SpendingBudgetCard(wallet: wallet)),
            SliverToBoxAdapter(child: _CarbonBudgetCard(wallet: wallet)),
            SliverToBoxAdapter(child: _AverageSpendingBenchmarkCard(wallet: wallet)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text(
                  'BUDGET ACTION PLAN',
                  style: TextStyle(
                    color: AppTheme.accentLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _BudgetExpenditureGraph(wallet: wallet)),
            const SliverToBoxAdapter(child: _ActionPlan()),
            const SliverToBoxAdapter(child: SizedBox(height: 128)),
          ],
        );
      },
    );
  }
}

class _SpendingBudgetCard extends StatelessWidget {
  final WalletProvider wallet;
  const _SpendingBudgetCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final progress = wallet.spendingBudgetProgress;
    final statusColor = progress > 0.9
        ? AppTheme.danger
        : progress > 0.7
            ? AppTheme.warning
            : AppTheme.primary;

    return _BudgetCardShell(
      title: 'Monthly spending budget',
      mainValue: 'RM ${wallet.monthlySpendingBudget.toStringAsFixed(0)}',
      subtitle: 'You used RM ${wallet.totalSpent.toStringAsFixed(2)} this month.',
      progress: progress,
      progressColor: statusColor,
      sliderMin: 100,
      sliderMax: 2000,
      sliderDivisions: 38,
      sliderValue: wallet.monthlySpendingBudget,
      onChanged: context.read<WalletProvider>().updateSpendingBudget,
      leftLabel: 'Used',
      leftValue: 'RM ${wallet.totalSpent.toStringAsFixed(2)}',
      rightLabel: 'Remaining',
      rightValue: 'RM ${wallet.remainingSpendingBudget.toStringAsFixed(2)}',
    );
  }
}

class _CarbonBudgetCard extends StatelessWidget {
  final WalletProvider wallet;
  const _CarbonBudgetCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final progress = wallet.carbonBudgetProgress;
    final statusColor = progress > 0.9
        ? AppTheme.danger
        : progress > 0.7
            ? AppTheme.warning
            : AppTheme.primary;

    return _BudgetCardShell(
      title: 'Monthly carbon budget',
      mainValue: '${wallet.monthlyCarbonBudget.toStringAsFixed(0)} kg',
      subtitle: 'You used ${wallet.totalCO2.toStringAsFixed(1)} kg CO₂ this month.',
      progress: progress,
      progressColor: statusColor,
      sliderMin: 40,
      sliderMax: 300,
      sliderDivisions: 26,
      sliderValue: wallet.monthlyCarbonBudget,
      onChanged: context.read<WalletProvider>().updateBudget,
      leftLabel: 'Used',
      leftValue: '${wallet.totalCO2.toStringAsFixed(1)} kg',
      rightLabel: 'Remaining',
      rightValue: '${wallet.remainingCarbonBudget.toStringAsFixed(1)} kg',
    );
  }
}


class _AverageSpendingBenchmarkCard extends StatelessWidget {
  final WalletProvider wallet;
  const _AverageSpendingBenchmarkCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final progress = wallet.spendingBenchmarkProgress;
    final statusColor = wallet.isAboveAverageMonthlySpending ? AppTheme.danger : AppTheme.primary;

    return _BudgetCardShell(
      title: 'Monthly average spending benchmark',
      mainValue: 'RM ${wallet.monthlyAverageSpendingBenchmark.toStringAsFixed(0)}',
      subtitle: wallet.isAboveAverageMonthlySpending
          ? 'You are above this monthly benchmark.'
          : 'You are still below this monthly benchmark.',
      progress: progress,
      progressColor: statusColor,
      sliderMin: 300,
      sliderMax: 3000,
      sliderDivisions: 54,
      sliderValue: wallet.monthlyAverageSpendingBenchmark,
      onChanged: context.read<WalletProvider>().updateMonthlyAverageSpendingBenchmark,
      leftLabel: 'Current spent',
      leftValue: 'RM ${wallet.totalSpent.toStringAsFixed(2)}',
      rightLabel: wallet.isAboveAverageMonthlySpending ? 'Over by' : 'Left before avg.',
      rightValue: 'RM ${wallet.spendingBenchmarkDifference.abs().toStringAsFixed(2)}',
    );
  }
}

class _BudgetCardShell extends StatelessWidget {
  final String title;
  final String mainValue;
  final String subtitle;
  final double progress;
  final Color progressColor;
  final double sliderMin;
  final double sliderMax;
  final int sliderDivisions;
  final double sliderValue;
  final ValueChanged<double> onChanged;
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  const _BudgetCardShell({
    required this.title,
    required this.mainValue,
    required this.subtitle,
    required this.progress,
    required this.progressColor,
    required this.sliderMin,
    required this.sliderMax,
    required this.sliderDivisions,
    required this.sliderValue,
    required this.onChanged,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppTheme.accentLight, fontSize: 12, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(mainValue, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 34, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: AppTheme.background,
                      valueColor: AlwaysStoppedAnimation(progressColor),
                    ),
                    Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(color: progressColor, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Slider(
            min: sliderMin,
            max: sliderMax,
            divisions: sliderDivisions,
            value: sliderValue,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.border,
            onChanged: onChanged,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _BudgetStat(label: leftLabel, value: leftValue, color: progressColor)),
              const SizedBox(width: 10),
              Expanded(child: _BudgetStat(label: rightLabel, value: rightValue, color: AppTheme.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BudgetStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}


class _BudgetExpenditureGraph extends StatelessWidget {
  final WalletProvider wallet;

  const _BudgetExpenditureGraph({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final overBudget = (wallet.totalSpent - wallet.monthlySpendingBudget).clamp(0.0, double.infinity).toDouble();
    final remaining = wallet.remainingSpendingBudget;
    final values = [
      wallet.totalSpent,
      wallet.monthlySpendingBudget,
      wallet.monthlyAverageSpendingBenchmark,
      overBudget,
    ];
    const labels = ['Spent', 'Budget', 'Avg', 'Over'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Budget Expenditure Graph',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: wallet.spendingBudgetProgress >= 1 ? AppTheme.danger.withOpacity(0.14) : AppTheme.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: wallet.spendingBudgetProgress >= 1 ? AppTheme.danger.withOpacity(0.45) : AppTheme.primary.withOpacity(0.45)),
                ),
                child: Text(
                  wallet.spendingBudgetProgress >= 1 ? 'Over budget' : 'On track',
                  style: TextStyle(
                    color: wallet.spendingBudgetProgress >= 1 ? AppTheme.danger : AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            overBudget > 0
                ? 'Your expenses are RM ${overBudget.toStringAsFixed(2)} above the monthly budget.'
                : 'You still have RM ${remaining.toStringAsFixed(2)} available in your monthly budget.',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 16),
          EcoBarChart(
            values: values,
            labels: labels,
            prefix: 'RM ',
            highlightAbove: wallet.monthlySpendingBudget,
            highlightColor: AppTheme.danger,
            decimalPlaces: 0,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _BudgetStat(label: 'Used', value: '${(wallet.spendingBudgetProgress * 100).toStringAsFixed(0)}%', color: wallet.spendingBudgetProgress >= 1 ? AppTheme.danger : AppTheme.primary)),
              const SizedBox(width: 10),
              Expanded(child: _BudgetStat(label: 'Remaining', value: 'RM ${remaining.toStringAsFixed(0)}', color: AppTheme.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionPlan extends StatelessWidget {
  const _ActionPlan();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('🚆', 'Choose public transport for short city trips.'),
      ('🍱', 'Track food spending and reduce high-emission purchases.'),
      ('💡', 'Review utilities and reduce unnecessary energy use.'),
      ('🛍️', 'Avoid impulse shopping and buy only needed items.'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: items
            .map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Text(item.$1, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item.$2, style: const TextStyle(color: AppTheme.textSecondary, height: 1.35))),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
