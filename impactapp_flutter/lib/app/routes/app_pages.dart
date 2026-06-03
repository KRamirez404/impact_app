import 'package:get/get.dart';
import '../../features/auth/presentation/bindings/auth_binding.dart';
import '../../features/auth/presentation/bindings/profile_binding.dart';
import '../../features/auth/presentation/bindings/settings_binding.dart';
import '../../features/auth/presentation/pages/edit_profile_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/settings_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/campaigns/presentation/bindings/campaign_binding.dart';
import '../../features/campaigns/presentation/bindings/donors_binding.dart';
import '../../features/campaigns/presentation/pages/campaign_detail_page.dart';
import '../../features/campaigns/presentation/pages/donors_page.dart';
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
import '../../features/support/presentation/bindings/support_binding.dart';
import '../../features/support/presentation/pages/support_home_page.dart';
import '../../features/support/presentation/pages/support_campaign_detail_page.dart';
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
    GetPage(
      name: AppRoutes.editProfile,
      page: () => EditProfilePage(),
      bindings: [AuthBinding()],
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      bindings: [SettingsBinding()],
    ),
    GetPage(
      name: AppRoutes.donors,
      page: () {
        final args = Get.parameters;
        return DonorsPage(
          campaignId: int.parse(args['id'] ?? '0'),
          campaignTitle: args['title'] ?? 'Campaña',
          campaignImageUrl: (args['imageUrl'] ?? '').isEmpty ? null : args['imageUrl'],
        );
      },
      bindings: [DonorsBinding()],
    ),
    GetPage(
      name: AppRoutes.supportHome,
      page: () => SupportHomePage(),
      bindings: [AuthBinding(), CampaignBinding(), SupportBinding()],
    ),
    GetPage(
      name: '${AppRoutes.supportCampaignDetail}/:id',
      page: () => SupportCampaignDetailPage(),
      bindings: [AuthBinding(), CampaignBinding(), SupportBinding()],
    ),
  ];
}
