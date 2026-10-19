import '../../domain/entities/order_session.dart';
import 'member_model.dart';

class SessionModel {
  const SessionModel({
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
  final List<MemberModel> members;

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
    id: json['id'] as String,
    hostId: json['host_id'] as String,
    title: json['title'] as String,
    merchantName: json['merchant_name'] as String?,
    menuImageUrl: json['menu_image_url'] as String?,
    deadline: DateTime.parse(json['deadline'] as String),
    status: json['status'] as String? ?? 'OPEN',
    shippingFee: (json['shipping_fee'] as num?)?.toDouble() ?? 0,
    discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
    members: ((json['session_members'] as List<dynamic>?) ?? const [])
        .map((member) => MemberModel.fromJson(member as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'host_id': hostId,
    'title': title,
    'merchant_name': merchantName,
    'menu_image_url': menuImageUrl,
    'deadline': deadline.toUtc().toIso8601String(),
    'status': status,
    'shipping_fee': shippingFee,
    'discount_amount': discountAmount,
  };
  OrderSession toEntity() => OrderSession(
    id: id,
    hostId: hostId,
    title: title,
    merchantName: merchantName,
    menuImageUrl: menuImageUrl,
    deadline: deadline,
    status: status,
    shippingFee: shippingFee,
    discountAmount: discountAmount,
    members: members.map((member) => member.toEntity()).toList(),
  );
  factory SessionModel.fromEntity(OrderSession entity) => SessionModel(
    id: entity.id,
    hostId: entity.hostId,
    title: entity.title,
    merchantName: entity.merchantName,
    menuImageUrl: entity.menuImageUrl,
    deadline: entity.deadline,
    status: entity.status,
    shippingFee: entity.shippingFee,
    discountAmount: entity.discountAmount,
  );
}
