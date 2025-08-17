#include "native_renderer_plugin.h"

// 🔑 这些头一定要有：MethodChannel / EncodableValue / Texture
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/texture_registrar.h>

#include <windows.h>

#include <atomic>
#include <chrono>
#include <cstring>
#include <mutex>
#include <sstream>
#include <thread>
#include <vector>

// ===== 落盘日志到 %TEMP%\native_renderer.log，同时打到 DebugView =====
static void NR_FileLog(const std::string& s) {
    static HANDLE h = INVALID_HANDLE_VALUE;
    if (h == INVALID_HANDLE_VALUE) {
        wchar_t temp[MAX_PATH]{};
        DWORD n = GetTempPathW(MAX_PATH, temp);
        if (n == 0 || n > MAX_PATH) return;
        std::wstring path = std::wstring(temp) + L"native_renderer.log";
        h = CreateFileW(path.c_str(), GENERIC_WRITE, FILE_SHARE_READ, nullptr,
                        OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (h != INVALID_HANDLE_VALUE) {
            SetFilePointer(h, 0, nullptr, FILE_END);
        }
    }
    if (h != INVALID_HANDLE_VALUE) {
        DWORD written = 0;
        WriteFile(h, s.c_str(), (DWORD)s.size(), &written, nullptr);
    }
}
#define NR_LOG(msg) do {                         \
  std::ostringstream _nr;                        \
  _nr << "NR| " << msg << "\r\n";                \
  auto _s = _nr.str();                           \
  OutputDebugStringA(_s.c_str());                \
  NR_FileLog(_s);                                \
} while(0)

namespace native_renderer {

    struct BgraFrame {
        std::vector<uint8_t> pixels; // BGRA
        size_t width = 0, height = 0;
        std::mutex mtx;
        FlutterDesktopPixelBuffer pixbuf{};
        static void Release(void*) {}

        BgraFrame(size_t w, size_t h) : width(w), height(h) {
            pixels.resize(w * h * 4, 0);
            pixbuf.buffer = pixels.data();
            pixbuf.width  = w;
            pixbuf.height = h;
            pixbuf.release_callback = &Release;
            NR_LOG("BgraFrame ctor w=" << w << " h=" << h);
        }
    };

    struct Renderer {
        std::unique_ptr<BgraFrame> frame;
        std::thread th;
        std::atomic<bool> running{false};
        std::mutex inst_mtx;
        std::vector<float> instances;

        explicit Renderer(size_t w, size_t h) {
            frame = std::make_unique<BgraFrame>(w, h);
            NR_LOG("Renderer ctor");
        }

