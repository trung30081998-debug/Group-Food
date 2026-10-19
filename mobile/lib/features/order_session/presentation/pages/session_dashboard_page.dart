import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/session_member.dart';
import '../cubit/session_cubit.dart';
import '../cubit/session_state.dart';

class SessionDashboardPage extends StatelessWidget {
  const SessionDashboardPage({required this.sessionId, super.key});
  final String sessionId;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<SessionCubit>()..loadSession(sessionId),
    child: Scaffold(
      appBar: AppBar(title: const Text('Theo dõi phiên gom đơn')),
      body: BlocBuilder<SessionCubit, SessionState>(
        builder: (context, state) {
          if (state.status == SessionStatus.loading && state.session == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == SessionStatus.failure && state.session == null) {
            return Center(
              child: Text(state.errorMessage ?? 'Không tải được phiên'),
            );
          }
          final session = state.session;
          if (session == null) return const SizedBox.shrink();
          return Column(
            children: [
              _Summary(
                deadline: session.deadline,
                total: session.totalAmount,
                memberCount: session.members.length,
              ),
              Expanded(
                child: session.members.isEmpty
                    ? const Center(child: Text('Chưa có món nào được chọn'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 280,
                              mainAxisExtent: 175,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: session.members.length,
                        itemBuilder: (_, index) =>
                            _MemberCard(member: session.members[index]),
                      ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.deadline,
    required this.total,
    required this.memberCount,
  });
  final DateTime deadline;
  final double total;
  final int memberCount;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.all(12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng tạm tính'),
                Text(
                  '${total.toStringAsFixed(0)} đ',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Countdown(deadline: deadline),
                Text('$memberCount thành viên'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});
  final SessionMember member;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  member.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Icon(
                member.isPaid ? Icons.verified : Icons.schedule,
                color: member.isPaid ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: member.items.isEmpty
                ? const Text('Đang chọn món')
                : ListView(
                    children: member.items
                        .map((item) => Text('${item.quantity}× ${item.name}'))
                        .toList(),
                  ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${member.totalAmount.toStringAsFixed(0)} đ'),
              Text(
                member.isPaid ? 'Đã thanh toán' : 'Chờ thanh toán',
                style: TextStyle(
                  color: member.isPaid ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Countdown extends StatefulWidget {
  const _Countdown({required this.deadline});
  final DateTime deadline;
  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late Timer _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.deadline.difference(DateTime.now());
    final text = remaining.isNegative
        ? 'Đã chốt đơn'
        : 'Còn ${remaining.inHours.toString().padLeft(2, '0')}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold));
  }
}
