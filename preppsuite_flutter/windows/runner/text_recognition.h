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

  void Handle(const flutter::MethodCall<flutter::EncodableValue>& call,
              std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                  result);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  HWND window_;
  std::mutex mutex_;
  std::vector<Reply> ready_;
};

#endif  // RUNNER_TEXT_RECOGNITION_H_
