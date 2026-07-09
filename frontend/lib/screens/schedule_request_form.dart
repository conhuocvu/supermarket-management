import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/app_state.dart';
import '../models/request.dart';
import '../widgets/bento_card.dart';

class ScheduleRequestForm extends StatefulWidget {
  const ScheduleRequestForm({Key? key}) : super(key: key);

  @override
  State<ScheduleRequestForm> createState() => _ScheduleRequestFormState();
}

class _ScheduleRequestFormState extends State<ScheduleRequestForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime _requestedDate = DateTime(2026, 6, 15);
  String _requestedShiftType = 'Morning';
  TimeOfDay _requestedStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _requestedEndTime = const TimeOfDay(hour: 17, minute: 0);
  String _reason = '';
  final TextEditingController _reasonController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _requestedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _requestedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _requestedStartTime : _requestedEndTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _requestedStartTime = picked;
        } else {
          _requestedEndTime = picked;
        }
      });
    }
  }

  double get _totalHours {
    final double start = _requestedStartTime.hour + (_requestedStartTime.minute / 60.0);
    final double end = _requestedEndTime.hour + (_requestedEndTime.minute / 60.0);
    double diff = end - start;
    if (diff < 0) diff += 24; // Handle overnight shifts
    return diff;
  }

  String get _hoursDifference {
    double diff = _totalHours - 8.0; // Compare against standard 8.0 hours
    if (diff == 0) return '0h difference';
    final String sign = diff > 0 ? '+' : '';
    // Format to 1 decimal place if it has a fraction, else integer
    final String diffStr = diff % 1 == 0 ? diff.toInt().toString() : diff.toStringAsFixed(1);
    return '$sign${diffStr}h difference';
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

    // Format display helper
    final String formattedDate = DateFormat('dd MMMM yyyy').format(_requestedDate);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Request Schedule Change',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with status draft & close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Request Schedule Change',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
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
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submit a request to modify your assigned work shift for manager approval.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Current Assigned Shift
                    _buildSectionHeader(context, Icons.calendar_today, 'CURRENT ASSIGNED SHIFT'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DATE', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
                              const SizedBox(height: 4),
                              Text('15 June 2026', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SHIFT TYPE', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('Morning', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TIME', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
                              const SizedBox(height: 4),
                              Text('08:00 AM - 04:00 PM', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Requested Shift Information
                    _buildSectionHeader(context, Icons.edit_calendar, 'REQUESTED SHIFT INFORMATION'),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.5,
                      children: [
                        // Date picker
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Requested Shift Date', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(DateFormat('MM/dd/yyyy').format(_requestedDate)),
                                    Icon(Icons.calendar_today_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Shift Type
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Requested Shift Type', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _requestedShiftType,
                              decoration: InputDecoration(
                                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              items: ['Morning', 'Afternoon', 'Evening', 'Night'].map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _requestedShiftType = val;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        // Start Time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Requested Start Time', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _selectTime(context, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_requestedStartTime.format(context)),
                                    Icon(Icons.access_time, size: 18, color: theme.colorScheme.onSurfaceVariant),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // End Time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Requested End Time', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _selectTime(context, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_requestedEndTime.format(context)),
                                    Icon(Icons.access_time, size: 18, color: theme.colorScheme.onSurfaceVariant),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Shift summary banner
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
                              Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '$formattedDate • $_requestedShiftType Shift • ${_totalHours.toStringAsFixed(1)} Total Hours',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _hoursDifference,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reason for Request
                    _buildSectionHeader(context, Icons.notes, 'REASON FOR REQUEST'),
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
                                  'Please provide detailed context for your schedule change request...',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                ),
                              ),
                              ListenableBuilder(
                                listenable: _reasonController,
                                builder: (context, _) {
                                  return Text(
                                    '${_reasonController.text.length}/500',
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _reasonController,
                            maxLines: 4,
                            maxLength: 500,
                            decoration: const InputDecoration(
                              hintText: 'Enter details here...',
                              border: InputBorder.none,
                              counterText: '',
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Please enter a request reason';
                              return null;
                            },
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
          // Profile Indicator at bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(
                top: BorderSide(color: theme.dividerColor.withOpacity(0.08)),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(appState.currentUser.imageUrl),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appState.currentUser.name,
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      appState.currentUser.title.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 8, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions row
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
                FilledButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      final String currentShiftTimeStr = '08:00 AM - 04:00 PM';
                      final String targetShiftTimeStr =
                          '${_requestedStartTime.format(context)} - ${_requestedEndTime.format(context)}';

                      final newRequest = RequestItem(
                        id: 'REQ-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                        type: RequestType.shiftSwap,
                        title: 'Schedule Change Request',
                        description: 'Requested shift swap for ${DateFormat('MMM dd').format(_requestedDate)}',
                        status: RequestStatus.pending,
                        submissionDate: DateTime.now(),
                        timeline: [
                          TimelineEvent(
                            title: 'Shift Change Requested',
                            description: 'Submitted by ${appState.currentUser.name}',
                            timestamp: DateTime.now(),
                          ),
                          TimelineEvent(
                            title: 'Awaiting Manager Review',
                            description: 'Pending approval by Floor manager',
                            timestamp: DateTime.now(),
                          ),
                        ],
                        details: {
                          'currentShiftDate': '2026-07-14',
                          'currentShiftTime': currentShiftTimeStr,
                          'targetShiftDate': DateFormat('yyyy-MM-dd').format(_requestedDate),
                          'targetShiftTime': targetShiftTimeStr,
                          'colleague': 'N/A (Open Shift)',
                          'reason': _reason,
                        },
                      );

                      appState.addRequest(newRequest);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Schedule change request submitted!'),
                          backgroundColor: Color(0xFF00503E),
                        ),
                      );

                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
