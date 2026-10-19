import '../../domain/entities/member_item.dart';
import '../../domain/entities/session_member.dart';

class MemberItemModel {
  const MemberItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.note,
  });
  final String id;
  final String name;
  final int quantity;
  final double unitPrice;
  final String? note;

  factory MemberItemModel.fromJson(Map<String, dynamic> json) =>
      MemberItemModel(
        id: json['id'] as String,
        name: json['item_name'] as String,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (json['unit_price'] as num).toDouble(),
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'item_name': name,
    'quantity': quantity,
    'unit_price': unitPrice,
    'note': note,
  };
  MemberItem toEntity() => MemberItem(
    id: id,
    name: name,
    quantity: quantity,
    unitPrice: unitPrice,
    note: note,
  );
}

class MemberModel {
  const MemberModel({
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
  final List<MemberItemModel> items;

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
    id: json['id'] as String,
    sessionId: json['session_id'] as String,
    name: json['member_name'] as String,
    phone: json['member_phone'] as String?,
    totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
    paymentStatus: json['payment_status'] as String? ?? 'PENDING',
    transferCode: json['transfer_code'] as String,
    items: ((json['member_items'] as List<dynamic>?) ?? const [])
        .map((item) => MemberItemModel.fromJson(item as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'session_id': sessionId,
    'member_name': name,
    'member_phone': phone,
    'total_amount': totalAmount,
    'payment_status': paymentStatus,
    'transfer_code': transferCode,
  };
  SessionMember toEntity() => SessionMember(
    id: id,
    sessionId: sessionId,
    name: name,
    phone: phone,
    totalAmount: totalAmount,
    paymentStatus: paymentStatus,
    transferCode: transferCode,
    items: items.map((item) => item.toEntity()).toList(),
  );
}
