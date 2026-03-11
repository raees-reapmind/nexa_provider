import 'package:emartprovider/constant/constants.dart';
import 'package:emartprovider/main.dart';
import 'package:emartprovider/model/user.dart';
import 'package:emartprovider/services/firebase_helper.dart';
import 'package:emartprovider/services/preferences.dart';
import 'package:emartprovider/ui/add_service/all_services_screen.dart';
import 'package:emartprovider/ui/auth/auth_screen.dart';
import 'package:emartprovider/ui/bank_details/bank_details_Screen.dart';
import 'package:emartprovider/ui/booking_list/booking_list_screen.dart';
import 'package:emartprovider/ui/chat_screen/inbox_screen.dart';
import 'package:emartprovider/ui/coupon/coupon_list.dart';
import 'package:emartprovider/ui/privacyPolicy/privacy_policy.dart';
import 'package:emartprovider/ui/profile/profile_screen.dart';
import 'package:emartprovider/ui/subscription_plan_screen/subscription_history_screen.dart';
import 'package:emartprovider/ui/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:emartprovider/ui/termsAndCondition/terms_and_codition.dart';
import 'package:emartprovider/ui/wallet/wallet_screen.dart';
import 'package:emartprovider/ui/worker/worker_list.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashBoardController extends GetxController {
  RxBool isLoading = true.obs;
  final fireStoreUtils = FireStoreUtils();

  final drawerItems = [
    DrawerItem('Booking List'.tr, "assets/icons/ic_order.svg"),
    DrawerItem('All Service'.tr, "assets/icons/ic_log.svg"),
    DrawerItem('Worker'.tr, "assets/icons/ic_worker.svg"),
    DrawerItem('Coupon'.tr, "assets/icons/ic_worker.svg"),
    DrawerItem('My Wallet'.tr, "assets/icons/ic_wallet.svg"),
    if (selectedSectionModel?.adminCommision?.enable == true ||
        isSubscriptionModelApplied == true)
      DrawerItem('Subscription'.tr, "assets/icons/ic_subscription.svg"),
    DrawerItem('Subscription History'.tr, "assets/icons/ic_history.svg"),
    DrawerItem('Withdraw Method'.tr, "assets/icons/ic_wallet.svg"),
    DrawerItem('Profile'.tr, "assets/icons/ic_profile.svg"),
    DrawerItem('My Inbox'.tr, "assets/icons/ic_chat.svg"),
    DrawerItem(
        'Terms and Condition'.tr, "assets/icons/terms_and_conditions.svg"),
    DrawerItem('Privacy policy'.tr, "assets/icons/privacy_policy.svg"),
    DrawerItem('Log out'.tr, "assets/icons/ic_logout.svg"),
  ];

  getDrawerItemWidget(int pos) {
    if (selectedSectionModel?.adminCommision?.enable == true ||
        isSubscriptionModelApplied == true) {
      switch (pos) {
        case 0:
          return const BookingListScreen();
        case 1:
          return const AllServiceScreen();
        case 2:
          return const AllWorkersScreen();
        case 3:
          return const CouponList();
        case 4:
          return const WalletScreen();
        case 5:
          return const SubscriptionPlanScreen(isDrawer: true);
        case 6:
          return const SubscriptionHistoryScreen();
        case 7:
          return const BankDetailsScreen();
        case 8:
          return const ProfileScreen();
        case 9:
          return const InboxScreen();
        case 10:
          return const TermsAndCondition();
        case 11:
          return const PrivacyPolicy();
        default:
          return const Text("Error");
      }
    } else {
      switch (pos) {
        case 0:
          return const BookingListScreen();
        case 1:
          return const AllServiceScreen();
        case 2:
          return const AllWorkersScreen();
        case 3:
          return const CouponList();
        case 4:
          return const WalletScreen();
        case 5:
          return const SubscriptionHistoryScreen();
        case 6:
          return const BankDetailsScreen();
        case 7:
          return const ProfileScreen();
        case 8:
          return const InboxScreen();
        case 9:
          return const TermsAndCondition();
        case 10:
          return const PrivacyPolicy();
        default:
          return const Text("Error");
      }
    }
  }

  RxInt selectedDrawerIndex = 0.obs;

  onSelectItem(int index) async {
    if (selectedSectionModel?.adminCommision?.enable == true ||
        isSubscriptionModelApplied == true) {
      if (index == 12) {
        MyAppState.currentUser = null;
        await auth.FirebaseAuth.instance.signOut();
        Preferences.clearSharPreference();
        Get.offAll(AuthScreen());
      } else {
        selectedDrawerIndex.value = index;
      }
      Get.back();
    } else {
      if (index == 11) {
        MyAppState.currentUser = null;
        await auth.FirebaseAuth.instance.signOut();
        Preferences.clearSharPreference();
        Get.offAll(AuthScreen());
      } else {
        selectedDrawerIndex.value = index;
      }
      Get.back();
    }
  }

  Rx<User> user = User().obs;
  RxString userId = ''.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();
    getData();
    super.onInit();
  }

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      if (argumentData['user'] != null) {
        user.value = argumentData['user'];
      }
      if (argumentData['userId'] != null) {
        userId.value = argumentData['userId'];
      }
    }
    update();
  }

  getData() async {
    await FireStoreUtils.getCurrentUser(MyAppState.currentUser == null
            ? userId.value
            : MyAppState.currentUser!.userID)
        .then((value) {
      MyAppState.currentUser = value;
      user.value = value!;
    });
    fireStoreUtils.getPlaceHolderImage();
    isLoading.value = false;
  }

  Rx<DateTime> currentBackPressTime = DateTime.now().obs;

  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (now.difference(currentBackPressTime.value) >
        const Duration(seconds: 2)) {
      currentBackPressTime.value = now;
      Get.showSnackbar(
        GetSnackBar(
          message: "Double press to exit".tr,
          snackPosition: SnackPosition.TOP,
        ),
      );
      return Future.value(false);
    }
    return Future.value(true);
  }
}

class DrawerItem {
  String title;
  String icon;

  DrawerItem(this.title, this.icon);
}
