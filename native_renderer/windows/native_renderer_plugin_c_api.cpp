#include "include/native_renderer/native_renderer_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "native_renderer_plugin.h"

void NativeRendererPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  native_renderer::NativeRendererPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
