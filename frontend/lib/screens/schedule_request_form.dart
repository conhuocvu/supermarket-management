import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';
import '../widgets/bento_card.dart';

class ScheduleRequestForm extends ConsumerStatefulWidget {
  const ScheduleRequestForm({super.key});

  @override
  ConsumerState<ScheduleRequestForm> createState() => _ScheduleRequestFormState();
}

class _ScheduleRequestFormState extends ConsumerState<ScheduleRequestForm> {
  final _formKey = GlobalKey<FormState>();

  // ── Current shift (the shift currently assigned to the user) ──────────────
  DateTime _currentDate = DateTime.now();
  String _currentShiftType = 'Morning';
  TimeOfDay _currentStartTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _currentEndTime = const TimeOfDay(hour: 16, minute: 0);

  // ── Target shift (the shift the user wants to swap into) ──────────────────
  DateTime _targetDate = DateTime.now().add(const Duration(days: 1));
  String _targetShiftType = 'Afternoon';
  TimeOfDay _targetStartTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _targetEndTime = const TimeOfDay(hour: 21, minute: 0);

  String _reason = '';
  final TextEditingController _reasonController = TextEditingController();
  bool _submitting = false;

  // ── Helpers ────────────────────────────────────────────────────────────────
  static const List<String> _shiftTypes = ['Morning', 'Afternoon', 'Evening', 'Night'];

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  double _hoursOf(TimeOfDay start, TimeOfDay end) {
    double diff = (end.hour + end.minute / 60.0) - (start.hour + start.minute / 60.0);
    if (diff < 0) diff += 24;
    return diff;
  }

