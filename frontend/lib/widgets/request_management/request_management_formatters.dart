import '../../models/staff_request.dart';

String requestDetails(StaffRequest request) {
  final reason = request.reason.trim().isEmpty
      ? 'No reason provided.'
      : request.reason.trim();

  if (request.isClearanceRequest) {
    final prodName = request.productName ?? 'Unknown Product';
    final discount = request.discountPercentage != null
        ? '${request.discountPercentage!.toStringAsFixed(0)}%'
        : '0%';
    return 'Product: $prodName\nProposed Discount: $discount · Reason: $reason';
  }

  if (request.isPurchaseRequest) {
    return reason;
  }

  if (!request.isLeaveRequest) {
    return reason;
  }

  final dateRange =
      '${formatRequestDate(request.startDate)} – ${formatRequestDate(request.endDate)}';
  final totalDays = request.totalLeaveDays;

  if (totalDays == null) {
    return reason;
  }

  return '$reason\n$dateRange · $totalDays day${totalDays == 1 ? '' : 's'}';
}

String formatRequestDate(DateTime? date) {
  if (date == null) {
    return 'Not specified';
  }

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String formatRequestDateTime(DateTime? date) {
  if (date == null) {
    return 'Not available';
  }

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} $hour:$minute';
}

String employeeInitial(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
}
