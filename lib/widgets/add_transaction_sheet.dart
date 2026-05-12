import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:carbon_emmision_app/models/transaction.dart';
import 'package:carbon_emmision_app/providers/wallet_provider.dart';
import 'package:carbon_emmision_app/theme/app_theme.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionCategory _selectedCategory = TransactionCategory.food;
  final DateTime _automaticDate = DateTime.now();

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0.0;
  double get _estimatedCO2 => _amount * _selectedCategory.emissionFactor;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (title.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid expense title and amount.')),
      );
      return;
    }

    final transaction = EcoTransaction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      category: _selectedCategory,
      date: DateTime.now(),
      note: _noteController.text.trim(),
    );

    await context.read<WalletProvider>().addTransaction(transaction);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Manual expense added · ${transaction.co2Kg.toStringAsFixed(1)} kg CO₂ estimated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(20, 14, 20, 18 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(color: AppTheme.borderBright, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.16), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.directions_walk_rounded, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Manual Expense', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
                        SizedBox(height: 3),
                        Text('The date is recorded automatically.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _EmissionPreview(
                estimatedCO2: _estimatedCO2,
                category: _selectedCategory,
                automaticDate: _automaticDate,
              ),
              const SizedBox(height: 20),
              const _FieldLabel('Title'),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Example: Lunch, MRT reload, grocery'),
              ),
              const SizedBox(height: 14),
              const _FieldLabel('Amount'),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: '0.00', prefixText: 'RM '),
              ),
              const SizedBox(height: 14),
              const _FieldLabel('Category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<TransactionCategory>(
                value: _selectedCategory,
                dropdownColor: AppTheme.surfaceElevated,
                iconEnabledColor: AppTheme.primary,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.category_rounded)),
                items: TransactionCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text('${category.emoji}  ${category.label}', style: const TextStyle(color: AppTheme.textPrimary)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ReadOnlyInfo(
                      label: 'Automatic Date',
                      value: DateFormat('d MMM yyyy').format(_automaticDate),
                      icon: Icons.calendar_month_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ReadOnlyInfo(
                      label: 'Emission Factor',
                      value: '${_selectedCategory.emissionFactor.toStringAsFixed(2)} kg/RM',
                      icon: Icons.co2_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _FieldLabel('Description'),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                minLines: 3,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Optional note about this expense'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmissionPreview extends StatelessWidget {
  final double estimatedCO2;
  final TransactionCategory category;
  final DateTime automaticDate;

  const _EmissionPreview({required this.estimatedCO2, required this.category, required this.automaticDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C3B25), Color(0xFF14532D)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estimated Carbon Emission', style: TextStyle(color: AppTheme.accentLight, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('${estimatedCO2.toStringAsFixed(1)} kg CO₂', style: const TextStyle(color: AppTheme.primary, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.7)),
          const SizedBox(height: 4),
          Text('Based on ${category.label} category • ${DateFormat('EEEE, d MMMM yyyy').format(automaticDate)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.35)),
        ],
      ),
    );
  }
}

class _ReadOnlyInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyInfo({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderBright),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(color: AppTheme.accentLight, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.2),
    );
  }
}
