import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emartprovider/constant/constants.dart';
import 'package:emartprovider/controller/global_setting_conroller.dart';
import 'package:emartprovider/firebase_options.dart';
import 'package:emartprovider/model/mail_setting.dart';
import 'package:emartprovider/model/user.dart';
import 'package:emartprovider/services/localization_service.dart';
import 'package:emartprovider/services/notification_service.dart';
import 'package:emartprovider/services/preferences.dart';
import 'package:emartprovider/themes/app_colors.dart';
import 'package:emartprovider/themes/styles.dart';
import 'package:emartprovider/ui/splash_screen.dart';
import 'package:emartprovider/utils/dark_theme_provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Preferences.initPref();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );
  initializeDateFormatting();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static User? currentUser;
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  NotificationService notificationService = NotificationService();

  notificationInit() {
    notificationService.initInfo().then((value) async {
      String token = await NotificationService.getToken();
      log(":::::::TOKEN:::::: $token");
    });
  }

  @override
  void initState() {
    notificationInit();
    initializeFlutterFire();
    getCurrentAppTheme();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  void initializeFlutterFire() async {
    try {
      await FirebaseFirestore.instance
          .collection(Setting)
          .doc('vendor')
          .get()
          .then((value) {
        isSubscriptionModelApplied = value.data()!['subscription_model'];
      });

      /// Wait for Firebase to initialize and set `_initialized` state to true
      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("ContactUs")
          .get()
          .then((value) {
        adminEmail = value.data()!['Email'].toString();
      });
      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("Version")
          .get()
          .then((value) {
        appVersion = value.data()!['app_version'].toString();
        providerUrl = value.data()!['providerUrl'].toString();
      });
      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("googleMapKey")
          .get()
          .then((value) {
        GOOGLE_API_KEY = value.data()!['key'].toString();
      });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("notification_setting")
          .get()
          .then((value) {
        print(value.data());
        senderId = value.data()!['senderId'].toString();
        jsonNotificationFileURL = value.data()!['serviceJson'].toString();
      });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("globalSettings")
          .get()
          .then((value) {
        AppColors.colorPrimary = Color(int.parse(value
            .data()!['provider_app_color']
            .toString()
            .replaceFirst("#", "0xff")));
      });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("DriverNearBy")
          .get()
          .then((value) {
        selectedMapType = value.data()!['selectedMapType'].toString();
      });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("emailSetting")
          .get()
          .then((value) {
        if (value.exists) {
          mailSettings = MailSettings.fromJson(value.data()!);
        }
      });
    } catch (e) {
      log("$e==========ERROR");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    getCurrentAppTheme();
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme =
        await themeChangeProvider.darkThemePreference.getTheme();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        return themeChangeProvider;
      },
      child: Consumer<DarkThemeProvider>(
        builder: (context, value, child) {
          return GetMaterialApp(
              navigatorKey: navigatorKey,
              title: 'eMart Provider',
              debugShowCheckedModeBanner: false,
              theme: Styles.themeData(
                  themeChangeProvider.darkTheme == 0
                      ? true
                      : themeChangeProvider.darkTheme == 1
                          ? false
                          : themeChangeProvider.getSystemThem(),
                  context),
              locale: LocalizationService.locale,
              fallbackLocale: LocalizationService.locale,
              translations: LocalizationService(),
              builder: EasyLoading.init(),
              home: GetBuilder<GlobalSettingController>(
                  init: GlobalSettingController(),
                  builder: (context) {
                    return const SplashScreen();
                  }));
        },
      ),
    );
  }
}
