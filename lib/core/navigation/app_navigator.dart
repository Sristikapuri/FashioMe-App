import 'package:flutter/widgets.dart';

/// Attached to the root [MaterialApp] so code outside the widget tree
/// (e.g. the Dio auth interceptor) can navigate without a [BuildContext].
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
