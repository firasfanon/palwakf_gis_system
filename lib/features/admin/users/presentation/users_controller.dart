import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/user_account.dart';
import '../../data/user_repository.dart';

// Users Controller using AsyncNotifier (Riverpod 2.x)
class UsersController extends AsyncNotifier<List<UserAccount>> {
  /// AsyncNotifier.build may run more than once (refresh / dependency changes).
  /// Avoid `late final` assignment inside build to prevent
  /// LateInitializationError ("already been initialized").
  UserRepository get _repo => ref.read(userRepositoryProvider);

  @override
  Future<List<UserAccount>> build() async {
    return loadUsers();
  }

  Future<List<UserAccount>> loadUsers() async {
    final users = await _repo.fetchUsers();
    state = AsyncValue.data(users);
    return users;
  }

  Future<void> create(UserAccount user) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createUser(user);
      await loadUsers();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateUser(UserAccount user) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateUser(user);
      await loadUsers();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> delete(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteUser(userId);
      await loadUsers();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Repository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// Users Controller Provider
final usersControllerProvider =
    AsyncNotifierProvider<UsersController, List<UserAccount>>(() {
  return UsersController();
});
