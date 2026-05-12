import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:carbon_emmision_app/models/transaction.dart';
import 'package:carbon_emmision_app/providers/auth_provider.dart';
import 'package:carbon_emmision_app/providers/wallet_provider.dart';
import 'package:carbon_emmision_app/theme/app_theme.dart';

class DashboardTab extends StatelessWidget {
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenProfile;

  const DashboardTab({super.key, this.onOpenHistory, this.onOpenProfile});

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, wallet, _) {
        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(child: _DashboardHeader(onOpenProfile: onOpenProfile)),
            SliverToBoxAdapter(child: _MetricCard.spending(wallet: wallet)),
            SliverToBoxAdapter(child: _MetricCard.carbon(wallet: wallet)),
            SliverToBoxAdapter(child: _QuickStats(wallet: wallet)),
            SliverToBoxAdapter(child: _BenchmarkNotice(wallet: wallet)),
            SliverToBoxAdapter(child: _RecentTransactions(wallet: wallet, onOpenHistory: onOpenHistory)),
            const SliverToBoxAdapter(child: SizedBox(height: 126)),
          ],
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final VoidCallback? onOpenProfile;

  const _DashboardHeader({required this.onOpenProfile});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'EW';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayName = auth.userName ?? 'Abdullah Marjuk';
    final firstName = displayName.split(' ').first;

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF06130D), Color(0xFF0D2A1A), Color(0xFF0A3A24)],
          ),
        ),
        child: Row(
          children: [
            Tooltip(
              message: 'Open profile and settings',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onOpenProfile,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withOpacity(0.16),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.48), width: 1.3),
                  ),
                  child: Center(
                    child: Text(_initials(displayName), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_greeting()}, $firstName', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  const Text('EcoWallet', style: TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.7)),
                ],
              ),
            ),
            Builder(
              builder: (context) => IconButton.filledTonal(
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                icon: const Icon(Icons.tune_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primary.withOpacity(0.13),
                  foregroundColor: AppTheme.accent,
                  fixedSize: const Size(46, 46),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String chipText;
  final Color chipColor;
  final String subtitle;
  final IconData icon;
  final double progress;
  final String progressLabel;
  final bool isDanger;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.chipText,
    required this.chipColor,
    required this.subtitle,
    required this.icon,
    required this.progress,
    required this.progressLabel,
    required this.isDanger,
  });

  factory _MetricCard.spending({required WalletProvider wallet}) {
    return _MetricCard(
      title: 'Total Spending',
      value: 'RM ${wallet.totalSpent.toStringAsFixed(2)}',
      chipText: 'This month',
      chipColor: AppTheme.info,
      subtitle: 'Budget: RM ${wallet.monthlySpendingBudget.toStringAsFixed(0)} • Remaining: RM ${wallet.remainingSpendingBudget.toStringAsFixed(2)}',
      icon: Icons.account_balance_wallet_rounded,
      progress: wallet.spendingBudgetProgress,
      progressLabel: '${(wallet.spendingBudgetProgress * 100).toStringAsFixed(0)}% of monthly spending budget used',
      isDanger: wallet.spendingBudgetProgress >= 0.9,
    );
  }

  factory _MetricCard.carbon({required WalletProvider wallet}) {
    return _MetricCard(
      title: 'Total Carbon Emission',
      value: '${wallet.totalCO2.toStringAsFixed(1)} kg CO₂',
      chipText: 'Estimated from recorded expenses',
      chipColor: wallet.carbonBudgetProgress >= 0.9 ? AppTheme.danger : AppTheme.primary,
      subtitle: 'Budget: ${wallet.monthlyCarbonBudget.toStringAsFixed(0)} kg CO₂ • Remaining: ${wallet.remainingCarbonBudget.toStringAsFixed(1)} kg CO₂',
      icon: Icons.recycling_rounded,
      progress: wallet.carbonBudgetProgress,
      progressLabel: '${(wallet.carbonBudgetProgress * 100).toStringAsFixed(0)}% of monthly carbon budget used',
      isDanger: wallet.carbonBudgetProgress >= 0.9,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = isDanger ? AppTheme.danger : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
              ),
              Icon(icon, color: activeColor, size: 26),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1.2),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: chipColor.withOpacity(0.16), borderRadius: BorderRadius.circular(9)),
            child: Text(chipText, style: TextStyle(color: chipColor, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
          const SizedBox(height: 14),
          Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, height: 1.35, fontSize: 12)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppTheme.background,
              valueColor: AlwaysStoppedAnimation(activeColor),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(child: Text(progressLabel, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11))),
              const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final WalletProvider wallet;
  const _QuickStats({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Transactions',
              value: '${wallet.allTransactions.length}',
              subtitle: 'Recorded expenses',
              icon: Icons.receipt_long_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Avg CO₂ / Transaction',
              value: '${wallet.averageCO2PerTransaction.toStringAsFixed(1)} kg',
              subtitle: 'Total CO₂ ÷ transactions',
              icon: Icons.co2_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.14), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, height: 1.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BenchmarkNotice extends StatelessWidget {
  final WalletProvider wallet;
  const _BenchmarkNotice({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final isAbove = wallet.isAboveAverageMonthlySpending;
    final color = isAbove ? AppTheme.danger : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAbove ? AppTheme.danger.withOpacity(0.10) : AppTheme.primaryDeep,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.42)),
      ),
      child: Row(
        children: [
          Icon(isAbove ? Icons.warning_amber_rounded : Icons.verified_rounded, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet.monthlySpendingBenchmarkTitle, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(wallet.monthlySpendingBenchmarkMessage, style: const TextStyle(color: AppTheme.textSecondary, height: 1.35, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  final WalletProvider wallet;
  final VoidCallback? onOpenHistory;

  const _RecentTransactions({required this.wallet, required this.onOpenHistory});

  @override
  Widget build(BuildContext context) {
    final items = wallet.allTransactions.take(4).toList();

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(9)),
                child: const Text('Transaction', style: TextStyle(color: AppTheme.primaryDeep, fontSize: 12, fontWeight: FontWeight.w900)),
              ),
              const Spacer(),
              IconButton(
                onPressed: onOpenHistory,
                icon: const Icon(Icons.more_horiz_rounded, color: AppTheme.textSecondary),
                tooltip: 'Open transaction history',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('No transactions recorded yet. Tap the centre button to add your first manual expense.', style: TextStyle(color: AppTheme.textMuted, height: 1.4)),
            )
          else
            ...items.map((transaction) => _RecentTransactionRow(transaction: transaction)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onOpenHistory,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Search and filter transaction history'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.borderBright),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionRow extends StatelessWidget {
  final EcoTransaction transaction;
  const _RecentTransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.category.label.toUpperCase(), style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(DateFormat('EEEE, d MMMM yyyy').format(transaction.date), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('RM ${transaction.amount.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text('${transaction.co2Kg.toStringAsFixed(1)} kg CO₂', textAlign: TextAlign.right, style: TextStyle(color: transaction.category.color, fontSize: 12, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
