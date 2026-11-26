#ifndef RUNNER_TEXT_RECOGNITION_H_
#define RUNNER_TEXT_RECOGNITION_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <functional>
#include <memory>
#include <mutex>
#include <vector>

// Reads the text on a scanned page with Windows.Media.Ocr (#66).
//
// The page arrives as BGRA pixels drawn by PDFium on the Dart side, so
// this only has to recognise. Windows.Media.Ocr is part of the system and
// runs on the device; it reads the languages whose language pack is
// installed, which is why "support" can answer "needsLanguagePack".
//
// The recognition runs on a thread of its own, because the engine's calls
// are asynchronous and must not be waited on from the window's thread. The
// answer comes back through a window message, because a method channel
// may only be answered on that thread.
//
// The threads are not waited for when the window closes: a page can take
// seconds. They share State with this object instead of pointing at it,
// so one that finishes after the window is gone finds the window cleared
// and drops its answer rather than touching a destroyed object (#409).
class TextRecognition {
 public:
  // Posted to |window| when an answer is ready; FlutterWindow hands it
  // back to Deliver().
  static constexpr UINT kDoneMessage = WM_APP + 0x51;

  TextRecognition(flutter::BinaryMessenger* messenger, HWND window);
  ~TextRecognition();

  // Answers every recognition that has finished. On the window's thread.
  void Deliver();

 private:
  using Reply = std::function<void()>;

  // What the recognition threads and the window share. |window| is
  // cleared when this object goes, under |mutex|.
  struct State {
    std::mutex mutex;
    HWND window = nullptr;
    std::vector<Reply> ready;
  };

  // Queues |reply| for Deliver() and tells the window, unless it is gone.
  // From a recognition thread.
  static void Post(const std::shared_ptr<State>& state, Reply reply);

  void Handle(const flutter::MethodCall<flutter::EncodableValue>& call,
              std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                  result);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::shared_ptr<State> state_;
};

#endif  // RUNNER_TEXT_RECOGNITION_H_
