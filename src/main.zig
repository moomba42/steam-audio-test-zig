const std = @import("std");

const c = @cImport({
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

    var hrtf_settings = c.IPLHRTFSettings {
        .type = c.IPL_HRTFTYPE_DEFAULT,
        .volume = 1,
    };

    var audio_settings = c.IPLAudioSettings {
        .samplingRate = 44100,
        .frameSize = 1024,
    };

    var hrtf: c.IPLHRTF = null;
    if(c.iplHRTFCreate(context, &audio_settings, &hrtf_settings, &hrtf) != c.IPL_STATUS_SUCCESS) {
        return error.HRTFCreationFailed;
    }

    var binaural_settings = c.IPLBinauralEffectSettings {
        .hrtf = hrtf,
    };

    var binaural: c.IPLBinauralEffect = null;
    if(c.iplBinauralEffectCreate(context, &audio_settings, &binaural_settings, &binaural) != c.IPL_STATUS_SUCCESS) {
        return error.BinauralEffectCreationFailed;
    }

    const input_audio_bytes = @embedFile("inputaudio");
    const input_audio_sample_count: usize = input_audio_bytes.len/@sizeOf(f32);
    const input_audio: [input_audio_sample_count]f32 = @as([*]const f32, @alignCast(@ptrCast(input_audio_bytes)))[0..input_audio_sample_count].*;

    std.debug.print("Input audio sample count: {d}", .{input_audio.len});
}
