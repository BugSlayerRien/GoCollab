import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/partner.dart';
import '../models/communication_log_model.dart';
import '../models/meeting_model.dart';
import '../models/partner_model.dart';
import '../models/sponsorship_model.dart';

class PartnershipRemoteDataSource {
  PartnershipRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<PartnerModel>> getPartners() async {
    final rows = await _client.from('partners').select().order('name');
    return (rows as List).map((r) => PartnerModel.fromMap(r as Map<String, dynamic>)).toList();
  }

  Future<PartnerModel> getPartnerById(String id) async {
    final row = await _client.from('partners').select().eq('id', id).single();
    return PartnerModel.fromMap(row);
  }

  Future<void> createPartner(PartnerModel partner) async {
    await _client.from('partners').insert(partner.toInsertMap());
  }

  Future<void> updateCollaborationStatus(String partnerId, CollaborationStatus status) async {
    await _client.from('partners').update({'collaboration_status': status.key}).eq('id', partnerId);
  }

  Future<List<SponsorshipModel>> getSponsorships(String partnerId) async {
    final rows = await _client
        .from('sponsorships')
        .select()
        .eq('partner_id', partnerId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => SponsorshipModel.fromMap(r as Map<String, dynamic>)).toList();
  }

  Future<void> createSponsorship(Map<String, dynamic> data) async {
    await _client.from('sponsorships').insert(data);
  }

  Future<List<MeetingModel>> getMeetings(String partnerId) async {
    final rows = await _client
        .from('meetings')
        .select()
        .eq('partner_id', partnerId)
        .order('scheduled_at', ascending: false);
    return (rows as List).map((r) => MeetingModel.fromMap(r as Map<String, dynamic>)).toList();
  }

  Future<void> createMeeting(Map<String, dynamic> data) async {
    await _client.from('meetings').insert(data);
  }

  Future<List<CommunicationLogModel>> getCommunications(String partnerId) async {
    final rows = await _client
        .from('communications')
        .select('*, author:profiles!communications_communicated_by_fkey(full_name)')
        .eq('partner_id', partnerId)
        .order('communicated_at', ascending: false);
    return (rows as List).map((r) => CommunicationLogModel.fromMap(r as Map<String, dynamic>)).toList();
  }

  Future<void> createCommunication({
    required String partnerId,
    required String subject,
    String? message,
    required String direction,
    required String contactMethod,
    required String communicatedBy,
  }) async {
    await _client.from('communications').insert({
      'partner_id': partnerId,
      'subject': subject,
      'message': message,
      'direction': direction,
      'contact_method': contactMethod,
      'communicated_by': communicatedBy,
    });
  }
}
