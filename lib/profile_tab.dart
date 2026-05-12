import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:carbon_emmision_app/providers/auth_provider.dart';
import 'package:carbon_emmision_app/providers/wallet_provider.dart';
import 'package:carbon_emmision_app/theme/app_theme.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _controllersReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersReady) return;
    final auth = context.read<AuthProvider>();
    _nameController = TextEditingController(text: auth.userName ?? 'Abdullah Marjuk');
    _emailController = TextEditingController(text: auth.userEmail ?? 'demo@ecowallet.com');
    _controllersReady = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    await context.read<AuthProvider>().updateProfile(
          name: _nameController.text,
          email: _emailController.text,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    final initials = _initials(auth.userName ?? 'Eco User');

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surface,
                        foregroundColor: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Profile & Settings', style: Theme.of(context).textTheme.headlineMedium)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withOpacity(0.14),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.45), width: 2),
                    ),
                    child: Center(
                      child: Text(initials, style: const TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.userName ?? 'Eco User', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(auth.userEmail ?? 'demo@ecowallet.com', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: AppTheme.primaryDeep, borderRadius: BorderRadius.circular(999)),
                          child: const Text('Academic prototype', style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Expanded(child: _ProfileStat(label: 'Total spent', value: 'RM ${wallet.totalSpent.toStringAsFixed(0)}')),
                  const SizedBox(width: 10),
                  Expanded(child: _ProfileStat(label: 'Total CO₂', value: '${wallet.totalCO2.toStringAsFixed(1)} kg')),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _EditProfileCard(nameController: _nameController, emailController: _emailController, onSave: _saveProfile)),
          SliverToBoxAdapter(child: _SettingsCard(wallet: wallet)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text(
                'SYSTEM FEATURES',
                style: TextStyle(
                  color: AppTheme.accentLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: const [
                  _FeatureTile(icon: Icons.login_rounded, title: 'Login and registration', subtitle: 'Firebase Authentication for user login and registration.'),
                  _FeatureTile(icon: Icons.edit_note_rounded, title: 'Manual expense entry', subtitle: 'No bank API required; users enter spending manually and records sync to Firestore.'),
                  _FeatureTile(icon: Icons.co2_rounded, title: 'Carbon calculation', subtitle: 'Estimated CO₂ = amount × category emission factor.'),
                  _FeatureTile(icon: Icons.dashboard_rounded, title: 'Dashboard and insights', subtitle: 'Realtime summaries, category breakdowns, filters, and charts from stored user data.'),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.primaryDeep,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.primaryDark),
              ),
              child: const Text(
                'Note: CO₂ values are estimated for academic demonstration. In a real deployment, emission factors should be updated using verified datasets or APIs.',
                style: TextStyle(color: AppTheme.textSecondary, height: 1.45),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'EW';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}

class _EditProfileCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final Future<void> Function() onSave;

  const _EditProfileCard({required this.nameController, required this.emailController, required this.onSave});

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
          const Text('Edit Profile', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Update the profile details saved for your EcoWallet account.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.35)),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: _inputDecoration('Display name', Icons.person_rounded),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: _inputDecoration('Email address', Icons.alternate_email_rounded),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save profile'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.primaryDeep,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.textSecondary),
      filled: true,
      fillColor: AppTheme.background,
      labelStyle: const TextStyle(color: AppTheme.textMuted),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final WalletProvider wallet;

  const _SettingsCard({required this.wallet});

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
          const Text('Settings', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Adjust key limits used in the dashboard, insights, and budget analysis.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.35)),
          const SizedBox(height: 16),
          _CompactSlider(
            label: 'Monthly spending budget',
            value: wallet.monthlySpendingBudget,
            min: 100,
            max: 2000,
            divisions: 38,
            valueText: 'RM ${wallet.monthlySpendingBudget.toStringAsFixed(0)}',
            onChanged: context.read<WalletProvider>().updateSpendingBudget,
          ),
          _CompactSlider(
            label: 'Monthly carbon budget',
            value: wallet.monthlyCarbonBudget,
            min: 40,
            max: 300,
            divisions: 26,
            valueText: '${wallet.monthlyCarbonBudget.toStringAsFixed(0)} kg CO₂',
            onChanged: context.read<WalletProvider>().updateBudget,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: context.read<WalletProvider>().resetDemoData,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reset demo data'),
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

class _CompactSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueText;
  final ValueChanged<double> onChanged;

  const _CompactSlider({required this.label, required this.value, required this.min, required this.max, required this.divisions, required this.valueText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w800))),
              Text(valueText, style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w900)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.border,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.13), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
