import 'package:flutter/material.dart';

/// Hand-written translation dictionary (no codegen). Add a getter here and
/// fill it in on both [_EnStrings] and [_NeStrings] to translate more text;
/// call sites read it via `context.strings.someLabel`.
abstract class AppStrings {
  static AppStrings of(Locale locale) {
    return locale.languageCode == 'ne'
        ? const _NeStrings()
        : const _EnStrings();
  }

  // Drawer menu
  String get menuTitle;
  String get navHome;
  String get navAiStylist;
  String get navMyWardrobe;
  String get navShopCatalog;
  String get navDiscoverTrends;
  String get navMyOrders;
  String get navMyReviews;
  String get navStyleArchive;
  String get navMyProfile;

  // Bottom nav bar (shorter labels)
  String get tabHome;
  String get tabAiStylist;
  String get tabWardrobe;
  String get tabShop;
  String get tabDiscover;
  String get tabProfile;

  // Settings sheet
  String get settingsTitle;
  String get settingsRefreshCache;
  String get settingsRefreshCacheSubtitle;
  String get settingsPrivacyPolicy;
  String get settingsPrivacyPolicySubtitle;
  String get settingsAbout;
  String get settingsAboutSubtitle;
  String get settingsLanguage;
  String get settingsLanguageSubtitle;
  String get languageEnglish;
  String get languageNepali;
  String get close;

  String get signOut;

  // First-run language picker (shown before login/signup)
  String get chooseLanguageTitle;
  String get chooseLanguageSubtitle;
  String get continueLabel;

  // Biometric (Face ID / fingerprint) lock
  String get settingsBiometric;
  String get settingsBiometricSubtitleOn;
  String get settingsBiometricSubtitleOff;
  String get settingsBiometricUnavailable;
  String get biometricPromptReason;
  String get biometricLockTitle;
  String get biometricLockSubtitle;
  String get biometricLockFailed;
  String get retry;
  String get useLogoutInstead;

  // Authentication
  String get welcomeBack;
  String get signInToContinue;
  String get emailAddress;
  String get emailRequired;
  String get invalidEmail;
  String get password;
  String get passwordRequired;
  String get passwordTooShort;
  String get forgotPassword;
  String get signIn;
  String get createNewAccount;
  String get onboardingTag;
  String get onboardingTitle1;
  String get onboardingSubtitle1;
  String get onboardingTitle2;
  String get onboardingSubtitle2;
  String get onboardingTitle3;
  String get onboardingSubtitle3;
  String get next;
  String get getStarted;
  String get personalInformation;
  String get firstName;
  String get lastName;
  String get username;
  String get gender;
  String get male;
  String get female;
  String get other;
  String get age;
  String get updateProfile;
  String get changePassword;
  String get newPassword;
  String get confirmNewPassword;
  String get updatePassword;
  String get orderHistory;
  String get noOrders;
}

class _EnStrings implements AppStrings {
  const _EnStrings();

  @override
  String get menuTitle => 'FashioMe Menu';
  @override
  String get navHome => 'Home';
  @override
  String get navAiStylist => 'AI Stylist';
  @override
  String get navMyWardrobe => 'My Wardrobe';
  @override
  String get navShopCatalog => 'Shop Catalog';
  @override
  String get navDiscoverTrends => 'Discover Trends';
  @override
  String get navMyOrders => 'My Orders';
  @override
  String get navMyReviews => 'My Reviews';
  @override
  String get navStyleArchive => 'Style Archive';
  @override
  String get navMyProfile => 'My Profile';

  @override
  String get tabHome => 'Home';
  @override
  String get tabAiStylist => 'AI Stylist';
  @override
  String get tabWardrobe => 'Wardrobe';
  @override
  String get tabShop => 'Shop';
  @override
  String get tabDiscover => 'Discover';
  @override
  String get tabProfile => 'Profile';

  @override
  String get settingsTitle => 'Settings & Preferences';
  @override
  String get settingsRefreshCache => 'Refresh Cache & Sync';
  @override
  String get settingsRefreshCacheSubtitle =>
      'Sync wardrobe and recommendations with cloud';
  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';
  @override
  String get settingsPrivacyPolicySubtitle =>
      'Learn how your style data is protected';
  @override
  String get settingsAbout => 'About FashioMe';
  @override
  String get settingsAboutSubtitle => 'Version 1.0.0 • Luxury AI Stylist App';
  @override
  String get settingsLanguage => 'Language';
  @override
  String get settingsLanguageSubtitle => 'Choose your preferred language';
  @override
  String get languageEnglish => 'English';
  @override
  String get languageNepali => 'Nepali';
  @override
  String get close => 'Close';

  @override
  String get signOut => 'Sign Out';

  @override
  String get chooseLanguageTitle => 'Choose your language';
  @override
  String get chooseLanguageSubtitle =>
      'You can change this anytime in Settings.';
  @override
  String get continueLabel => 'Continue';

