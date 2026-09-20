class ProfileActivityItem {
  const ProfileActivityItem({
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
    this.campaignId,
    this.rejectionNote,
    this.auditorName,
    this.imageUrl,
    this.nuevosAvances = 0,
    this.totalAvances = 0,
    this.openCampaignDetail = false,
    this.paymentStatus,
  });

  final String title;
  final double amount;
  final String date;
  final String status;
  final int? campaignId;
  final String? rejectionNote;
  final String? auditorName;
  final String? imageUrl;
  final int nuevosAvances;
  final int totalAvances;
  final bool openCampaignDetail;
  final String? paymentStatus;
}
