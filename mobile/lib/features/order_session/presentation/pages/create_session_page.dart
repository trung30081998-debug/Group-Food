import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/order_session.dart';
import '../cubit/session_cubit.dart';
import '../cubit/session_state.dart';
import 'session_dashboard_page.dart';

class CreateSessionPage extends StatefulWidget {
  const CreateSessionPage({super.key});
  @override
  State<CreateSessionPage> createState() => _CreateSessionPageState();
}

class _CreateSessionPageState extends State<CreateSessionPage> {
  final _formKey = GlobalKey<FormState>();
  final _hostId = TextEditingController();
  final _merchant = TextEditingController();
  final _bankCode = TextEditingController();
  final _accountNo = TextEditingController();
  final _accountName = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(hours: 1));

  @override
  void dispose() {
    _hostId.dispose();
    _merchant.dispose();
    _bankCode.dispose();
    _accountNo.dispose();
    _accountName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<SessionCubit>(),
    child: BlocListener<SessionCubit, SessionState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == SessionStatus.success && state.session != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  SessionDashboardPage(sessionId: state.session!.id),
            ),
          );
        }
        if (state.status == SessionStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Không thể tạo phiên'),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Tạo phiên gom đơn')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _merchant,
                  decoration: const InputDecoration(
                    labelText: 'Tên quán / thương hiệu',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hostId,
                  decoration: const InputDecoration(
                    labelText: 'Host ID (UUID)',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Chốt đơn lúc'),
                  subtitle: Text(
                    _deadline.toLocal().toString().substring(0, 16),
                  ),
                  trailing: const Icon(Icons.timer_outlined),
                  onTap: _pickDeadline,
                ),
                const Divider(),
                const Text(
                  'Tài khoản nhận tiền',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: _bankCode,
                  decoration: const InputDecoration(
                    labelText: 'Mã ngân hàng (VD: VCB)',
                  ),
                ),
                TextFormField(
                  controller: _accountNo,
                  decoration: const InputDecoration(labelText: 'Số tài khoản'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _accountName,
                  decoration: const InputDecoration(
                    labelText: 'Tên chủ tài khoản',
                  ),
                ),
                const SizedBox(height: 24),
                BlocBuilder<SessionCubit, SessionState>(
                  builder: (context, state) => FilledButton(
                    onPressed: state.status == SessionStatus.loading
                        ? null
                        : () => _submit(context),
                    child: Text(
                      state.status == SessionStatus.loading
                          ? 'Đang tạo...'
                          : 'Tạo phiên',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Trường này là bắt buộc' : null;
  Future<void> _pickDeadline() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (value != null && mounted) {
      setState(
        () => _deadline = DateTime(
          value.year,
          value.month,
          value.day,
          _deadline.hour,
          _deadline.minute,
        ),
      );
    }
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<SessionCubit>().createSession(
      OrderSession(
        id: '',
        hostId: _hostId.text.trim(),
        title: _merchant.text.trim(),
        merchantName: _merchant.text.trim(),
        deadline: _deadline,
        status: 'OPEN',
        shippingFee: 0,
        discountAmount: 0,
      ),
    );
  }
}
