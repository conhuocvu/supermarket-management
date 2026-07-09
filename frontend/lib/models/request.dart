enum RequestType { leave, shiftSwap, productSuggestion, inventoryIssue }

enum RequestStatus { pending, approved, rejected, resolved }

class RequestItem {
  final String id;
  final RequestType type;
  final String title;
  final String description;
  final RequestStatus status;
  final DateTime submissionDate;
  final List<TimelineEvent> timeline;
  final Map<String, dynamic> details;

  RequestItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    required this.submissionDate,
    required this.timeline,
    required this.details,
  });

  RequestItem copyWith({
    String? id,
    RequestType? type,
    String? title,
    String? description,
    RequestStatus? status,
    DateTime? submissionDate,
    List<TimelineEvent>? timeline,
    Map<String, dynamic>? details,
  }) {
    return RequestItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      submissionDate: submissionDate ?? this.submissionDate,
      timeline: timeline ?? this.timeline,
      details: details ?? this.details,
    );
  }
}

class TimelineEvent {
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isCompleted;

  TimelineEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    this.isCompleted = true,
  });
}
