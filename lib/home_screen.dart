import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:carbon_emmision_app/budget_tab.dart';
import 'package:carbon_emmision_app/dashboard_tab.dart';
import 'package:carbon_emmision_app/insights_tab.dart';
import 'package:carbon_emmision_app/providers/auth_provider.dart';
import 'package:carbon_emmision_app/profile_tab.dart';
import 'package:carbon_emmision_app/sign_in_screen.dart';
import 'package:carbon_emmision_app/theme/app_theme.dart';
import 'package:carbon_emmision_app/transaction_history_tab.dart';
import 'package:carbon_emmision_app/widgets/add_transaction_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _showAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surface,
      barrierColor: Colors.black.withOpacity(0.68),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => const AddTransactionSheet(),
    );
  }

  void _openHistory() {
    setState(() => _currentIndex = 2);
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileTab()),
    );
  }

  void _signOut() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Sign out', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Do you want to leave EcoWallet?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<AuthProvider>().signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (_) => false,
              );
            },
            child: const Text('Sign out', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardTab(onOpenHistory: _openHistory, onOpenProfile: _openProfile),
      const InsightsTab(),
      const TransactionHistoryTab(),
      const BudgetTab(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: true,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: tabs),
      floatingActionButton: _FootprintActionButton(onPressed: _showAddTransactionSheet),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _EcoBottomBar(
        currentIndex: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
      ),
      endDrawer: Drawer(
        backgroundColor: AppTheme.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EcoWallet', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text(
                  'A sustainable finance prototype that connects manual expense tracking with carbon footprint estimation.',
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 22),
                _DrawerTile(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 0);
                  },
                ),
                _DrawerTile(
                  icon: Icons.bar_chart_rounded,
                  title: 'Insights',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 1);
                  },
                ),
                _DrawerTile(
                  icon: Icons.receipt_long_rounded,
                  title: 'Transaction History',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 2);
                  },
                ),
                _DrawerTile(
                  icon: Icons.savings_rounded,
                  title: 'Budget Settings',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 3);
                  },
                ),
                _DrawerTile(
                  icon: Icons.person_rounded,
                  title: 'Profile & Settings',
                  onTap: () {
                    Navigator.pop(context);
                    _openProfile();
                  },
                ),
                const Spacer(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout_rounded, color: AppTheme.danger),
                  title: const Text('Sign out', style: TextStyle(color: AppTheme.danger)),
                  onTap: _signOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
      onTap: onTap,
    );
  }
}

class _FootprintActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FootprintActionButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: FloatingActionButton(
        heroTag: 'add-expense-footprint',
        onPressed: onPressed,
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.primaryDeep,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FootprintMark(size: 30),
            SizedBox(height: 2),
            Text('Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _FootprintMark extends StatelessWidget {
  final double size;

  const _FootprintMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FootprintPainter(color: AppTheme.primaryDeep)),
    );
  }
}

class _FootprintPainter extends CustomPainter {
  final Color color;

  const _FootprintPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.translate(w * 0.50, h * 0.55);
    canvas.rotate(-0.24);
    canvas.drawOval(Rect.fromCenter(center: Offset(0, h * 0.08), width: w * 0.38, height: h * 0.56), paint);
    final toeY = -h * 0.30;
    final toeData = [
      (Offset(-w * 0.18, toeY + h * 0.06), w * 0.070),
      (Offset(-w * 0.08, toeY - h * 0.03), w * 0.076),
      (Offset(w * 0.03, toeY - h * 0.06), w * 0.072),
      (Offset(w * 0.14, toeY - h * 0.02), w * 0.066),
      (Offset(w * 0.22, toeY + h * 0.07), w * 0.058),
    ];
    for (final toe in toeData) {
      canvas.drawCircle(toe.$1, toe.$2, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FootprintPainter oldDelegate) => oldDelegate.color != color;
}

class _EcoBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _EcoBottomBar({required this.currentIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding > 0 ? bottomPadding + 2 : 12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.98),
        border: const Border(top: BorderSide(color: AppTheme.border, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.34),
            blurRadius: 26,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Dashboard',
              isSelected: currentIndex == 0,
              onTap: () => onChanged(0),
            ),
            _NavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Insights',
              isSelected: currentIndex == 1,
              onTap: () => onChanged(1),
            ),
            const SizedBox(width: 86),
            _NavItem(
              icon: Icons.receipt_long_rounded,
              label: 'History',
              isSelected: currentIndex == 2,
              onTap: () => onChanged(2),
            ),
            _NavItem(
              icon: Icons.savings_rounded,
              label: 'Budget',
              isSelected: currentIndex == 3,
              onTap: () => onChanged(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textMuted, size: 24),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
