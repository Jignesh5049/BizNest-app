import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, AuthException, AuthChangeEvent;
import '../../../core/services/api_service.dart';
import '../../../core/services/token_service.dart';

// ==================== AUTH EVENTS ====================
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String role;
  AuthLoginRequested({
    required this.email,
    required this.password,
    this.role = 'business',
  });
  @override
  List<Object?> get props => [email, password, role];
}

class AuthSignupRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String role;
  final String? phone;
  AuthSignupRequested({
    required this.name,
    required this.email,
    required this.password,
    this.role = 'business',
    this.phone,
  });
  @override
  List<Object?> get props => [name, email, password, role, phone];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthBusinessUpdated extends AuthEvent {
  final Map<String, dynamic> business;
  AuthBusinessUpdated(this.business);
  @override
  List<Object?> get props => [business];
}

// ==================== AUTH STATES ====================
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? business;
  final String role;

  AuthAuthenticated({required this.user, this.business, required this.role});

  bool get isBusinessOwner => role == 'business';
  bool get isCustomer => role == 'customer';
  bool get hasOnboarded => business?['isOnboarded'] == true;
  String get userName => user['name'] ?? '';

  @override
  List<Object?> get props => [user, business, role];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ==================== AUTH BLOC ====================
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _api = ApiService();
  final TokenService _tokenService = TokenService();
  final _supabase = Supabase.instance.client;

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckAuth);
    on<AuthLoginRequested>(_onLogin);
    on<AuthSignupRequested>(_onSignup);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthBusinessUpdated>(_onBusinessUpdated);

    // Listen to Supabase auth state changes (only if using Supabase)
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        add(AuthCheckRequested());
      }
    });
  }

  Future<void> _onCheckAuth(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // First check if we have a JWT token from direct auth
      final hasJwt = await _tokenService.hasJwtToken();
      if (hasJwt) {
        final response = await _api.getMe();
        final data = response.data;
        emit(
          AuthAuthenticated(
            user: {
              '_id': data['_id'],
              'name': data['name'],
              'email': data['email'],
              'phone': data['phone'],
            },
            business: data['business'],
            role: data['role'] ?? 'business',
          ),
        );
        return;
      }

      // Then check Supabase session
      final session = _supabase.auth.currentSession;
      if (session == null) {
        emit(AuthUnauthenticated());
        return;
      }

      // Fetch user profile from our backend using Supabase token
      final response = await _api.getMe();
      final data = response.data;

      emit(
        AuthAuthenticated(
          user: {
            '_id': data['_id'],
            'name': data['name'],
            'email': data['email'],
            'phone': data['phone'],
          },
          business: data['business'],
          role: data['role'] ?? 'business',
        ),
      );
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Try direct API login first (for existing MongoDB users)
      try {
        final response = await _api.login({
          'email': event.email,
          'password': event.password,
          'role': event.role,
        });

        final data = response.data;
        final token = data['token'];

        // Store JWT token
        await _tokenService.setJwtToken(token);

        emit(
          AuthAuthenticated(
            user: {
              '_id': data['_id'],
              'name': data['name'],
              'email': data['email'],
              'phone': data['phone'],
            },
            business: data['business'],
            role: data['role'] ?? event.role,
          ),
        );
        return;
      } catch (directAuthError) {
        // Direct auth failed, try Supabase
        try {
          final authResponse = await _supabase.auth.signInWithPassword(
            email: event.email,
            password: event.password,
          );

          if (authResponse.session == null) {
            emit(AuthError('Login failed. Please try again.'));
            return;
          }

          // Sync user with our backend and get profile
          final response = await _api.syncUser({
            'email': event.email,
            'role': event.role,
            'supabaseId': authResponse.user!.id,
          });

          final data = response.data;

          emit(
            AuthAuthenticated(
              user: {
                '_id': data['_id'],
                'name': data['name'],
                'email': data['email'],
                'phone': data['phone'],
              },
              business: data['business'],
              role: data['role'] ?? event.role,
            ),
          );
        } on AuthException catch (e) {
          emit(AuthError(e.message));
        }
      }
    } catch (e) {
      final msg = e.toString().contains('DioException')
          ? 'Invalid email or password'
          : e.toString();
      emit(AuthError(msg));
    }
  }

  Future<void> _onSignup(
    AuthSignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Try direct API signup first
      try {
        final response = await _api.signup({
          'name': event.name,
          'email': event.email,
          'password': event.password,
          'role': event.role,
          'phone': event.phone ?? '',
        });

        final data = response.data;
        if (data['token'] != null) {
          // Store JWT token for direct auth users
          await _tokenService.setJwtToken(data['token']);
        }

        emit(
          AuthAuthenticated(
            user: {
              '_id': data['_id'],
              'name': data['name'],
              'email': data['email'],
              'phone': data['phone'],
            },
            business: data['business'],
            role: data['role'] ?? event.role,
          ),
        );
        return;
      } catch (directAuthError) {
        // Direct signup failed, try Supabase
        try {
          final authResponse = await _supabase.auth.signUp(
            email: event.email,
            password: event.password,
            data: {'name': event.name, 'role': event.role},
          );

          if (authResponse.user == null) {
            emit(AuthError('Signup failed. Please try again.'));
            return;
          }

          // Auto sign-in after signup
          if (authResponse.session == null) {
            await _supabase.auth.signInWithPassword(
              email: event.email,
              password: event.password,
            );
          }

          // Create user in our backend
          final response = await _api.signup({
            'name': event.name,
            'email': event.email,
            'password': event.password,
            'role': event.role,
            'phone': event.phone ?? '',
            'supabaseId': authResponse.user!.id,
          });

          final data = response.data;

          emit(
            AuthAuthenticated(
              user: {
                '_id': data['_id'],
                'name': data['name'],
                'email': data['email'],
                'phone': data['phone'],
              },
              business: data['business'],
              role: data['role'] ?? event.role,
            ),
          );
        } on AuthException catch (e) {
          emit(AuthError(e.message));
        }
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Clear JWT token
    await _tokenService.clearAllTokens();
    // Sign out from Supabase
    await _supabase.auth.signOut();
    emit(AuthUnauthenticated());
  }

  void _onBusinessUpdated(AuthBusinessUpdated event, Emitter<AuthState> emit) {
    final current = state;
    if (current is AuthAuthenticated) {
      emit(
        AuthAuthenticated(
          user: current.user,
          business: event.business,
          role: current.role,
        ),
      );
    }
  }
}
