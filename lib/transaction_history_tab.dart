import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:carbon_emmision_app/models/transaction.dart';
import 'package:carbon_emmision_app/providers/wallet_provider.dart';
import 'package:carbon_emmision_app/theme/app_theme.dart';
import 'package:carbon_emmision_app/widgets/eco_bar_chart.dart';
import 'package:carbon_emmision_app/widgets/transaction_tile.dart';

class TransactionHistoryTab extends StatelessWidget {
  const TransactionHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, wallet, _) {
        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(child: _HistoryHeader(wallet: wallet)),
            SliverToBoxAdapter(child: _SearchAndFilter(wallet: wallet)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  children: [
                    const Text(
                      'MY TRANSACTION HISTORY',
                      style: TextStyle(
                        color: AppTheme.accentLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${wallet.visibleTransactions.length} shown',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            if (wallet.visibleTransactions.isEmpty)
              const SliverToBoxAdapter(child: _EmptyTransactions())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) => TransactionTile(transaction: wallet.visibleTransactions[index]),
                  childCount: wallet.visibleTransactions.length,
                ),
              ),
            SliverToBoxAdapter(child: _HistoryGraphCard(wallet: wallet)),
            const SliverToBoxAdapter(child: SizedBox(height: 128)),
          ],
        );
      },
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final WalletProvider wallet;
  const _HistoryHeader({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('History', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            const Text(
              'Search, filter, and review every manual expense with its estimated carbon footprint.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _HistorySummaryCard(
                    label: 'Total spending',
                    value: 'RM ${wallet.totalSpent.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HistorySummaryCard(
                    label: 'Total carbon',
                    value: '${wallet.totalCO2.toStringAsFixed(1)} kg',
                    icon: Icons.eco_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HistorySummaryCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}


class _HistoryGraphCard extends StatelessWidget {
  final WalletProvider wallet;
  const _HistoryGraphCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final dailyBenchmark = wallet.monthlyAverageSpendingBenchmark / 30;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 14),
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
                  'Transaction history graph',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: wallet.isAboveAverageMonthlySpending ? AppTheme.danger.withOpacity(0.14) : AppTheme.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: wallet.isAboveAverageMonthlySpending ? AppTheme.danger.withOpacity(0.5) : AppTheme.primary.withOpacity(0.5)),
                ),
                child: Text(
                  wallet.isAboveAverageMonthlySpending ? 'Above avg' : 'Below avg',
                  style: TextStyle(
                    color: wallet.isAboveAverageMonthlySpending ? AppTheme.danger : AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Last 7 days spending from your manual transactions', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          EcoBarChart(
            values: wallet.weeklySpending,
            labels: wallet.lastSevenDayLabels,
            prefix: 'RM ',
            highlightAbove: dailyBenchmark,
            highlightColor: AppTheme.warning,
            decimalPlaces: 0,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HistoryGraphMiniStat(
                  label: 'Highest day',
                  value: 'RM ${wallet.highestWeeklySpending.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HistoryGraphMiniStat(
                  label: 'Daily avg.',
                  value: 'RM ${wallet.averageDailySpendingFromHistory.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryGraphMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _HistoryGraphMiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  final WalletProvider wallet;
  const _SearchAndFilter({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Column(
        children: [
          TextField(
            onChanged: context.read<WalletProvider>().updateSearch,
            decoration: const InputDecoration(
              hintText: 'Search history by name, category, or note',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'All',
                        emoji: '✨',
                        isSelected: wallet.filterCategory == null,
                        onTap: () => context.read<WalletProvider>().updateCategoryFilter(null),
                      ),
                      ...TransactionCategory.values.map(
                        (category) => _FilterChip(
                          label: category.label,
                          emoji: category.emoji,
                          isSelected: wallet.filterCategory == category,
                          onTap: () => context.read<WalletProvider>().updateCategoryFilter(category),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: context.read<WalletProvider>().clearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 19),
                tooltip: 'Clear filters',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.emoji, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderBright),
          ),
          child: Row(
            children: [
              Text(emoji),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF052E16) : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, color: AppTheme.textMuted, size: 34),
          SizedBox(height: 10),
          Text('No matching transactions found', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text('Try changing the search text or category filter.', style: TextStyle(color: AppTheme.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
