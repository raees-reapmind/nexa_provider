import 'package:emartprovider/constant/constants.dart';
import 'package:emartprovider/constant/show_toast_dialog.dart';
import 'package:emartprovider/main.dart';
import 'package:emartprovider/model/user.dart';
import 'package:emartprovider/services/firebase_helper.dart';
import 'package:emartprovider/services/helper.dart';
import 'package:emartprovider/services/preferences.dart';
import 'package:emartprovider/ui/dashboard/dashboard_screen.dart';
import 'package:emartprovider/ui/subscription_plan_screen/app_not_access_screen.dart';
import 'package:emartprovider/ui/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> passwordController = TextEditingController().obs;
  AutovalidateMode validate = AutovalidateMode.disabled;
  Rx<GlobalKey<FormState>> key = GlobalKey<FormState>().obs;

  login(context) async {
    if (key.value.currentState?.validate() ?? false) {
      key.value.currentState!.save();
      await _loginWithEmailAndPassword(emailController.value.text.trim(),
          passwordController.value.text.trim(), context);
    } else {
      validate = AutovalidateMode.onUserInteraction;
    }
  }

  /// login with email and password with firebase
  /// @param email user email
  /// @param password user password
  _loginWithEmailAndPassword(
      String email, String password, BuildContext context) async {
    ShowToastDialog.showLoader('Logging in, please wait...'.tr);
    dynamic result = await FireStoreUtils.loginWithEmailAndPassword(
        email.trim(), password.trim());
    ShowToastDialog.closeLoader();
    if (result != null && result is User && result.role == 'provider') {
      if (result.active == true) {
        result.active = true;
        Preferences.setString(Preferences.passwordKey, password);
        await FireStoreUtils.updateCurrentUser(result);
        print("result ans:" + result.fcmToken);
        MyAppState.currentUser = result;
        if (MyAppState.currentUser!.section_id.isNotEmpty) {
          await FireStoreUtils.getSectionsById(
                  MyAppState.currentUser!.section_id)
              .then(
            (value) {
              if (value != null) {
                selectedSectionModel = value;
              }
            },
          );
        }

        if ((isSubscriptionModelApplied == true ||
                selectedSectionModel?.adminCommision?.enable == true) &&
            MyAppState.currentUser?.section_id.isNotEmpty == true &&
            MyAppState.currentUser?.subscriptionPlanId == null) {
          Get.offAll(const SubscriptionPlanScreen(), arguments: {
            "isShowAppBar": false,
            "isDropdownDisable":
                MyAppState.currentUser?.section_id.isEmpty == true
                    ? false
                    : true
          });
        } else if ((MyAppState.currentUser?.section_id == null ||
                MyAppState.currentUser?.section_id == '' ||
                MyAppState.currentUser?.subscriptionPlanId == null) &&
            isSubscriptionModelApplied == false) {
          Get.offAll(const DashBoardScreen(),
              arguments: {'user': MyAppState.currentUser});
        } else if (result.subscriptionPlanId == null ||
            isExpire(result) == true) {
          if ((selectedSectionModel != null &&
                  selectedSectionModel?.adminCommision?.enable == false) &&
              isSubscriptionModelApplied == false) {
            Get.offAll(const DashBoardScreen(), arguments: {'user': result});
          } else {
            Get.offAll(const SubscriptionPlanScreen(), arguments: {
              "isShowAppBar": false,
              "isDropdownDisable":
                  MyAppState.currentUser?.section_id.isEmpty == true
                      ? false
                      : true
            });
          }
        } else if (result.subscriptionPlan?.features?.ownerMobileApp == true) {
          Get.offAll(const DashBoardScreen(), arguments: {'user': result});
        } else {
          Get.offAll(const AppNotAccessScreen());
        }
      } else {
        showAlertDialog(
            context,
            'Your account has been disabled, Please contact to admin.'.tr,
            "",
            true);
      }
    } else if (result != null && result is String) {
      showAlertDialog(context, "Couldn't Authenticate".tr, result, true);
    } else {
      showAlertDialog(context, "Couldn't Authenticate".tr,
          'Login failed, Please try again.'.tr, true);
      print("result ans:" + result.toString());
    }
  }

  loginWithApple(BuildContext context) async {
    try {
      ShowToastDialog.showLoader('Logging in, Please wait...'.tr);
      dynamic result = await FireStoreUtils.loginWithApple();
      ShowToastDialog.closeLoader();
      if (result != null && result is User) {
        MyAppState.currentUser = result;
        if (MyAppState.currentUser!.active == true) {
          if (MyAppState.currentUser!.section_id.isNotEmpty) {
            await FireStoreUtils.getSectionsById(
                    MyAppState.currentUser!.section_id)
                .then(
              (value) {
                if (value != null) {
                  selectedSectionModel = value;
                }
              },
            );
          }
          if (MyAppState.currentUser?.subscriptionPlanId == null &&
              isSubscriptionModelApplied == false) {
            Get.offAll(const DashBoardScreen(),
                arguments: {'user': MyAppState.currentUser});
          } else if (result.subscriptionPlanId == null ||
              isExpire(result) == true) {
            if ((selectedSectionModel != null &&
                    selectedSectionModel?.adminCommision?.enable == false) &&
                isSubscriptionModelApplied == false) {
              Get.offAll(const DashBoardScreen(), arguments: {'user': result});
            } else {
              Get.offAll(const SubscriptionPlanScreen(), arguments: {
                "isShowAppBar": false,
                "isDropdownDisable":
                    MyAppState.currentUser?.section_id.isEmpty == true
                        ? false
                        : true
              });
            }
          } else if (result.subscriptionPlan?.features?.ownerMobileApp ==
              true) {
            Get.offAll(const DashBoardScreen(), arguments: {'user': result});
          } else {
            Get.offAll(const AppNotAccessScreen());
          }
        } else {
          showAlertDialog(
              context,
              'Your account has been disabled, Please contact to admin.'.tr,
              "",
              true);
        }
      } else if (result != null && result is String) {
        showAlertDialog(context, 'Error'.tr, result.tr, true);
      } else {
        showAlertDialog(
            context, 'Error'.tr, "Couldn't login with apple.".tr, true);
      }
    } catch (e, s) {
      ShowToastDialog.closeLoader();
      print('_LoginScreen.loginWithApple $e $s');
      showAlertDialog(
          context, 'Error'.tr, "Couldn't login with apple.".tr, true);
    }
  }
}
