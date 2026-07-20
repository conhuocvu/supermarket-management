import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';
import '../widgets/bento_card.dart';

class LeaveRequestForm extends ConsumerStatefulWidget {
  const LeaveRequestForm({super.key});

  @override
  ConsumerState<LeaveRequestForm> createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends ConsumerState<LeaveRequestForm> {
  final _formKey = GlobalKey<FormState>();
  String _leaveType = 'Annual Leave';
  DateTime? _startDate;
  DateTime? _endDate;
  String _reason = '';
  final TextEditingController _reasonController = TextEditingController();

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate!.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate = _endDate!.subtract(const Duration(days: 1));
          }
        }
      });
    }
  }

  int get _leaveDuration {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool _submitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end dates')),
      );
      return;
    }
    _formKey.currentState!.save();

    final userId = ref.read(authProvider).user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to submit a leave request.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      // Prefix the reason with the leave type since the backend stores a single reason field.
      await ApiService().createLeaveRequest(
        userId: userId,
        reason: '$_leaveType: $_reason',
        startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Leave request submitted successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      context.go('/manage-requests');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Leave Request Form',
            breadcrumbs: ['Personal', 'Leave Request'],
          );
    });

    Widget mainForm = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with status draft
        Row(
          children: [
            Text(
              'Create Leave Request',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'STATUS: DRAFT',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Submit your request for time off. Your manager will be notified once you submit.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),

        // Leave Information Bento Card
        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Leave Information',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Leave Type Select
              Text('Leave Type', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _leaveType,
                decoration: InputDecoration(
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: ['Annual Leave', 'Sick Leave', 'Unpaid Leave', 'Maternity Leave'].map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _leaveType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Date pickers row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start Date', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _startDate == null
                                      ? 'mm/dd/yyyy'
                                      : DateFormat('MM/dd/yyyy').format(_startDate!),
                                  style: TextStyle(
                                    color: _startDate == null ? Colors.grey : theme.colorScheme.onSurface,
                                  ),
                                ),
                                Icon(Icons.calendar_today_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('End Date', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _endDate == null
                                      ? 'mm/dd/yyyy'
                                      : DateFormat('MM/dd/yyyy').format(_endDate!),
                                  style: TextStyle(
                                    color: _endDate == null ? Colors.grey : theme.colorScheme.onSurface,
                                  ),
                                ),
                                Icon(Icons.calendar_today_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Duration summary banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, color: theme.colorScheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Leave Duration Summary',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$_leaveDuration Days',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Reason Bento Card
        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Reason',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  ListenableBuilder(
                    listenable: _reasonController,
                    builder: (context, _) {
                      return Text(
                        '${_reasonController.text.length}/500 characters',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Briefly describe the reason for your leave request...',
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                  filled: true,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please provide a reason';
                  return null;
                },
                onSaved: (val) => _reason = val ?? '',
              ),
            ],
          ),
        ),
      ],
    );

    Widget sideWidgets = Column(
      children: [
        // Available Balance Card
        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Balance',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildBalanceRow(context, 'Annual Leave', '8 / 20 days', 0.4, 'Resets in 4 months', Colors.green),
              const SizedBox(height: 20),
              _buildBalanceRow(context, 'Sick Leave', '5 / 10 days', 0.5, 'Used this year', Colors.orange),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Policy Reminder Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user_outlined,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Policy Reminder',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPolicyBullet(context, 'Requests for more than 3 days must be submitted 2 weeks in advance.'),
              _buildPolicyBullet(context, 'Sick leave requires medical documentation if exceeding 2 consecutive days.'),
              _buildPolicyBullet(context, 'Managerial approval is required for all emergency leave within 24 hours.'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tip Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Text(
            '“Tip: Check the store peak-trading calendar before requesting annual leave during holiday seasons.”',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: mainForm),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: sideWidgets),
                      ],
                    )
                  : Column(
                      children: [
                        mainForm,
                        const SizedBox(height: 24),
                        sideWidgets,
                      ],
                    ),
            ),
          ),
        ),
        // Bottom button row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: () => context.go('/work-schedule'),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceRow(BuildContext context, String label, String value, double progress, String subtext, Color progressColor) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(value, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          color: progressColor,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text(subtext, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildPolicyBullet(BuildContext context, String text) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
