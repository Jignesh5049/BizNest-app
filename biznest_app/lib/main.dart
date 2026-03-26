import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biznest_core/biznest_core.dart';
import 'core/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (non-optional) to match previous behavior.
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://timkzcxmicogoukjliat.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpbWt6Y3htaWNvZ291a2psaWF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA3MDY4NDUsImV4cCI6MjA4NjI4Mjg0NX0.4S2h3SqisoDyG75x2j6Vug8N2dl7wJkVfpPLQnlY0Tc',
    ),
  );

  runApp(const BizNestApp());
}

class BizNestApp extends StatefulWidget {
  const BizNestApp({super.key});

  @override
  State<BizNestApp> createState() => _BizNestAppState();
}

class _BizNestAppState extends State<BizNestApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc()..add(AuthCheckRequested());
    _router = createRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider.value(value: _authBloc)],
      child: MaterialApp.router(
        title: 'BizNest',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}
