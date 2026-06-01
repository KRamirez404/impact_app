class ProfileActivityItem {
  const ProfileActivityItem({
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
    this.campaignId,
    this.rejectionNote,
    this.auditorName,
  });

  final String title;
  final double amount;
  final String date;
  final String status;
  final int? campaignId;
  final String? rejectionNote;
  final String? auditorName;
}
