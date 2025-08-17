#ifndef FLUTTER_PLUGIN_NATIVE_RENDERER_PLUGIN_H_
#define FLUTTER_PLUGIN_NATIVE_RENDERER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/texture_registrar.h>

#include <memory>
#include <unordered_map>

namespace native_renderer {

    class NativeRendererPlugin : public flutter::Plugin {
    public:
        static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

        explicit NativeRendererPlugin(flutter::PluginRegistrarWindows* registrar);
        ~NativeRendererPlugin() override;

        NativeRendererPlugin(const NativeRendererPlugin&) = delete;
        NativeRendererPlugin& operator=(const NativeRendererPlugin&) = delete;

    private:
        void OnMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call,
                          std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

        flutter::PluginRegistrarWindows* registrar_;
        flutter::TextureRegistrar* texture_reg_;

        struct TexRecord;
        std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
        std::unordered_map<int64_t, std::unique_ptr<TexRecord>> recs_;
    };

}  // namespace native_renderer

#endif
