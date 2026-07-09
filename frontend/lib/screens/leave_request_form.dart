import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/app_state.dart';
import '../models/request.dart';
import '../widgets/bento_card.dart';

class LeaveRequestForm extends StatefulWidget {
  const LeaveRequestForm({Key? key}) : super(key: key);

  @override
  State<LeaveRequestForm> createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends State<LeaveRequestForm> {
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

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
                color: theme.colorScheme.outlineVariant.withOpacity(0.4),
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
                value: _leaveType,
                decoration: InputDecoration(
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
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
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
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
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
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
                  color: theme.colorScheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
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
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
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
        const SizedBox(height: 20),

        // Attachment Bento Card
        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.attach_file, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Supporting Attachment',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                    style: BorderStyle.solid,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.upload_file_outlined, size: 40, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Click or drag and drop to upload',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF, JPG, or PNG (Max 5MB)',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
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
            color: const Color(0xFFE8F5E9), // Light green policy background
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: Color(0xFF00503E), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Policy Reminder',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF00503E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPolicyBullet('Requests for more than 3 days must be submitted 2 weeks in advance.'),
              _buildPolicyBullet('Sick leave requires medical documentation if exceeding 2 consecutive days.'),
              _buildPolicyBullet('Managerial approval is required for all emergency leave within 24 hours.'),
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
            border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
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

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Leave Requests',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: Column(
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
              border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.08))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (_startDate == null || _endDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select both start and end dates')),
                        );
                        return;
                      }
                      _formKey.currentState!.save();

                      final newRequest = RequestItem(
                        id: 'REQ-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                        type: RequestType.leave,
                        title: '$_leaveType Request',
                        description: 'Requested $_leaveDuration day(s) of $_leaveType',
                        status: RequestStatus.pending,
                        submissionDate: DateTime.now(),
                        timeline: [
                          TimelineEvent(
                            title: 'Leave Request Submitted',
                            description: 'Submitted by ${appState.currentUser.name}',
                            timestamp: DateTime.now(),
                          ),
                          TimelineEvent(
                            title: 'Awaiting Manager Review',
                            description: 'Pending approval by floor manager',
                            timestamp: DateTime.now(),
                          ),
                        ],
                        details: {
                          'leaveType': _leaveType,
                          'startDate': DateFormat('yyyy-MM-dd').format(_startDate!),
                          'endDate': DateFormat('yyyy-MM-dd').format(_endDate!),
                          'reason': _reason,
                          'approvedBy': 'Pending',
                        },
                      );

                      appState.addRequest(newRequest);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Leave request submitted successfully!'),
                          backgroundColor: Color(0xFF00503E),
                        ),
                      );

                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
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
          backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
          color: progressColor,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text(subtext, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildPolicyBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF00503E), fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF00503E), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
