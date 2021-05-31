#define WIN32_LEAN_AND_MEAN

#include <shlwapi.h>
#include <windows.h>

static const WCHAR *NextArgument(const WCHAR *commandLine) {
  if (*commandLine == '"') {
    commandLine++;
    while (*commandLine) {
      if (*commandLine++ == '"') {
        break;
      }
    }
  } else {
    while (*commandLine && *commandLine != ' ' && *commandLine != '\t') {
      commandLine++;
    }
  }
  while (*commandLine == ' ' || *commandLine == '\t') {
    commandLine++;
  }
  return commandLine;
}

int APIENTRY WinMain(HINSTANCE hInst, HINSTANCE hInstPrev, PSTR cmdline,
                     int cmdshow) {
  WCHAR *commandLine = StrDupW(NextArgument(GetCommandLineW()));

  STARTUPINFOW si;
  ZeroMemory(&si, sizeof(si));
  si.cb = sizeof(si);

  PROCESS_INFORMATION pi;
  ZeroMemory(&pi, sizeof(pi));

  if (CreateProcessW(
          /*lpApplicationName=*/NULL, commandLine,
          /*lpProcessAttributes=*/NULL,
          /*lpThreadAttributes=*/NULL,
          /*bInheritHandles=*/FALSE,
          /*dwCreationFlags=*/0,
          /*lpEnvironment=*/NULL,
          /*lpCurrentDirectory=*/NULL, &si, &pi)) {
    return 0;
  }

  DWORD error = GetLastError();
  WCHAR *message;
  FormatMessageW(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
                 /*lpSource=*/NULL, /*dwMessageId=*/error,
                 /*dwLanguageId=*/0, (WCHAR *)&message, /*nSize=*/0,
                 /*Arguments=*/NULL);
  MessageBoxW(NULL, message, L"code.exe", MB_OK | MB_ICONERROR);
  return error;
}
