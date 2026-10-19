enum LoginProvider { google, kakao, naver }

class Account {
  final String uid;
  final String? name, email;
  const Account({required this.uid, this.name, this.email});
}

class AuthFailure implements Exception {
  final String message;
  final bool cancelled;
  const AuthFailure(this.message, {this.cancelled = false});
}

/// SDK-free contract. Identity is always a Firebase UID, never an email address.
abstract class AuthRepository {
  Set<LoginProvider> get supportedProviders;
  Account? get currentAccount;
  Stream<Account?> get accountChanges;
  Future<void> initialize();
  Future<void> signIn(LoginProvider provider);
  Future<void> signOut();
}
