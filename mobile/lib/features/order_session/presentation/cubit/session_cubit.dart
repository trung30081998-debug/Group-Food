import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/order_session.dart';
import '../../domain/repositories/session_repository.dart';
import 'session_state.dart';

@injectable
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._repository) : super(const SessionState());
  final SessionRepository _repository;
  StreamSubscription? _membersSubscription;

  Future<void> createSession(OrderSession session) async {
    emit(state.copyWith(status: SessionStatus.loading));
    try {
      final created = await _repository.createSession(session);
      emit(state.copyWith(status: SessionStatus.success, session: created));
      _watchMembers(created.id);
    } catch (error) {
      emit(
        state.copyWith(
          status: SessionStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> loadSession(String sessionId) async {
    emit(state.copyWith(status: SessionStatus.loading));
    try {
      final session = await _repository.getSession(sessionId);
      emit(state.copyWith(status: SessionStatus.success, session: session));
      _watchMembers(sessionId);
    } catch (error) {
      emit(
        state.copyWith(
          status: SessionStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _watchMembers(String sessionId) {
    _membersSubscription?.cancel();
    _membersSubscription = _repository.watchMembers(sessionId).listen(
      (members) {
        final current = state.session;
        if (current != null) {
          emit(
            state.copyWith(
              session: OrderSession(
                id: current.id,
                hostId: current.hostId,
                title: current.title,
                merchantName: current.merchantName,
                menuImageUrl: current.menuImageUrl,
                deadline: current.deadline,
                status: current.status,
                shippingFee: current.shippingFee,
                discountAmount: current.discountAmount,
                members: members,
              ),
            ),
          );
        }
      },
      onError: (Object error) => emit(
        state.copyWith(
          status: SessionStatus.failure,
          errorMessage: error.toString(),
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _membersSubscription?.cancel();
    return super.close();
  }
}
