const std = @import("std");

const c = @cImport({
    @cInclude("phonon.h");
});

pub fn main() !void {
    // Create the context
    var context_settings = c.IPLContextSettings{
        .version = c.STEAMAUDIO_VERSION,
    };
    var context: c.IPLContext = null;
    if (c.iplContextCreate(&context_settings, &context) != c.IPL_STATUS_SUCCESS) {
        return error.ContextCreationFailed;
    }

    // Define audio settings
    const frame_size = 1024;
    var audio_settings = c.IPLAudioSettings{
        .samplingRate = 44100,
        .frameSize = frame_size,
    };

    // Create the default Head-Related Transfer Function
    var hrtf_settings = c.IPLHRTFSettings{
        .type = c.IPL_HRTFTYPE_DEFAULT,
        .volume = 1,
    };
    var hrtf: c.IPLHRTF = null;
    if (c.iplHRTFCreate(context, &audio_settings, &hrtf_settings, &hrtf) != c.IPL_STATUS_SUCCESS) {
        return error.HRTFCreationFailed;
    }

    // Create a binaural effect - this is an object that contains all the state that must persist from
    // one audio frame to the next, for a single audio source.
    var binaural_settings = c.IPLBinauralEffectSettings{ .hrtf = hrtf };
    var binaural: c.IPLBinauralEffect = null;
    if (c.iplBinauralEffectCreate(context, &audio_settings, &binaural_settings, &binaural) != c.IPL_STATUS_SUCCESS) {
        return error.BinauralEffectCreationFailed;
    }

    // Load the input audio data
    const input_audio_bytes = @embedFile("inputaudio");
    const input_audio_sample_count: usize = input_audio_bytes.len / @sizeOf(f32);
    const input_audio: [input_audio_sample_count]f32 = @as([*]const f32, @alignCast(@ptrCast(input_audio_bytes)))[0..input_audio_sample_count].*;
    std.debug.print("Input audio sample count: {d}", .{input_audio.len});

    // Initialize the input buffer
    const input_buffer_num_channels = 1;
    const input_buffer_channels: [input_buffer_num_channels][*c]f32 = .{@constCast(&input_audio)};
    const input_buffer = c.IPLAudioBuffer{
        .numChannels = input_buffer_num_channels,
        .numSamples = frame_size,
        .data = @constCast(&input_buffer_channels),
    };

    // Initialize the output buffer
    var output_buffer = c.IPLAudioBuffer{};
    if (c.iplAudioBufferAllocate(context, 2, frame_size, &output_buffer) != c.IPL_STATUS_SUCCESS) {
        return error.OutputBufferAllocationFailed;
    }

    // Initialize the output frame that will be used to retrieve data from the buffer
    const output_audio_frame: [2 * frame_size]f32 = .{0} ** (2 * frame_size);

    _ = input_buffer;
    _ = output_audio_frame;
}
