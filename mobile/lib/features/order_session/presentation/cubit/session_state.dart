import '../../domain/entities/order_session.dart';

enum SessionStatus { initial, loading, success, failure }

class SessionState {
  const SessionState({
    this.status = SessionStatus.initial,
    this.session,
    this.errorMessage,
  });
  final SessionStatus status;
  final OrderSession? session;
  final String? errorMessage;

  SessionState copyWith({
    SessionStatus? status,
    OrderSession? session,
    String? errorMessage,
  }) => SessionState(
    status: status ?? this.status,
    session: session ?? this.session,
    errorMessage: errorMessage,
  );
}
