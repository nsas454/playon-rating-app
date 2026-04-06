import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/game_detail_screen.dart';
import 'screens/my_screen.dart';
import 'screens/entry_list_screen.dart';
import 'screens/rating_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://dneacdxkuawarviiidtq.supabase.co',
    anonKey: 'sb_publishable_ALyYTYAk4gr6t9-LeZigsw_7yxPE3__',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  runApp(const PlayOnApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _Shell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/rating', builder: (_, __) => const RatingScreen()),
        GoRoute(path: '/my', builder: (_, __) => const MyScreen()),
      ],
    ),
    GoRoute(
      path: '/game/:slug',
      builder: (_, state) => GameDetailScreen(slug: state.pathParameters['slug']!),
    ),
    GoRoute(path: '/my/entry', builder: (_, __) => const EntryListScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
  ],
);

class PlayOnApp extends StatelessWidget {
  const PlayOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PLAYONレーティング',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja'), Locale('en')],
      locale: const Locale('ja'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      routerConfig: _router,
    );
  }
}

class _Shell extends StatelessWidget {
  final Widget child;
  const _Shell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/rating')) currentIndex = 1;
    if (location.startsWith('/my')) currentIndex = 2;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/'); break;
            case 1: context.go('/rating'); break;
            case 2: context.go('/my'); break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '大会'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'レーティング'),
          NavigationDestination(icon: Icon(Icons.person), label: 'マイページ'),
        ],
      ),
    );
  }
}
