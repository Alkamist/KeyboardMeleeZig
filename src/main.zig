const std = @import("std");
const kbd = @import("keyboard_input.zig");

pub fn main() !void {
    const hook_thread = kbd.runHook();
    defer hook_thread.wait();

    kbd.setAllKeysBlocked(true);

    while (true) {
        //if (kbd.keyIsPressed(kbd.Key.A)) {
        //    std.debug.print("Yee\n", .{});
        //}
    }
}
