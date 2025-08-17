import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_renderer_platform_interface.dart';

/// An implementation of [NativeRendererPlatform] that uses method channels.
class MethodChannelNativeRenderer extends NativeRendererPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_renderer');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
