import '../entities/order_session.dart';
import '../entities/session_member.dart';

abstract class SessionRepository {
  Future<OrderSession> createSession(OrderSession session);
  Future<OrderSession> getSession(String sessionId);
  Stream<List<SessionMember>> watchMembers(String sessionId);
}
