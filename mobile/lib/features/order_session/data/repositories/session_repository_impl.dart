import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/order_session.dart';
import '../../domain/entities/session_member.dart';
import '../../domain/repositories/session_repository.dart';
import '../models/member_model.dart';
import '../models/session_model.dart';

@LazySingleton(as: SessionRepository)
class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this._client);
  final SupabaseClient _client;

  static const _sessionSelect = '*, session_members(*, member_items(*))';

  @override
  Future<OrderSession> createSession(OrderSession session) async {
    final response = await _client
        .from('sessions')
        .insert(SessionModel.fromEntity(session).toJson())
        .select(_sessionSelect)
        .single();
    return SessionModel.fromJson(response).toEntity();
  }

  @override
  Future<OrderSession> getSession(String sessionId) async {
    final response = await _client
        .from('sessions')
        .select(_sessionSelect)
        .eq('id', sessionId)
        .single();
    return SessionModel.fromJson(response).toEntity();
  }

  @override
  Stream<List<SessionMember>> watchMembers(String sessionId) => _client
      .from('session_members')
      .stream(primaryKey: ['id'])
      .eq('session_id', sessionId)
      .order('created_at')
      .map(
        (rows) => rows
            .map(MemberModel.fromJson)
            .map((model) => model.toEntity())
            .toList(),
      );
}
