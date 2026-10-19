import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/order_session/domain/entities/member_item.dart';

void main() {
  test('member item calculates its subtotal', () {
    const item = MemberItem(
      id: 'item-1',
      name: 'Trà sữa',
      quantity: 2,
      unitPrice: 25000,
    );
    expect(item.subtotal, 50000);
  });
}
