import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repo_viewer/auth/application/auth_notifier.dart';
import 'package:repo_viewer/auth/shared/providers.dart';
import 'package:repo_viewer/core/presentation/routes/app_router.gr.dart';

import '../shared/providers.dart';
import 'routes/app_router.dart';

final initializationProvider = FutureProvider<Unit>((ref) async {
  await ref.read(sembasetProvider).init();
  ref.read(dioProvider)
    ..options = BaseOptions(
      headers: {
        'Accept': 'application/vnd.github.html+json',
      },
    )
    ..interceptors.add(
      ref.read(oAuth2InterceptorProvider),
    );
  final authNotifier = ref.read(authNotifierProvider.notifier);
  await authNotifier.checkAndUpdateAuthState();
  // print('==========>initializationProvider');
  return unit;
});

class AppWidget extends ConsumerWidget {
  AppWidget({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(initializationProvider, (previous, next) {});
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      next.maybeMap(
        orElse: () {},
        authenticated: (_) {
          _appRouter.pushAndPopUntil(
            const StarredReposRoute(),
            predicate: (route) => false,
          );
        },
        unAuthenticated: (_) {
          _appRouter.pushAndPopUntil(
            const SignInRoute(),
            predicate: (route) => false,
          );
        },
      );
    });

    // final value = initializationProvider;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Repo Viewer',
      routerConfig: _appRouter.config(),
    );
  }
}
