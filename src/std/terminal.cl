// src/std/terminal.cl
// CARTAN Standard Library: Terminal ANSI Formatting, Cursor Control & Asynchronous Input

include "src/std/math.cl";

// Global terminal color rendering toggle (1.0 = enabled, 0.0 = collapsed to empty string)
var g_terminal_color_enabled: float = 1.0;

// Configures whether terminal color codes emit ANSI escapes or empty strings
fn terminal_set_color_enabled(flag: float) {
    g_terminal_color_enabled = flag;
}

// Queries current terminal color rendering state
fn terminal_get_color_enabled() -> float {
    return g_terminal_color_enabled;
}

// Emits raw ANSI ESC byte (\e)
fn terminal_ansi_esc() -> string {
    return "\e";
}

// Resets terminal text attributes to default
fn terminal_col_reset() -> string {
    if (g_terminal_color_enabled == 1.0) { return "\e[0m"; }
    return "";
}

// Sets bold/bright text attribute
fn terminal_col_bold() -> string {
    if (g_terminal_color_enabled == 1.0) { return "\e[1m"; }
    return "";
}

// Sets dim/faint text attribute
fn terminal_col_dim() -> string {
    if (g_terminal_color_enabled == 1.0) { return "\e[2m"; }
    return "";
}

// Sets bright green foreground color
fn terminal_col_green() -> string {
    if (g_terminal_color_enabled == 1.0) { return "\e[1;32m"; }
    return "";
}

// Sets bright cyan foreground color
fn terminal_col_cyan() -> string {
    if (g_terminal_color_enabled == 1.0) { return "\e[1;36m"; }
    return "";
}

// Sets bright yellow foreground color
fn terminal_col_yellow() -> string {
    if (g_terminal_color_enabled == 1.0) { return "\e[1;33m"; }
    return "";
}

// Sets regular amber/yellow foreground color
fn terminal_col_amber() -> string {
    if (g_terminal_color_enabled == 1.0) { return "\e[33m"; }
    return "";
}

// Sets bright magenta foreground color
fn terminal_col_magenta() -> string {
    if (g_terminal_color_enabled == 1.0) { return "\e[1;35m"; }
    return "";
}

// Sets bright red foreground color
fn terminal_col_red() -> string {
    if (g_terminal_color_enabled == 1.0) { return "\e[1;31m"; }
    return "";
}

// Sets bright blue foreground color
fn terminal_col_blue() -> string {
    if (g_terminal_color_enabled == 1.0) { return "\e[1;34m"; }
    return "";
}

// Sets dark gray foreground color
fn terminal_col_gray() -> string {
    if (g_terminal_color_enabled == 1.0) { return "\e[90m"; }
    return "";
}

// Clears the current terminal line and returns cursor to beginning of line
fn terminal_erase_line() -> string {
    if (g_terminal_color_enabled == 1.0) { return "\e[2K\r"; }
    return "\r                                                                                \r";
}

// Returns a 10-frame Unicode braille spinner character
fn terminal_spinner_braille(idx: float) -> string {
    let m = idx - (floor(idx / 10.0) * 10.0);
    if (m == 0.0) { return "⠋"; }
    if (m == 1.0) { return "⠙"; }
    if (m == 2.0) { return "⠹"; }
    if (m == 3.0) { return "⠸"; }
    if (m == 4.0) { return "⠼"; }
    if (m == 5.0) { return "⠴"; }
    if (m == 6.0) { return "⠦"; }
    if (m == 7.0) { return "⠧"; }
    if (m == 8.0) { return "⠇"; }
    return "⠏";
}

// Returns a 4-frame rotating ASCII spinner character (| / - \)
fn terminal_spinner_ascii(idx: float) -> string {
    let m = idx - (floor(idx / 4.0) * 4.0);
    if (m == 0.0) { return "|"; }
    if (m == 1.0) { return "/"; }
    if (m == 2.0) { return "-"; }
    return "\\";
}

// Non-blocking terminal keyboard status check (returns 1.0 if key available, 0.0 otherwise)
fn terminal_kbhit() -> float {
    let hit = _kbhit();
    if (hit != 0.0) { return 1.0; }
    return 0.0;
}

// Reads character code from keyboard input without echoing to terminal
fn terminal_getch() -> float {
    return _getch();
}
