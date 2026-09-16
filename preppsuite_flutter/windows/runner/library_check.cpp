#include "library_check.h"

#include <windows.h>

#include <string>
#include <vector>

namespace {

struct FailedLibrary {
  const wchar_t* name;
  DWORD error;
};

// What a Flutter app on Windows cannot run without, and what the package
// now ships beside the executable.
//
// By name rather than by path on purpose: the loader then searches the
// same places it would when resolving a real import -- the application
// directory first, then the system -- so this asks the question the
// loader will ask, rather than a different one about a file's existence.
const wchar_t* const kRequired[] = {
    L"vcruntime140.dll",
    L"vcruntime140_1.dll",
    L"msvcp140.dll",
};

std::wstring Describe(const std::vector<FailedLibrary>& failures,
                      bool in_german) {
  std::wstring message =
      in_german
          ? L"PreppSuite kann nicht starten: die Microsoft-Visual-C++-"
            L"Laufzeit ist nicht zu finden.\r\n\r\nEs fehlt:\r\n"
          : L"PreppSuite cannot start: the Microsoft Visual C++ runtime "
            L"cannot be found.\r\n\r\nMissing:\r\n";
  for (const FailedLibrary& failure : failures) {
    message += L"    ";
    message += failure.name;
    message += L"  (Windows: " + std::to_wstring(failure.error) + L")\r\n";
  }
  message +=
      in_german
          ? L"\r\nDiese Dateien gehoeren in denselben Ordner wie "
            L"PreppSuite.exe. Am ehesten hilft: das Paket noch einmal "
            L"vollstaendig entpacken. Wurde etwas von einem Virenscanner "
            L"entfernt, hole es zurueck.\r\n\r\nSonst laesst sich die "
            L"Laufzeit bei Microsoft nachinstallieren (\"Visual C++ "
            L"Redistributable\", x64)."
          : L"\r\nThese files belong in the same folder as PreppSuite.exe. "
            L"The likeliest fix is to extract the package again, "
            L"completely. If an antivirus removed something, restore "
            L"it.\r\n\r\nFailing that, the runtime can be installed from "
            L"Microsoft (\"Visual C++ Redistributable\", x64).";
  return message;
}

}  // namespace

bool CheckBundledLibraries() {
  std::vector<FailedLibrary> failures;
  for (const wchar_t* name : kRequired) {
    const HMODULE module = ::LoadLibraryExW(
        name, nullptr,
        LOAD_LIBRARY_SEARCH_APPLICATION_DIR | LOAD_LIBRARY_SEARCH_SYSTEM32 |
            LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);
    if (module == nullptr) {
      failures.push_back({name, ::GetLastError()});
    }
    // Left loaded: the app needs them a moment later anyway, and
    // unloading here would only mean doing the work twice.
  }

  if (failures.empty()) {
    return true;
  }

  const bool in_german =
      PRIMARYLANGID(::GetUserDefaultUILanguage()) == LANG_GERMAN;
  ::MessageBoxW(nullptr, Describe(failures, in_german).c_str(), L"PreppSuite",
                MB_OK | MB_ICONERROR | MB_SETFOREGROUND);
  return false;
}
