const std = @import("std");

const HC_ACTION = 0;

const WM_KEYDOWN = 0x0100;
const WM_KEYUP = 0x0101;
const WM_SYSKEYDOWN = 0x0104;
const WM_SYSKEYUP = 0x0105;

const HINSTANCE = *opaque {};
const HWND = *opaque {};
const WPARAM = usize;
const LPARAM = usize;
const LRESULT = usize;

const ULONG_PTR = usize;
const UINT = c_uint;
const DWORD = u32;

const WH_KEYBOARD_LL = 13;

const HOOKPROC = fn(c_int, WPARAM, LPARAM) callconv(.Stdcall) LRESULT;

const KBDLLHOOKSTRUCT = extern struct {
    vkCode: DWORD,
    scanCode: DWORD,
    flags: DWORD,
    time: DWORD,
    dwExtraInfo: ULONG_PTR,
};

const POINT = extern struct {
    x: c_long,
    y: c_long,
};

const MSG = extern struct {
    hWnd: ?HWND,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    time: DWORD,
    pt: POINT,
    lPrivate: DWORD,
};

extern "user32" fn GetMessageA(
    lpMsg: ?*MSG,
    hWnd: ?HWND,
    wMsgFilterMin: UINT,
    wMsgFilterMax: UINT,
) callconv(.Stdcall) bool;

extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(.Stdcall) bool;
extern "user32" fn DispatchMessageA(lpMsg: *const MSG) callconv(.Stdcall) LRESULT;

extern "user32" fn SetWindowsHookExW(
    idHook: c_int,
    lpfn: HOOKPROC,
    hmod: ?HINSTANCE,
    dwThreadId: DWORD,
) callconv(.Stdcall) c_int;

extern "user32" fn CallNextHookEx(
    hhk: ?*c_void,
    code: c_int,
    wParam: WPARAM,
    lParam: LPARAM,
) callconv(.Stdcall) LRESULT;

fn enumIndex(comptime Enum: type, e: Enum) ?usize {
    comptime var i = 0;
    inline for (std.meta.fields(Enum)) |field| {
        if (field.value == @enumToInt(e)) {
            return i;
        }
        i += 1;
    }
    return null;
}

fn windowsHook(code: c_int, w_param: WPARAM, l_param: LPARAM) callconv(.Stdcall) LRESULT {
    var block_key_press = false;

    if (code == HC_ACTION) {
        const key_code = @intToPtr(*const KBDLLHOOKSTRUCT, l_param).vkCode;
        const key_result = std.meta.intToEnum(Key, key_code);
        if (key_result) |key| {
            var possible_key_index = enumIndex(Key, key);
            if (possible_key_index) |key_index| {
                block_key_press = key_block_states[key_index];

                if (w_param == WM_KEYDOWN or w_param == WM_SYSKEYDOWN) {
                    key_states[key_index] = true;
                    std.debug.print("Down, {}\n", .{@tagName(key)});
                }
                else if (w_param == WM_KEYUP or w_param == WM_SYSKEYUP) {
                    key_states[key_index] = false;
                    std.debug.print("Up, {}\n", .{@tagName(key)});
                }
            }
        }
        else |_| {}
    }

    if (block_key_press) {
        return 1;
    }

    return CallNextHookEx(null, code, w_param, l_param);
}

fn runHookNoThread(context: void) void {
    _ = SetWindowsHookExW(WH_KEYBOARD_LL, windowsHook, null, 0);

    while (true) {
        var msg = MSG {
            .hWnd = null,
            .message = 0,
            .wParam = 0,
            .lParam = 0,
            .time = 0,
            .pt = POINT {
                .x = 0,
                .y = 0,
            },
            .lPrivate = 0,
        };
        _ = GetMessageA(&msg, null, 0, 0);
        _ = TranslateMessage(&msg);
        _ = DispatchMessageA(&msg);
    }
}

pub fn runHook() !*std.Thread {
    const hook_thread = try std.Thread.spawn({}, runHookNoThread);
    return hook_thread;
}

var key_states = [_]bool{false} ** @typeInfo(Key).Enum.fields.len;
var key_block_states = [_]bool{false} ** @typeInfo(Key).Enum.fields.len;

pub fn keyIsPressed(key: Key) bool {
    if (enumIndex(Key, key)) |key_index| {
        return key_states[key_index];
    }
    return false;
}