        void start(std::function<void()> markDirty) {
            if (running.exchange(true)) { NR_LOG("Renderer already running"); return; }
            NR_LOG("Renderer start()");
            th = std::thread([this, markDirty]() {
                using namespace std::chrono_literals;
                NR_LOG("render thread ENTER");
                try {
                    const size_t W = frame->width, H = frame->height;
                    uint32_t t = 0;
                    while (running.load()) {
                        {
                            std::lock_guard<std::mutex> lk(frame->mtx);
                            auto* p = frame->pixels.data();

                            // 清屏
                            for (size_t i = 0; i < W * H; ++i) {
                                p[i*4+0] = 20;  p[i*4+1] = 25;  p[i*4+2] = 28;  p[i*4+3] = 255;
                            }
                            // 棋盘
                            for (size_t y=0; y<H; y+=32) {
                                for (size_t x=0; x<W; x+=32) {
                                    bool on = ((x^y) & 64) != 0;
                                    if (!on) continue;
                                    for (size_t yy=0; yy<32 && y+yy<H; ++yy) {
                                        for (size_t xx=0; xx<32 && x+xx<W; ++xx) {
                                            size_t idx = ((y+yy)*W + (x+xx)) * 4;
                                            p[idx+0] = 40; p[idx+1] = 40; p[idx+2] = 46;
                                        }
                                    }
                                }
                            }
                            // 滚动条
                            size_t barX = (t*8) % (W + 200);
                            for (size_t y=H/3; y<H/3+8 && y<H; ++y) {
                                for (size_t x=0; x<200 && barX+x<W; ++x) {
                                    size_t idx=(y*W + (barX+x))*4;
                                    p[idx+0]=80; p[idx+1]=160; p[idx+2]=240;
                                }
                            }
                            // （可选）实例彩条
                            std::vector<float> local;
                            { std::lock_guard<std::mutex> lk2(inst_mtx); local = instances; }
                            for (size_t i=0; i+7<local.size(); i+=8) {
                                float dx=local[i+4], dy=local[i+5], dw=local[i+6], dh=local[i+7];
                                int x0=(int)dx, y0=(int)dy, x1=(int)(dx+dw), y1=(int)(dy+dh);
                                if (x0<0) x0=0; if (y0<0) y0=0;
                                if (x1>(int)W) x1=(int)W; if (y1>(int)H) y1=(int)H;
                                uint8_t cr = 80 + ((i*17 + t*3) % 170);
                                uint8_t cg = 80 + ((i*31 + t*5) % 170);
                                uint8_t cb = 80 + ((i*47 + t*7) % 170);
                                for (int y=y0; y<y1; ++y) {
                                    size_t row = y*W*4;
                                    for (int x=x0; x<x1; ++x) {
                                        size_t idx = row + x*4;
                                        p[idx+0]=cb; p[idx+1]=cg; p[idx+2]=cr; p[idx+3]=255;
                                    }
                                }
                            }
                        }
                        if ((t % 60) == 0) NR_LOG("render frame t=" << t);
                        markDirty();
                        ++t;
                        std::this_thread::sleep_for(std::chrono::milliseconds(16));
                    }
                } catch (const std::exception& e) {
                    NR_LOG("render thread EXCEPTION: " << e.what());
                } catch (...) {
                    NR_LOG("render thread EXCEPTION: unknown");
                }
                NR_LOG("render thread EXIT");
            });
        }

        void stop() {
            if (!running.exchange(false)) return;
            NR_LOG("Renderer stop()");
            if (th.joinable()) th.join();
        }

        void setInstances(const uint8_t* bytes, size_t len) {
            std::lock_guard<std::mutex> lk(inst_mtx);
            instances.resize(len/4);
            std::memcpy(instances.data(), bytes, len);
            NR_LOG("setInstances bytes=" << len << " floats=" << instances.size());
        }
    };

    struct NativeRendererPlugin::TexRecord {
        std::unique_ptr<Renderer> renderer;
        std::unique_ptr<flutter::TextureVariant> texture;
        int64_t tex_id = -1;
    };

// ====== Plugin 实现 ======

    void NativeRendererPlugin::RegisterWithRegistrar(
            flutter::PluginRegistrarWindows* registrar) {
        NR_LOG("RegisterWithRegistrar ENTER");

        auto plugin = std::make_unique<NativeRendererPlugin>(registrar);

        plugin->channel_ = std::make_unique<
                           flutter::MethodChannel<flutter::EncodableValue>>(
                registrar->messenger(), "native_renderer",
                        &flutter::StandardMethodCodec::GetInstance());

        plugin->channel_->SetMethodCallHandler(
                [plugin_raw = plugin.get()](const auto& call, auto result) {
                    plugin_raw->OnMethodCall(call, std::move(result));
                });

        registrar->AddPlugin(std::move(plugin));
        NR_LOG("RegisterWithRegistrar OK");
    }

    NativeRendererPlugin::NativeRendererPlugin(
            flutter::PluginRegistrarWindows* registrar)
            : registrar_(registrar),
              texture_reg_(registrar->texture_registrar()) {
        NR_LOG("Plugin ctor");
    }

    NativeRendererPlugin::~NativeRendererPlugin() {
        NR_LOG("Plugin dtor");
        for (auto& kv : recs_) {
            if (kv.second->renderer) kv.second->renderer->stop();
            texture_reg_->UnregisterTexture(kv.first);
        }
    }

