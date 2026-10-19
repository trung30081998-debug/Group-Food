class MemberItem {
  const MemberItem({
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

  double get subtotal => quantity * unitPrice;
}
