import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

import 'package:carbon_emmision_app/services/firebase_connection.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    if (FirebaseConnection.isEnabled) {
      _firebaseAuth = firebase_auth.FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      final currentUser = _firebaseAuth!.currentUser;
      if (currentUser != null) {
        _status = AuthStatus.authenticated;
        _syncFirebaseUser(currentUser);
      }
      _authSubscription = _firebaseAuth!.authStateChanges().listen(_syncFirebaseUser);
    }
  }

  firebase_auth.FirebaseAuth? _firebaseAuth;
  FirebaseFirestore? _firestore;
  StreamSubscription<firebase_auth.User?>? _authSubscription;

  AuthStatus _status = AuthStatus.unauthenticated;
  String? _uid;
  String? _userEmail;
  String? _userName;
  String? _error;

  AuthStatus get status => _status;
  String? get uid => _uid;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get error => _error;
  bool get isFirebaseEnabled => FirebaseConnection.isEnabled;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  final Map<String, Map<String, String>> _localUsers = {
    'demo@ecowallet.com': {
      'name': 'Abdullah Marjuk',
      'password': '123456',
    },
  };

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading();
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedName = name.trim().isEmpty ? 'EcoWallet User' : name.trim();

    if (!FirebaseConnection.isEnabled) {
      await Future.delayed(const Duration(milliseconds: 450));
      if (_localUsers.containsKey(normalizedEmail)) {
        return _fail('An account with this email already exists.');
      }
      _localUsers[normalizedEmail] = {
        'name': trimmedName,
        'password': password,
      };
      _uid = 'local-${normalizedEmail.hashCode}';
      _userEmail = normalizedEmail;
      _userName = trimmedName;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    }

    try {
      final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      await credential.user?.updateDisplayName(trimmedName);
      await _saveProfileDocument(
        uid: credential.user!.uid,
        name: trimmedName,
        email: normalizedEmail,
        merge: false,
      );
      await _syncFirebaseUser(credential.user);
      return true;
    } on firebase_auth.FirebaseAuthException catch (error) {
      return _fail(_authErrorMessage(error));
    } catch (error) {
      return _fail('Could not create account. ${error.toString()}');
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading();
    final normalizedEmail = email.trim().toLowerCase();

    if (!FirebaseConnection.isEnabled) {
      await Future.delayed(const Duration(milliseconds: 450));
      final user = _localUsers[normalizedEmail];
      if (user == null || user['password'] != password) {
        return _fail('Invalid email or password. Use demo@ecowallet.com / 123456.');
      }
      _uid = 'local-${normalizedEmail.hashCode}';
      _userEmail = normalizedEmail;
      _userName = user['name'];
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    }

    try {
      final credential = await _firebaseAuth!.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      await _syncFirebaseUser(credential.user);
      return true;
    } on firebase_auth.FirebaseAuthException catch (error) {
      return _fail(_authErrorMessage(error));
    } catch (error) {
      return _fail('Could not sign in. ${error.toString()}');
    }
  }

  Future<bool> useDemoAccount() async {
    const demoEmail = 'demo@ecowallet.com';
    const demoPassword = '123456';
    const demoName = 'Abdullah Marjuk';

    if (!FirebaseConnection.isEnabled) {
      _uid = 'local-${demoEmail.hashCode}';
      _userEmail = demoEmail;
      _userName = demoName;
      _error = null;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    }

    _setLoading();
    try {
      final credential = await _firebaseAuth!.signInWithEmailAndPassword(
        email: demoEmail,
        password: demoPassword,
      );
      await _ensureProfileDocument(credential.user!, fallbackName: demoName);
      await _syncFirebaseUser(credential.user);
      return true;
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found' || error.code == 'invalid-credential') {
        try {
          final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
            email: demoEmail,
            password: demoPassword,
          );
          await credential.user?.updateDisplayName(demoName);
          await _saveProfileDocument(
            uid: credential.user!.uid,
            name: demoName,
            email: demoEmail,
            merge: false,
          );
          await _syncFirebaseUser(credential.user);
          return true;
        } on firebase_auth.FirebaseAuthException catch (createError) {
          return _fail(_authErrorMessage(createError));
        }
      }
      return _fail(_authErrorMessage(error));
    } catch (error) {
      return _fail('Could not open demo account. ${error.toString()}');
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final trimmedName = name.trim().isEmpty ? 'EcoWallet User' : name.trim();
    final normalizedEmail = email.trim().isEmpty
        ? (_userEmail ?? 'demo@ecowallet.com')
        : email.trim().toLowerCase();

    if (!FirebaseConnection.isEnabled || _uid == null) {
      if (_userEmail != null && _localUsers.containsKey(_userEmail)) {
        final currentPassword = _localUsers[_userEmail]?['password'] ?? '123456';
        _localUsers.remove(_userEmail);
        _localUsers[normalizedEmail] = {
          'name': trimmedName,
          'password': currentPassword,
        };
      }
      _userName = trimmedName;
      _userEmail = normalizedEmail;
      _error = null;
      notifyListeners();
      return;
    }

    try {
      final user = _firebaseAuth!.currentUser;
      await user?.updateDisplayName(trimmedName);
      await _saveProfileDocument(
        uid: _uid!,
        name: trimmedName,
        email: normalizedEmail,
        merge: true,
      );
      _userName = trimmedName;
      _userEmail = normalizedEmail;
      _error = null;
      notifyListeners();
    } catch (error) {
      _error = 'Profile could not be updated. ${error.toString()}';
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (FirebaseConnection.isEnabled) {
      await _firebaseAuth?.signOut();
    }
    _status = AuthStatus.unauthenticated;
    _uid = null;
    _userEmail = null;
    _userName = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _syncFirebaseUser(firebase_auth.User? user) async {
    if (user == null) {
      _uid = null;
      _userEmail = null;
      _userName = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _uid = user.uid;
    _userEmail = user.email;
    _userName = user.displayName ?? 'EcoWallet User';
    _status = AuthStatus.authenticated;
    _error = null;
    notifyListeners();

    await _ensureProfileDocument(user, fallbackName: _userName ?? 'EcoWallet User');

    try {
      final profile = await _firestore!.collection('users').doc(user.uid).get();
      final data = profile.data();
      if (data != null) {
        _userName = (data['name'] ?? _userName ?? 'EcoWallet User').toString();
        _userEmail = (data['email'] ?? user.email ?? _userEmail ?? '').toString();
        notifyListeners();
      }
    } catch (_) {
      // Keep the authenticated Firebase user even if profile read fails.
    }
  }

  Future<void> _ensureProfileDocument(
    firebase_auth.User user, {
    required String fallbackName,
  }) async {
    final doc = _firestore!.collection('users').doc(user.uid);
    final snapshot = await doc.get();
    if (!snapshot.exists) {
      await _saveProfileDocument(
        uid: user.uid,
        name: user.displayName ?? fallbackName,
        email: user.email ?? '',
        merge: false,
      );
    }
  }

  Future<void> _saveProfileDocument({
    required String uid,
    required String name,
    required String email,
    required bool merge,
  }) async {
    await _firestore!.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'loginEmail': _firebaseAuth?.currentUser?.email ?? email,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!merge) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: merge));
  }

  void _setLoading() {
    _status = AuthStatus.authenticating;
    _error = null;
    notifyListeners();
  }

  bool _fail(String message) {
    _error = message;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }

  String _authErrorMessage(firebase_auth.FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Please use a stronger password with at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
