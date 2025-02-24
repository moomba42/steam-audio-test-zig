const std = @import("std");

const c = @cImport({
    // @cDefine("SDL_DISABLE_OLD_NAMES", {});
    @cInclude("phonon.h");
});

pub fn main() !void {
    var context_settings = c.IPLContextSettings {
      .version = c.STEAMAUDIO_VERSION,
    };

    var context: c.IPLContext = null;
    if(c.iplContextCreate(&context_settings, &context) != c.IPL_STATUS_SUCCESS) {
        return error.ContextCreationFailed;
    }
}