  @override
  String get settingsBiometric => 'Face ID / Biometric Login';
  @override
  String get settingsBiometricSubtitleOn => 'Enabled — unlock with Face ID';
  @override
  String get settingsBiometricSubtitleOff => 'Off';
  @override
  String get settingsBiometricUnavailable =>
      'Not available on this device (set up Face ID or a fingerprint in your device settings first)';
  @override
  String get biometricPromptReason => 'Unlock FashioMe to continue';
  @override
  String get biometricLockTitle => 'Welcome back';
  @override
  String get biometricLockSubtitle =>
      'Use Face ID or your fingerprint to unlock FashioMe.';
  @override
  String get biometricLockFailed => "Couldn't verify your identity. Try again.";
  @override
  String get retry => 'Try Again';
  @override
  String get useLogoutInstead => 'Use Password Instead';
  @override
  String get welcomeBack => 'Welcome Back';
  @override
  String get signInToContinue => 'Sign in to continue your style journey.';
  @override
  String get emailAddress => 'Email Address';
  @override
  String get emailRequired => 'Email is required.';
  @override
  String get invalidEmail => 'Enter a valid email address.';
  @override
  String get password => 'Password';
  @override
  String get passwordRequired => 'Password is required.';
  @override
  String get passwordTooShort => 'Password must be at least 6 characters.';
  @override
  String get forgotPassword => 'Forgot Password?';
  @override
  String get signIn => 'Sign In';
  @override
  String get createNewAccount => 'Create New Account';
  @override
  String get onboardingTag => 'PERSONALIZED STYLE';
  @override
  String get onboardingTitle1 => 'Your AI Stylist,\nReimagined.';
  @override
  String get onboardingSubtitle1 =>
      'Merging the heritage of the Saree with the edge of modern tailoring.';
  @override
  String get onboardingTitle2 => 'Luxury Meets\nTechnology.';
  @override
  String get onboardingSubtitle2 =>
      'Discover premium fashion recommendations powered by AI intelligence.';
  @override
  String get onboardingTitle3 => 'Create Your\nOwn Identity.';
  @override
  String get onboardingSubtitle3 =>
      'Fashion curated uniquely for your personality and culture.';
  @override
  String get next => 'Next';
  @override
  String get getStarted => 'Continue';
  @override
  String get personalInformation => 'Personal Information';
  @override
  String get firstName => 'First Name';
  @override
  String get lastName => 'Last Name';
  @override
  String get username => 'Username';
  @override
  String get gender => 'Gender';
  @override
  String get male => 'Male';
  @override
  String get female => 'Female';
  @override
  String get other => 'Other';
  @override
  String get age => 'Age';
  @override
  String get updateProfile => 'Update Profile';
  @override
  String get changePassword => 'Change Password';
  @override
  String get newPassword => 'New Password';
  @override
  String get confirmNewPassword => 'Confirm New Password';
  @override
  String get updatePassword => 'Update Password';
  @override
  String get orderHistory => 'Order History';
  @override
  String get noOrders => 'No orders yet.';
}

class _NeStrings implements AppStrings {
  const _NeStrings();

  @override
  String get menuTitle => 'फेशियोमी मेनु';
  @override
  String get navHome => 'Home';
  @override
  String get navAiStylist => 'AI Stylist';
  @override
  String get navMyWardrobe => 'मेरो वार्डरोब';
  @override
  String get navShopCatalog => 'Shop';
  @override
  String get navDiscoverTrends => 'ट्रेन्डहरू';
  @override
  String get navMyOrders => 'मेरा अर्डरहरू';
  @override
  String get navMyReviews => 'मेरो Reviews';
  @override
  String get navStyleArchive => 'Style Archive';
  @override
  String get navMyProfile => 'मेरो प्रोफाइल';

  @override
  String get tabHome => 'Home';
  @override
  String get tabAiStylist => 'एआई स्टाइलिस्ट';
  @override
  String get tabWardrobe => 'वार्डरोब';
  @override
  String get tabShop => 'Shop';
  @override
  String get tabDiscover => 'Discover';
  @override
  String get tabProfile => 'प्रोफाइल';

  @override
  String get settingsTitle => 'Settings';
  @override
  String get settingsRefreshCache => 'Refresh & Sync';
  @override
  String get settingsRefreshCacheSubtitle =>
      'Wardrobe र recommendations cloud सँग sync गर्नुहोस्';
  @override
  String get settingsPrivacyPolicy => 'गोपनीयता नीति';
  @override
  String get settingsPrivacyPolicySubtitle =>
      'तपाईंको स्टाइल डाटा कसरी सुरक्षित छ भनेर जान्नुहोस्';
  @override
  String get settingsAbout => 'About FashioMe';
  @override
  String get settingsAboutSubtitle => 'Version 1.0.0 • Luxury AI Stylist App';
  @override
  String get settingsLanguage => 'भाषा';
  @override
  String get settingsLanguageSubtitle => 'आफ्नो मनपर्ने भाषा छान्नुहोस्';
  @override
  String get languageEnglish => 'English';
  @override
  String get languageNepali => 'नेपाली';
  @override
  String get close => 'बन्द गर्नुहोस्';

