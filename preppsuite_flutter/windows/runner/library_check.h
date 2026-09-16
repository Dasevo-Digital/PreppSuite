#ifndef RUNNER_LIBRARY_CHECK_H_
#define RUNNER_LIBRARY_CHECK_H_

// Turning a silent non-start into a sentence.
//
// This exists because of a real failure that shipped for months. The
// packages needed the Microsoft Visual C++ runtime and did not carry it,
// which is invisible on any machine that has it -- every machine with
// Visual Studio, with Flutter, or with half the software on a developer's
// disk. On a machine without it the app did not crash and did not say
// anything: the process started, loaded flutter_windows.dll, and then sat
// at five megabytes with no window. Nothing on screen, nothing in the
// event log. Measured in a bare Windows Sandbox, the same build with the
// runtime installed came up in seconds.
//
// The runtime is bundled now (windows/CMakeLists.txt), so that case is
// gone. This is for the next one: a half-extracted archive, a file an
// antivirus took away, a copy made with something that dropped a DLL.
//
// Deliberately narrow. The first version of this loaded every DLL beside
// the executable, which is general and wrong: a plugin loaded outside the
// order the engine loads it in is a risk of its own, and it cannot be
// tested here -- Smart App Control on the test machine refuses every
// unsigned binary, in its Windows Sandbox as well. So it checks the one
// thing that actually went wrong and is safe to check: the C++ runtime,
// whose libraries are Microsoft's own and made to be loaded by anything.

// Returns true when the Microsoft C++ runtime can be resolved. Otherwise
// puts a message on screen naming what is missing and returns false; the
// caller must then stop, because nothing further along reports this -- the
// engine hangs on it rather than failing.
bool CheckBundledLibraries();

#endif  // RUNNER_LIBRARY_CHECK_H_
