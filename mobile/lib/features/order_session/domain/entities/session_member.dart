import 'member_item.dart';

class SessionMember {
  const SessionMember({
    required this.id,
    required this.sessionId,
    required this.name,
    required this.totalAmount,
    required this.paymentStatus,
    required this.transferCode,
    this.phone,
    this.items = const [],
  });

  final String id;
  final String sessionId;
  final String name;
  final String? phone;
  final double totalAmount;
  final String paymentStatus;
  final String transferCode;
  final List<MemberItem> items;

  bool get isPaid => paymentStatus.toUpperCase() == 'PAID';
}
