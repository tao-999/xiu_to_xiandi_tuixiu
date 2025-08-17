import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'native_renderer_method_channel.dart';

abstract class NativeRendererPlatform extends PlatformInterface {
  /// Constructs a NativeRendererPlatform.
  NativeRendererPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeRendererPlatform _instance = MethodChannelNativeRenderer();

  /// The default instance of [NativeRendererPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeRenderer].
  static NativeRendererPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeRendererPlatform] when
  /// they register themselves.
  static set instance(NativeRendererPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
