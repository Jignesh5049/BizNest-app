import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, AuthException, AuthChangeEvent;
import 'package:dio/dio.dart';
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
  AuthLoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
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
        try {
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
        } on DioException catch (e) {
          // Token expired or server unreachable, clear and proceed
          await _tokenService.clearJwtToken();
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError) {
            // Server is unreachable, emit unauthenticated
            emit(AuthUnauthenticated());
            return;
          }
          rethrow;
        }
      }

      // Then check Supabase session
      final session = _supabase.auth.currentSession;
      if (session == null) {
        emit(AuthUnauthenticated());
        return;
      }

      // Fetch user profile from our backend using Supabase token
      try {
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
      } on DioException catch (e) {
        // If server is unreachable, still emit authenticated with Supabase user
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          emit(
            AuthAuthenticated(
              user: {
                '_id': session.user.id,
                'name': session.user.userMetadata?['name'] ?? 'User',
                'email': session.user.email ?? '',
                'phone': session.user.userMetadata?['phone'],
              },
              role: session.user.userMetadata?['role'] ?? 'business',
            ),
          );
          return;
        }
        rethrow;
      }
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
            role: data['role'] ?? 'business',
          ),
        );
        return;
      } on DioException catch (dioError) {
        // Check for timeout errors specifically
        if (dioError.type == DioExceptionType.connectionTimeout ||
            dioError.type == DioExceptionType.receiveTimeout) {
          emit(
            AuthError(
              'Login timeout: ${dioError.error ?? 'Request took too long. Check your connection or server status.'}',
            ),
          );
          return;
        }

        if (dioError.type == DioExceptionType.connectionError) {
          emit(
            AuthError(
              'Connection failed: Cannot reach server at 192.168.6.14:5000. Make sure:\n'
              '1. Your device is on the same network\n'
              '2. The server is running\n'
              '3. The IP address is correct',
            ),
          );
          return;
        }

        // For other API errors, try Supabase as fallback
        if (dioError.response?.statusCode != 401) {
          rethrow;
        }

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
              role: data['role'] ?? 'business',
            ),
          );
        } on AuthException catch (e) {
          emit(AuthError(e.message));
        }
      }
    } catch (e) {
      String errorMsg = _getErrorMessage(e);
      emit(AuthError(errorMsg));
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
      } on DioException catch (dioError) {
        // Check for timeout errors specifically
        if (dioError.type == DioExceptionType.connectionTimeout ||
            dioError.type == DioExceptionType.receiveTimeout) {
          emit(
            AuthError(
              'Signup timeout: ${dioError.error ?? 'Request took too long. Check your connection or server status.'}',
            ),
          );
          return;
        }

        if (dioError.type == DioExceptionType.connectionError) {
          emit(
            AuthError(
              'Connection failed: Cannot reach server at 192.168.6.14:5000. Make sure:\n'
              '1. Your device is on the same network\n'
              '2. The server is running\n'
              '3. The IP address is correct',
            ),
          );
          return;
        }

        // For other errors, try Supabase as fallback
        if (dioError.response?.statusCode != 400 &&
            dioError.response?.statusCode != 500 &&
            dioError.response?.statusCode != null) {
          rethrow;
        }

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

  /// Helper method to format error messages
  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout) {
        return 'Connection timeout: Request took too long to respond. Please check your server connection.';
      } else if (error.type == DioExceptionType.receiveTimeout) {
        return 'Receive timeout: Server took too long to respond. Please try again.';
      } else if (error.type == DioExceptionType.connectionError) {
        return 'Network error: Cannot reach the server. Please check your internet connection and server status.';
      } else if (error.response?.statusCode == 401) {
        return 'Invalid email or password.';
      } else if (error.response?.statusCode == 400) {
        return error.response?.data['message'] ??
            'Invalid request. Please check your input.';
      } else if (error.response?.statusCode == 500) {
        return 'Server error. Please try again later.';
      }
      return error.message ?? 'An error occurred. Please try again.';
    }
    return error.toString();
  }
}
