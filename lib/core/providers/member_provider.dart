import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data_provider.dart';
import '../../domain/entities/member_entity.dart';

final memberProvider = Provider<List<MemberEntity>>((ref) {
  return ref.watch(membersProvider);
});
