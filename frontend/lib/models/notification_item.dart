/// A user notification (Feature 5.1 - View Notifications).
/// Matches the notifications table: title, content, is_read, created_date.
class NotificationItem {
  final int notificationNumber;
  final String title;
  final String content;
  final bool isRead;
  final DateTime? createdDate;

  const NotificationItem({
    required this.notificationNumber,
    required this.title,
    required this.content,
    required this.isRead,
    this.createdDate,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      notificationNumber: json['notificationNumber'] as int? ?? 0,
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      isRead: json['isRead'] as bool? ?? false,
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'].toString())
          : null,
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      notificationNumber: notificationNumber,
      title: title,
      content: content,
      isRead: isRead ?? this.isRead,
      createdDate: createdDate,
    );
  }
}
