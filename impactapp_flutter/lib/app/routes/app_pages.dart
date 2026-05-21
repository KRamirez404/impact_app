import 'package:get/get.dart';
import '../../features/auth/presentation/bindings/auth_binding.dart';
import '../../features/auth/presentation/bindings/profile_binding.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/campaigns/presentation/bindings/campaign_binding.dart';
import '../../features/campaigns/presentation/pages/campaign_detail_page.dart';
import '../../features/campaigns/presentation/pages/explore_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/bindings/home_binding.dart';
import '../../features/campaigns/presentation/pages/create_campaign_page.dart';
import '../../features/campaigns/presentation/pages/donate_page.dart';
import '../../features/collection_points/presentation/bindings/collection_point_binding.dart';
import '../../features/collection_points/presentation/pages/collection_point_list_page.dart';
import '../../features/collection_points/presentation/pages/create_collection_point_page.dart';
import '../../features/ratings/presentation/bindings/rating_binding.dart';
import '../../features/ratings/presentation/pages/rate_campaign_page.dart';
import '../../features/verification/presentation/bindings/verification_binding.dart';
import '../../features/verification/presentation/pages/upload_support_page.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      bindings: [AuthBinding()],
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginPage(),
      bindings: [AuthBinding()],
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => RegisterPage(),
      bindings: [AuthBinding()],
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => HomePage(),
      bindings: [AuthBinding(), CampaignBinding(), HomeBinding()],
    ),
    GetPage(
      name: AppRoutes.explore,
      page: () => ExplorePage(),
      bindings: [AuthBinding(), CampaignBinding()],
    ),
    GetPage(
      name: '${AppRoutes.campaignDetail}/:id',
      page: () => CampaignDetailPage(),
      bindings: [AuthBinding(), CampaignBinding()],
    ),
    GetPage(
      name: AppRoutes.createCampaign,
      page: () => CreateCampaignPage(),
      bindings: [CampaignBinding(), CollectionPointBinding()],
    ),
    GetPage(
      name: '${AppRoutes.donate}/:id',
      page: () => DonatePage(),
      bindings: [CampaignBinding()],
    ),
    GetPage(
      name: '${AppRoutes.uploadSupport}/:id',
      page: () => UploadSupportPage(),
      bindings: [VerificationBinding()],
    ),
    GetPage(
      name: '${AppRoutes.collectionPoints}/:id',
      page: () => CollectionPointListPage(),
      bindings: [CollectionPointBinding()],
    ),
    GetPage(
      name: '${AppRoutes.collectionPoints}/:id/create',
      page: () => CreateCollectionPointPage(),
      bindings: [CollectionPointBinding()],
    ),
    GetPage(
      name: '${AppRoutes.rate}/:id',
      page: () => RateCampaignPage(),
      bindings: [RatingBinding()],
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => ProfilePage(),
      bindings: [AuthBinding(), CampaignBinding(), ProfileBinding()],
    ),
  ];
}