  Future<void> _pickDate(BuildContext context, bool isCurrent) async {
    final initial = isCurrent ? _currentDate : _targetDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => isCurrent ? _currentDate = picked : _targetDate = picked);
    }
  }

  Future<void> _pickTime(BuildContext context, bool isCurrent, bool isStart) async {
    TimeOfDay init;
    if (isCurrent) {
      init = isStart ? _currentStartTime : _currentEndTime;
    } else {
      init = isStart ? _targetStartTime : _targetEndTime;
    }
    final picked = await showTimePicker(context: context, initialTime: init);
    if (picked != null) {
      setState(() {
        if (isCurrent) {
          if (isStart) _currentStartTime = picked; else _currentEndTime = picked;
        } else {
          if (isStart) _targetStartTime = picked; else _targetEndTime = picked;
        }
      });
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final userId = ref.read(authProvider).user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to submit a request.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService().createShiftChangeRequest(
        userId: userId,
        reason: _reason.isEmpty ? null : _reason,
        // Current shift
        currentShiftDate: _fmtDate(_currentDate),
        currentShiftType: _currentShiftType,
        currentShiftStart: _fmtTime(_currentStartTime),
        currentShiftEnd: _fmtTime(_currentEndTime),
        // Target shift
        targetShiftDate: _fmtDate(_targetDate),
        targetShiftType: _targetShiftType,
        targetShiftStart: _fmtTime(_targetStartTime),
        targetShiftEnd: _fmtTime(_targetEndTime),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Schedule change request submitted!'),
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final userName = authState.profile?.fullName ?? authState.user?.email ?? 'Employee';
    final userTitle = authState.profile?.roleName ?? 'Staff';
    final avatarUrl = authState.profile?.avatarUrl;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Schedule Change Request',
            breadcrumbs: ['Personal', 'Schedule Change'],
          );
    });

    return Column(
      children: [
        // ── Scrollable form content ──────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildFormHeader(context),
                  const SizedBox(height: 24),

                  // ── Section 1: Current Shift ─────────────────────────────
                  _buildSectionHeader(
                    context,
                    Icons.calendar_today_outlined,
                    'CURRENT SHIFT',
                    subtitle: 'The shift you are currently assigned to',
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 12),
                  _buildShiftCard(
                    context,
                    isCurrent: true,
                    date: _currentDate,
                    shiftType: _currentShiftType,
                    startTime: _currentStartTime,
                    endTime: _currentEndTime,
                    cardColor: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 8),
                  _buildShiftSummaryBanner(
                    context,
                    date: _currentDate,
                    shiftType: _currentShiftType,
                    start: _currentStartTime,
                    end: _currentEndTime,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 24),

                  // Arrow divider
                  _buildSwapArrow(context),
                  const SizedBox(height: 24),

                  // ── Section 2: Target Shift ──────────────────────────────
                  _buildSectionHeader(
                    context,
                    Icons.swap_horiz,
                    'TARGET SHIFT',
                    subtitle: 'The shift you want to swap into',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  _buildShiftCard(
                    context,
                    isCurrent: false,
                    date: _targetDate,
                    shiftType: _targetShiftType,
                    startTime: _targetStartTime,
                    endTime: _targetEndTime,
                    cardColor: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  _buildShiftSummaryBanner(
                    context,
                    date: _targetDate,
                    shiftType: _targetShiftType,
                    start: _targetStartTime,
                    end: _targetEndTime,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),

                  // ── Reason ───────────────────────────────────────────────
                  _buildSectionHeader(
                    context,
                    Icons.notes_outlined,
                    'REASON FOR CHANGE (optional)',
                    subtitle: 'Provide extra context for your manager',
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 12),
                  BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Describe why you want to change shifts...',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ),
                            ListenableBuilder(
                              listenable: _reasonController,
                              builder: (context, _) => Text(
                                '${_reasonController.text.length}/500',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _reasonController,
                          maxLines: 4,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            hintText: 'Enter your reason here...',
                            border: InputBorder.none,
                            counterText: '',
                          ),
                          onSaved: (val) => _reason = val ?? '',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Profile bar ─────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border(
              top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?')
                    : null,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userName,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(userTitle.toUpperCase(),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontSize: 8, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),

        // ── Action buttons ───────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border:
                Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: () => context.go('/work-schedule'),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: const Text('Submit Request',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Sub-widgets ─────────────────────────────────────────────────────────────

  Widget _buildFormHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Shift Change Request',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'DRAFT',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/work-schedule'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title, {
    required String subtitle,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShiftCard(
    BuildContext context, {
    required bool isCurrent,
    required DateTime date,
    required String shiftType,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required Color cardColor,
  }) {
    final theme = Theme.of(context);
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent bar at top
          Container(
            height: 3,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Date row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFieldGroup(
                  context,
                  label: 'DATE',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _pickDate(context, isCurrent),
                    child: _fieldContainer(
                      context,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy').format(date),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Icon(Icons.calendar_today_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFieldGroup(
                  context,
                  label: 'SHIFT TYPE',
                  child: _shiftTypeDropdown(context, shiftType, isCurrent, cardColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Time row
          Row(
            children: [
              Expanded(
                child: _buildFieldGroup(
                  context,
                  label: 'START TIME',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _pickTime(context, isCurrent, true),
                    child: _fieldContainer(
                      context,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            startTime.format(context),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Icon(Icons.access_time,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFieldGroup(
                  context,
                  label: 'END TIME',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _pickTime(context, isCurrent, false),
                    child: _fieldContainer(
                      context,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            endTime.format(context),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Icon(Icons.access_time,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldGroup(BuildContext context,
      {required String label, required Widget child}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _fieldContainer(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }

  Widget _shiftTypeDropdown(
      BuildContext context, String value, bool isCurrent, Color activeColor) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          items: _shiftTypes.map((t) {
            return DropdownMenuItem<String>(value: t, child: Text(t));
          }).toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              if (isCurrent) {
                _currentShiftType = val;
              } else {
                _targetShiftType = val;
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildShiftSummaryBanner(
    BuildContext context, {
    required DateTime date,
    required String shiftType,
    required TimeOfDay start,
    required TimeOfDay end,
    required Color color,
  }) {
    final hours = _hoursOf(start, end);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${DateFormat('dd MMMM yyyy').format(date)} • $shiftType • ${hours.toStringAsFixed(1)} hours (${_fmtTime(start)} - ${_fmtTime(end)})',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwapArrow(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: theme.dividerColor.withValues(alpha: 0.3))),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.secondary,
                theme.colorScheme.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text('SWAP TO',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
        Expanded(child: Divider(color: theme.dividerColor.withValues(alpha: 0.3))),
      ],
    );
  }
}