pub fn keyIsBlocked(key: Key) bool {
    if (enumIndex(Key, key)) |key_index| {
        return key_block_states[key_index];
    }
    return false;
}

pub fn setKeyBlocked(key: Key, state: bool) void {
    if (enumIndex(Key, key)) |key_index| {
        key_block_states[key_index] = state;
    }
}

pub fn setAllKeysBlocked(state: bool) void {
    for (key_block_states) |*block_state| {
        block_state.* = state;
    }
}

pub const Key = enum(u32) {
    ControlBreak = 3,
    Backspace = 8,
    Tab = 9,
    Clear = 12,
    Enter = 13,
    Shift = 16,
    Control = 17,
    Alt = 18,
    Pause = 19,
    CapsLock = 20,
    IMEKana = 21,
    IMEJunja = 23,
    IMEFinal = 24,
    IMEHanja = 25,
    Escape = 27,
    IMEConvert = 28,
    IMENonConvert = 29,
    IMEAccept = 30,
    IMEModeChange = 31,
    Space = 32,
    PageUp = 33,
    PageDown = 34,
    End = 35,
    Home = 36,
    LeftArrow = 37,
    UpArrow = 38,
    RightArrow = 39,
    DownArrow = 40,
    Select = 41,
    Print = 42,
    Execute = 43,
    PrintScreen = 44,
    Insert = 45,
    Delete = 46,
    Help = 47,
    Key0 = 48,
    Key1 = 49,
    Key2 = 50,
    Key3 = 51,
    Key4 = 52,
    Key5 = 53,
    Key6 = 54,
    Key7 = 55,
    Key8 = 56,
    Key9 = 57,
    A = 65,
    B = 66,
    C = 67,
    D = 68,
    E = 69,
    F = 70,
    G = 71,
    H = 72,
    I = 73,
    J = 74,
    K = 75,
    L = 76,
    M = 77,
    N = 78,
    O = 79,
    P = 80,
    Q = 81,
    R = 82,
    S = 83,
    T = 84,
    U = 85,
    V = 86,
    W = 87,
    X = 88,
    Y = 89,
    Z = 90,
    LeftWindows = 91,
    RightWindows = 92,
    Applications = 93,
    Sleep = 95,
    NumPad0 = 96,
    NumPad1 = 97,
    NumPad2 = 98,
    NumPad3 = 99,
    NumPad4 = 100,
    NumPad5 = 101,
    NumPad6 = 102,
    NumPad7 = 103,
    NumPad8 = 104,
    NumPad9 = 105,
    NumPadMultiply = 106,
    NumPadAdd = 107,
    NumPadSeparator = 108,
    NumPadSubtract = 109,
    NumPadDecimal = 110,
    NumPadDivide = 111,
    F1 = 112,
    F2 = 113,
    F3 = 114,
    F4 = 115,
    F5 = 116,
    F6 = 117,
    F7 = 118,
    F8 = 119,
    F9 = 120,
    F10 = 121,
    F11 = 122,
    F12 = 123,
    F13 = 124,
    F14 = 125,
    F15 = 126,
    F16 = 127,
    F17 = 128,
    F18 = 129,
    F20 = 130,
    F21 = 131,
    F22 = 132,
    F23 = 133,
    F24 = 134,
    NumLock = 144,
    ScrollLock = 145,
    LeftShift = 160,
    RightShift = 161,
    LeftControl = 162,
    RightControl = 163,
    LeftAlt = 164,
    RightAlt = 165,
    BrowserBack = 166,
    BrowserForward = 167,
    BrowserRefresh = 168,
    BrowserStop = 169,
    BrowserSearch = 170,
    BrowserFavorites = 171,
    BrowserHome = 172,
    BrowserMute = 173,
    VolumeDown = 174,
    VolumeUp = 175,
    MediaNextTrack = 176,
    MediaPreviousTrack = 177,
    MediaStop = 178,
    MediaPlay = 179,
    StartMail = 180,
    MediaSelect = 181,
    LaunchApplication1 = 182,
    LaunchApplication2 = 183,
    Semicolon = 186,
    Equals = 187,
    Comma = 188,
    Minus = 189,
    Period = 190,
    Slash = 191,
    Grave = 192,
    LeftBracket = 219,
    BackSlash = 220,
    RightBracket = 221,
    Apostrophe = 222,
    IMEProcess = 229,
};
