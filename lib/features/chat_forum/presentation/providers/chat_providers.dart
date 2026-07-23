import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_group.dart';

final chatDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource();
});

// Currently selected group ID state (defaults to 'lobby')
final currentGroupIdProvider = StateProvider<String>((ref) => 'lobby');

// Stream of messages for the active group
final chatMessagesStreamProvider = StreamProvider.autoDispose<List<ChatMessage>>((ref) {
  final groupId = ref.watch(currentGroupIdProvider);
  return ref.watch(chatDataSourceProvider).getMessagesStream(groupId);
});

// Stream of groups available to the current operator
final chatGroupsStreamProvider = StreamProvider.autoDispose<List<ChatGroup>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final email = auth?.currentUser?.email ?? '';
  return ref.watch(chatDataSourceProvider).getGroupsStream(email);
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
      final activeGroupId = _ref.read(currentGroupIdProvider);

      await _dataSource.sendMessage(
        senderName: name,
        senderEmail: email,
        text: text,
        isVoice: false,
        groupId: activeGroupId,
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
      final activeGroupId = _ref.read(currentGroupIdProvider);

      await _dataSource.sendMessage(
        senderName: name,
        senderEmail: email,
        text: '🎤 Voice Message (${durationSeconds}s)',
        isVoice: true,
        voiceUrl: voiceUrl,
        voiceDuration: durationSeconds,
        groupId: activeGroupId,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> deleteMessage(String messageId) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.deleteMessage(messageId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> editMessage(String messageId, String newText) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.editMessage(messageId, newText);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> createNewGroup(String name, String description, List<String> members) async {
    state = const AsyncValue.loading();
    try {
      final auth = _ref.read(firebaseAuthProvider);
      final email = auth?.currentUser?.email ?? 'system@redopshub.com';
      
      await _dataSource.createGroup(
        name: name,
        description: description,
        ownerEmail: email,
        members: members,
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
