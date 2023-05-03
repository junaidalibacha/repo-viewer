// import 'package:auto_route/auto_route.dart';
import 'package:auto_route/auto_route.dart';

import 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends $AppRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: SplashRoute.page, path: '/'),
        AutoRoute(page: SignInRoute.page, path: '/sign-in'),
        AutoRoute(page: AuthorizationRoute.page, path: '/authorization'),
        AutoRoute(page: StarredReposRoute.page, path: '/starred-repos'),
      ];
}
