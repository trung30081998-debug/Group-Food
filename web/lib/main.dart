import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  runApp(const MemberApp());
}

class MemberApp extends StatelessWidget {
  const MemberApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateRoute: (s) {
      final path = Uri.parse(s.name ?? Uri.base.path).pathSegments;
      return MaterialPageRoute(
        builder: (_) => path.length == 2 && path.first == 'session'
            ? OrderPage(sessionId: path[1])
            : const Scaffold(body: Center(child: Text('Link không hợp lệ'))),
      );
    },
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
    ),
  );
}

class OrderPage extends StatefulWidget {
  const OrderPage({required this.sessionId, super.key});
  final String sessionId;
  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final db = Supabase.instance.client,
      name = TextEditingController(),
      note = TextEditingController();
  final quantities = {'Trà sữa': 0, 'Trà đào': 0, 'Cà phê sữa': 0};
  final prices = {
    'Trà sữa': 30000.0,
    'Trà đào': 28000.0,
    'Cà phê sữa': 25000.0,
  };
  StreamSubscription? payment;
  Map<String, dynamic>? host;
  String? memberId, code;
  double total = 0;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    _host();
  }

  Future<void> _host() async {
    try {
      final session = await db
          .from('sessions')
          .select('host_id')
          .eq('id', widget.sessionId)
          .single();
      host = await db
          .from('users')
          .select('bank_code,bank_account_no,bank_account_name')
          .eq('id', session['host_id'])
          .single();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> submit() async {
    if (name.text.trim().isEmpty || quantities.values.every((v) => v == 0)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nhập tên và chọn món')));
      return;
    }
    setState(() => saving = true);
    try {
      total = quantities.entries.fold(
        0,
        (sum, e) => sum + prices[e.key]! * e.value,
      );
      final member = await db
          .from('session_members')
          .insert({
            'session_id': widget.sessionId,
            'member_name': name.text.trim(),
            'total_amount': total,
            'transfer_code': 'PENDING',
          })
          .select()
          .single();
      memberId = member['id'];
      code =
          'GOM_${widget.sessionId.replaceAll('-', '').substring(0, 8).toUpperCase()}_${memberId!.replaceAll('-', '').substring(0, 8).toUpperCase()}';
      await db
          .from('session_members')
          .update({'transfer_code': code})
          .eq('id', memberId!);
      await db
          .from('member_items')
          .insert(
            quantities.entries
                .where((e) => e.value > 0)
                .map(
                  (e) => {
                    'session_member_id': memberId,
                    'item_name': e.key,
                    'quantity': e.value,
                    'unit_price': prices[e.key],
                    'note': note.text.trim().isEmpty ? null : note.text.trim(),
                  },
                )
                .toList(),
          );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String get qr => Uri.https(
    'img.vietqr.io',
    '/image/${host?['bank_code'] ?? ''}-${host?['bank_account_no'] ?? ''}-compact2.png',
    {
      'amount': total.toStringAsFixed(0),
      'addInfo': code ?? '',
      'accountName': host?['bank_account_name'] ?? '',
    },
  ).toString();
  @override
  void dispose() {
    payment?.cancel();
    name.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (memberId != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: db
                    .from('session_members')
                    .stream(primaryKey: ['id'])
                    .eq('id', memberId!),
                builder: (_, s) {
                  final paid =
                      s.data?.isNotEmpty == true &&
                      s.data!.first['payment_status'] == 'PAID';
                  return paid
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                color: Colors.green,
                                size: 100,
                              ),
                              Text(
                                'Đã thanh toán',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            const Text(
                              'Quét mã thanh toán',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Image.network(qr, height: 300),
                            Text(
                              '${total.toStringAsFixed(0)} đ',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SelectableText(code!, textAlign: TextAlign.center),
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Đang chờ xác nhận thanh toán',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        );
                },
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Gom đơn',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Tên / Biệt danh',
                  ),
                ),
                const SizedBox(height: 16),
                ...quantities.entries.map(
                  (e) => ListTile(
                    title: Text(e.key),
                    subtitle: Text('${prices[e.key]!.toStringAsFixed(0)} đ'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: e.value == 0
                              ? null
                              : () => setState(
                                  () => quantities[e.key] = e.value - 1,
                                ),
                          icon: const Icon(Icons.remove),
                        ),
                        Text('${e.value}'),
                        IconButton(
                          onPressed: () =>
                              setState(() => quantities[e.key] = e.value + 1),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ),
                TextField(
                  controller: note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    hintText: '50% đường, không đá',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: saving ? null : submit,
                  child: Text(saving ? 'Đang gửi...' : 'Xác nhận Order'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