    void NativeRendererPlugin::OnMethodCall(
            const flutter::MethodCall<flutter::EncodableValue>& call,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const auto& method = call.method_name();
        NR_LOG("OnMethodCall: " << method);

        if (method == "create") {
            const auto* args =
                    std::get_if<flutter::EncodableMap>(call.arguments());
            const int w = (int)std::get<int64_t>(args->at(flutter::EncodableValue("w")));
            const int h = (int)std::get<int64_t>(args->at(flutter::EncodableValue("h")));
            NR_LOG("create(): w=" << w << " h=" << h);

            auto rec = std::make_unique<TexRecord>();
            rec->renderer = std::make_unique<Renderer>(w, h);

            auto provider = [r = rec->renderer.get()](size_t, size_t)
                    -> const FlutterDesktopPixelBuffer* {
                static bool logged = false;
                if (!logged) { NR_LOG("pixel provider first call"); logged = true; }
                std::lock_guard<std::mutex> lk(r->frame->mtx);
                return &r->frame->pixbuf;
            };

            rec->texture = std::make_unique<flutter::TextureVariant>(
                    flutter::PixelBufferTexture(provider));
            rec->tex_id = texture_reg_->RegisterTexture(rec->texture.get());

            int64_t id = rec->tex_id;
            recs_.emplace(id, std::move(rec));
            NR_LOG("create(): tex_id=" << id);
            result->Success(flutter::EncodableValue(id));
            return;
        }

        if (method == "start") {
            const auto* args =
                    std::get_if<flutter::EncodableMap>(call.arguments());
            int64_t id = std::get<int64_t>(args->at(flutter::EncodableValue("id")));
            auto it = recs_.find(id);
            if (it == recs_.end()) {
                result->Error("not_found","texture not found");
                NR_LOG("start(): not_found id=" << id);
                return;
            }
            auto markDirty = [this, id]() { texture_reg_->MarkTextureFrameAvailable(id); };
            it->second->renderer->start(markDirty);
            NR_LOG("start(): id=" << id);
            result->Success();
            return;
        }

        if (method == "stop") {
            const auto* args =
                    std::get_if<flutter::EncodableMap>(call.arguments());
            int64_t id = std::get<int64_t>(args->at(flutter::EncodableValue("id")));
            auto it = recs_.find(id);
            if (it != recs_.end()) it->second->renderer->stop();
            NR_LOG("stop(): id=" << id);
            result->Success();
            return;
        }

        if (method == "dispose") {
            const auto* args =
                    std::get_if<flutter::EncodableMap>(call.arguments());
            int64_t id = std::get<int64_t>(args->at(flutter::EncodableValue("id")));
            auto it = recs_.find(id);
            if (it != recs_.end()) {
                it->second->renderer->stop();
                texture_reg_->UnregisterTexture(id);
                recs_.erase(it);
                NR_LOG("dispose(): id=" << id);
            } else {
                NR_LOG("dispose(): id not found " << id);
            }
            result->Success();
            return;
        }

        if (method == "uploadInstances") {
            const auto* args =
                    std::get_if<flutter::EncodableMap>(call.arguments());
            int64_t id = std::get<int64_t>(args->at(flutter::EncodableValue("id")));
            auto it = recs_.find(id);
            if (it == recs_.end()) {
                result->Error("not_found","texture not found");
                NR_LOG("uploadInstances(): not_found id=" << id);
                return;
            }
            const auto& any = args->at(flutter::EncodableValue("buf"));
            const auto* list = std::get_if<std::vector<uint8_t>>(&any);
            if (!list) {
                result->Error("bad_args","buf missing");
                NR_LOG("uploadInstances(): bad_args");
                return;
            }
            it->second->renderer->setInstances(list->data(), list->size());
            NR_LOG("uploadInstances(): id=" << id << " bytes=" << list->size());
            result->Success();
            return;
        }

        result->NotImplemented();
        NR_LOG("NotImplemented: " << method);
    }

}  // namespace native_renderer