  @override
  String get signOut => 'Sign Out';

  @override
  String get chooseLanguageTitle => 'आफ्नो भाषा छान्नुहोस्';
  @override
  String get chooseLanguageSubtitle =>
      'यो भाषा पछि Settings बाट पनि परिवर्तन गर्न सक्नुहुन्छ।';
  @override
  String get continueLabel => 'अगाडि बढ्नुहोस्';

  @override
  String get settingsBiometric => 'Face ID / Biometric Login';
  @override
  String get settingsBiometricSubtitleOn => 'सक्षम — फेस आईडीले अनलक गर्नुहोस्';
  @override
  String get settingsBiometricSubtitleOff => 'Off';
  @override
  String get settingsBiometricUnavailable =>
      'यो उपकरणमा उपलब्ध छैन (पहिले आफ्नो उपकरणको सेटिङमा फेस आईडी वा फिंगरप्रिन्ट सेटअप गर्नुहोस्)';
  @override
  String get biometricPromptReason => 'जारी राख्न फेशियोमी अनलक गर्नुहोस्';
  @override
  String get biometricLockTitle => 'Welcome Back';
  @override
  String get biometricLockSubtitle =>
      'फेशियोमी अनलक गर्न फेस आईडी वा फिंगरप्रिन्ट प्रयोग गर्नुहोस्।';
  @override
  String get biometricLockFailed =>
      'पहिचान प्रमाणित गर्न सकिएन। फेरि प्रयास गर्नुहोस्।';
  @override
  String get retry => 'फेरि प्रयास गर्नुहोस्';
  @override
  String get useLogoutInstead => 'बरु पासवर्ड प्रयोग गर्नुहोस्';
  @override
  String get welcomeBack => 'Welcome Back';
  @override
  String get signInToContinue =>
      'आफ्नो style journey जारी राख्न Sign in गर्नुहोस्।';
  @override
  String get emailAddress => 'Email Address';
  @override
  String get emailRequired => 'इमेल आवश्यक छ।';
  @override
  String get invalidEmail => 'मान्य इमेल ठेगाना लेख्नुहोस्।';
  @override
  String get password => 'Password';
  @override
  String get passwordRequired => 'पासवर्ड आवश्यक छ।';
  @override
  String get passwordTooShort => 'पासवर्ड कम्तीमा ६ अक्षरको हुनुपर्छ।';
  @override
  String get forgotPassword => 'Password बिर्सनुभयो?';
  @override
  String get signIn => 'Sign In';
  @override
  String get createNewAccount => 'नयाँ Account बनाउनुहोस्';
  @override
  String get onboardingTag => 'तपाईंका लागि विशेष शैली';
  @override
  String get onboardingTitle1 => 'तपाईंको एआई स्टाइलिस्ट,\nनयाँ रूपमा।';
  @override
  String get onboardingSubtitle1 =>
      'सारीको परम्परालाई आधुनिक सिलाइको शैलीसँग जोड्नुहोस्।';
  @override
  String get onboardingTitle2 => 'विलासिता र\nप्रविधिको मेल।';
  @override
  String get onboardingSubtitle2 =>
      'एआईद्वारा तयार गरिएका उत्कृष्ट फेसन सिफारिसहरू पाउनुहोस्।';
  @override
  String get onboardingTitle3 => 'आफ्नो\nपहिचान बनाउनुहोस्।';
  @override
  String get onboardingSubtitle3 =>
      'तपाईंको व्यक्तित्व र संस्कृतिअनुसार तयार गरिएको फेसन।';
  @override
  String get next => 'अर्को';
  @override
  String get getStarted => 'अगाडि बढ्नुहोस्';
  @override
  String get personalInformation => 'व्यक्तिगत जानकारी';
  @override
  String get firstName => 'नाम';
  @override
  String get lastName => 'थर';
  @override
  String get username => 'प्रयोगकर्ता नाम';
  @override
  String get gender => 'लिङ्ग';
  @override
  String get male => 'पुरुष';
  @override
  String get female => 'महिला';
  @override
  String get other => 'अन्य';
  @override
  String get age => 'उमेर';
  @override
  String get updateProfile => 'प्रोफाइल अपडेट गर्नुहोस्';
  @override
  String get changePassword => 'पासवर्ड परिवर्तन गर्नुहोस्';
  @override
  String get newPassword => 'नयाँ पासवर्ड';
  @override
  String get confirmNewPassword => 'नयाँ पासवर्ड पुनः लेख्नुहोस्';
  @override
  String get updatePassword => 'पासवर्ड अपडेट गर्नुहोस्';
  @override
  String get orderHistory => 'अर्डर इतिहास';
  @override
  String get noOrders => 'अहिलेसम्म कुनै अर्डर छैन।';
}
