import 'package:flutter/material.dart';
import 'package:fashio_me/features/auth/presentation/pages/login_page.dart';
import 'package:fashio_me/features/review/presentation/pages/my_reviews_page.dart';
import 'package:fashio_me/features/shop/presentation/pages/order_history_page.dart';
import 'package:fashio_me/features/shop/presentation/pages/shop_page.dart';
import 'package:fashio_me/features/shop/presentation/pages/wishlist_page.dart';
import 'package:fashio_me/features/silhouette/presentation/pages/silhouette_flow_page.dart';
import 'package:fashio_me/features/style_archive/presentation/pages/style_archive_page.dart';

class AppRoutes {
  AppRoutes._();

  static void push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  static void pushReplacement(BuildContext context, Widget page) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  static void pushAndRemoveUntil(BuildContext context, Widget page) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  static void pop(BuildContext context) {
    Navigator.pop(context);
  }

  static void popToFirst(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // Feature destinations are composed here instead of inside feature pages.
  static void toLogin(BuildContext context) =>
      pushReplacement(context, const LoginPage());

  static void toShop(BuildContext context) => push(context, const ShopPage());
  static void toWishlist(BuildContext context) => push(context, const WishlistPage());

  static void toOrderHistory(BuildContext context) =>
      push(context, const OrderHistoryPage());

  static void toMyReviews(BuildContext context) =>
      push(context, const MyReviewsPage());

  static void toStyleArchive(BuildContext context) =>
      push(context, const StyleArchivePage());

  static void toSilhouette(BuildContext context) =>
      push(context, const SilhouetteFlowPage());

  static Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, TO>(
      context,
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    BuildContext context,
    String routeName, {
    required RoutePredicate predicate,
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      predicate,
      arguments: arguments,
    );
  }
}
