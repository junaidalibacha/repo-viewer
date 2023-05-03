import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

@RoutePage()
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(MdiIcons.github, size: 150),
            LinearProgressIndicator(),
            // ElevatedButton(
            //   onPressed: () => context.pushRoute(const SignInRoute()),
            //   child: const Text('data'),
            // ),
          ],
        ),
      ),
    );
  }
}
