import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:frontend/core/di/dependencies.dart';
import 'package:frontend/core/routes/app_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  // URL dạng /weekly/doc/w12-doc1 thay vì /#/weekly/doc/w12-doc1. Server phải trả index.html cho
  // mọi đường dẫn không phải API (backend/src/main.ts đã làm). Không ảnh hưởng Android/iOS.
  usePathUrlStrategy();
  setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: MaterialApp.router(
        title: 'IELTS Hub',
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}
