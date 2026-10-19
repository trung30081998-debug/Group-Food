import 'session_member.dart';

class OrderSession {
  const OrderSession({
    required this.id,
    required this.hostId,
    required this.title,
    required this.deadline,
    required this.status,
    required this.shippingFee,
    required this.discountAmount,
    this.merchantName,
    this.menuImageUrl,
    this.members = const [],
  });

  final String id;
  final String hostId;
  final String title;
  final String? merchantName;
  final String? menuImageUrl;
  final DateTime deadline;
  final String status;
  final double shippingFee;
  final double discountAmount;
  final List<SessionMember> members;

  double get totalAmount =>
      members.fold(0, (sum, member) => sum + member.totalAmount);
}
