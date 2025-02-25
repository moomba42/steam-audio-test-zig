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
    defer c.iplContextRelease(&context);

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
    defer c.iplHRTFRelease(&hrtf);

    // Create a binaural effect - this is an object that contains all the state that must persist from
    // one audio frame to the next, for a single audio source.
    var binaural_settings = c.IPLBinauralEffectSettings{ .hrtf = hrtf };
    var binaural: c.IPLBinauralEffect = null;
    if (c.iplBinauralEffectCreate(context, &audio_settings, &binaural_settings, &binaural) != c.IPL_STATUS_SUCCESS) {
        return error.BinauralEffectCreationFailed;
    }
    defer c.iplBinauralEffectRelease(&binaural);

    // Load the input audio data
    const input_audio_bytes = @embedFile("inputaudio");
    const input_audio_sample_count: usize = input_audio_bytes.len / @sizeOf(f32);
    const input_audio: [input_audio_sample_count]f32 = @as([*]const f32, @alignCast(@ptrCast(input_audio_bytes)))[0..input_audio_sample_count].*;
    std.debug.print("Input audio sample count: {d}", .{input_audio.len});

    // Initialize the input buffer
    const input_buffer_num_channels = 1;
    var input_buffer_channels: [input_buffer_num_channels][*c]f32 = .{@constCast(&input_audio)};
    var input_buffer = c.IPLAudioBuffer{
        .numChannels = input_buffer_num_channels,
        .numSamples = frame_size,
        .data = &input_buffer_channels,
    };

    // Initialize the output buffer
    var output_buffer = c.IPLAudioBuffer{};
    if (c.iplAudioBufferAllocate(context, 2, frame_size, &output_buffer) != c.IPL_STATUS_SUCCESS) {
        return error.OutputBufferAllocationFailed;
    }
    defer c.iplAudioBufferFree(context, &output_buffer);

    // Initialize the output frame that will be used to retrieve data from the buffer
    var output_audio_frame: [2 * frame_size]f32 = .{0} ** (2 * frame_size);
    const frame_count = input_audio_sample_count / frame_size;
    var output_audio: [frame_count*frame_size*2]f32 = std.mem.zeroes([frame_count*frame_size*2]f32);

    // Loop through all frames and apply the spatialization effect, saving everything to output_audio
    for(0..frame_count) |i| {
        var binaural_params = c.IPLBinauralEffectParams {
            .direction = c.IPLVector3 {.x = -3.0, .y = 0.0, .z = 3.0},
            .interpolation = c.IPL_HRTFINTERPOLATION_NEAREST,
            .spatialBlend = 1.0,
            .hrtf = hrtf,
            .peakDelays = null,
        };
        if(c.iplBinauralEffectApply(binaural, &binaural_params, &input_buffer, &output_buffer) != c.IPL_STATUS_SUCCESS) {
            return error.BinauralEffectFailure;
        }

        c.iplAudioBufferInterleave(context, &output_buffer, &output_audio_frame);

        input_buffer_channels[0] += frame_size;
        @memcpy(output_audio[(i*frame_size*2)..((i*frame_size*2)+frame_size+frame_size)], output_audio_frame[0..]);
    }

    // Save the results to the disk
    var file = try std.fs.cwd().createFile("outputaudio.raw", .{});
    defer file.close();
    try file.writeAll(@as([*]u8, @ptrCast(&output_audio))[0..output_audio.len*@sizeOf(f32)]);
}
