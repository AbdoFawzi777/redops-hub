import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../domain/entities/chat_message.dart';

final chatDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource();
});

final chatMessagesStreamProvider = StreamProvider<List<ChatMessage>>((ref) {
  return ref.watch(chatDataSourceProvider).getMessagesStream();
});

class ChatController extends StateNotifier<AsyncValue<void>> {
  ChatController(this._dataSource, this._ref) : super(const AsyncValue.data(null));
  final ChatRemoteDataSource _dataSource;
  final Ref _ref;

  Future<bool> sendTextMessage(String text) async {
    state = const AsyncValue.loading();
    try {
      final auth = _ref.read(firebaseAuthProvider);
      final user = auth?.currentUser;
      final email = user?.email ?? 'anonymous@redopshub.com';
      final name = user?.displayName ?? email.split('@')[0].toUpperCase();

      await _dataSource.sendMessage(
        senderName: name,
        senderEmail: email,
        text: text,
        isVoice: false,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> sendVoiceMessage(String voiceUrl, int durationSeconds) async {
    state = const AsyncValue.loading();
    try {
      final auth = _ref.read(firebaseAuthProvider);
      final user = auth?.currentUser;
      final email = user?.email ?? 'anonymous@redopshub.com';
      final name = user?.displayName ?? email.split('@')[0].toUpperCase();

      await _dataSource.sendMessage(
        senderName: name,
        senderEmail: email,
        text: '🎤 Voice Message (${durationSeconds}s)',
        isVoice: true,
        voiceUrl: voiceUrl,
        voiceDuration: durationSeconds,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, AsyncValue<void>>((ref) {
  return ChatController(ref.watch(chatDataSourceProvider), ref);
});
