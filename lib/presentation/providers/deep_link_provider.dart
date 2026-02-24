import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import '../../core/utils/link_utils.dart';

class DeepLinkNotifier extends StateNotifier<Uri?> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  DeepLinkNotifier() : super(null) {
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Get the initial link if the app was opened via a deep link
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        state = initialUri;
      }
    } catch (e) {
      // Handle error if needed
    }

    // Listen for incoming deep links while the app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        state = uri;
      },
      onError: (err) {
        // Handle error if needed
      },
    );
  }

  void clearLink() {
    state = null;
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }
}

//Provider for deep link state
final deepLinkProvider = StateNotifierProvider<DeepLinkNotifier, Uri?>((ref) {
  return DeepLinkNotifier();
});

//Provider to check if there's a pending location from a link
final pendingLocationProvider = Provider<LocationLinkData?>((ref) {
  final uri = ref.watch(deepLinkProvider);
  
  if(uri == null) {
    return null;
  }

  return LinkUtils.parseLocationLink(uri);
});