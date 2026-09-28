#ifndef _CRT_SECURE_NO_WARNINGS
#define _CRT_SECURE_NO_WARNINGS 1
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
static int g_console_utf8_initialized = 0;
static void init_console_utf8_if_needed(void) {
    if (!g_console_utf8_initialized) {
        SetConsoleOutputCP(CP_UTF8);
        SetConsoleCP(CP_UTF8);
        g_console_utf8_initialized = 1;
    }
}
#endif

// Native console line reader with real stdin stream, UTF-8 BOM stripping, and trimming
char* c_cartan_read_line(void) {
#ifdef _WIN32
    init_console_utf8_if_needed();
#endif
    static char buf[4096];
    memset(buf, 0, sizeof(buf));
    fflush(stdout);
    fflush(stderr);
    if (!fgets(buf, sizeof(buf), stdin)) {
        return "exit";
    }
    size_t len = strlen(buf);
    while (len > 0 && (buf[len - 1] == '\r' || buf[len - 1] == '\n' || buf[len - 1] == ' ' || buf[len - 1] == '\t')) {
        buf[--len] = '\0';
    }
    char* start = buf;
    if ((unsigned char)start[0] == 0xEF && (unsigned char)start[1] == 0xBB && (unsigned char)start[2] == 0xBF) {
        start += 3;
    }
    while (*start == ' ' || *start == '\t') {
        start++;
    }
    return start;
}
