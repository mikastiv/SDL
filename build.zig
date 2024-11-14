const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "SDL3",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    lib.addCSourceFiles(.{ .files = generic_src_files });
    lib.defineCMacro("SDL_USE_BUILTIN_OPENGL_DEFINITIONS", "1");
    lib.defineCMacro("SDL_STATIC_LIB", "");

    switch (target.result.os.tag) {
        .windows => {
            lib.addCSourceFiles(.{ .files = windows_src_files });
            lib.linkSystemLibrary("gdi32");
            lib.linkSystemLibrary("imm32");
            lib.linkSystemLibrary("ole32");
            lib.linkSystemLibrary("oleaut32");
            lib.linkSystemLibrary("setupapi");
            lib.linkSystemLibrary("version");
            lib.linkSystemLibrary("winmm");
        },
        else => @panic("unsupported"),
    }

    const use_pregenerated_config = switch (target.result.os.tag) {
        .windows => true,
        else => false,
    };

    if (use_pregenerated_config) {
        lib.addCSourceFiles(.{ .files = render_driver_software_src_files });
        lib.installHeadersDirectory(b.path("include/build_config"), "SDL3", .{});
    }

    lib.addIncludePath(b.path("include"));
    lib.addIncludePath(b.path("include/build_config"));
    lib.addIncludePath(b.path("src"));
    lib.installHeadersDirectory(b.path("include/SDL3"), "SDL3", .{});

    b.installArtifact(lib);
}

const generic_src_files: []const []const u8 = &.{
    "src/SDL.c",
    "src/SDL_assert.c",
    "src/SDL_error.c",
    "src/SDL_guid.c",
    "src/SDL_hashtable.c",
    "src/SDL_hints.c",
    "src/SDL_list.c",
    "src/SDL_log.c",
    "src/SDL_properties.c",
    "src/SDL_utils.c",

    "src/atomic/SDL_atomic.c",
    "src/atomic/SDL_spinlock.c",

    "src/audio/SDL_audio.c",
    "src/audio/SDL_audiocvt.c",
    "src/audio/SDL_audiodev.c",
    "src/audio/SDL_audioqueue.c",
    "src/audio/SDL_audioresample.c",
    "src/audio/SDL_audiotypecvt.c",
    "src/audio/SDL_mixer.c",
    "src/audio/SDL_wave.c",
    "src/audio/dummy/SDL_dummyaudio.c",

    "src/camera/SDL_camera.c",
    "src/camera/dummy/SDL_camera_dummy.c",

    "src/core/SDL_core_unsupported.c",

    "src/cpuinfo/SDL_cpuinfo.c",

    "src/dialog/SDL_dialog_utils.c",
    "src/dialog/dummy/SDL_dummydialog.c",

    "src/dynapi/SDL_dynapi.c",

    "src/events/imKStoUCS.c",
    "src/events/SDL_categories.c",
    "src/events/SDL_clipboardevents.c",
    "src/events/SDL_displayevents.c",
    "src/events/SDL_dropevents.c",
    "src/events/SDL_events.c",
    "src/events/SDL_keyboard.c",
    "src/events/SDL_keymap.c",
    "src/events/SDL_keysym_to_scancode.c",
    "src/events/SDL_mouse.c",
    "src/events/SDL_pen.c",
    "src/events/SDL_quit.c",
    "src/events/SDL_scancode_tables.c",
    "src/events/SDL_touch.c",
    "src/events/SDL_windowevents.c",

    "src/file/SDL_iostream.c",

    "src/filesystem/SDL_filesystem.c",
    "src/filesystem/dummy/SDL_sysfilesystem.c",
    "src/filesystem/dummy/SDL_sysfsops.c",

    "src/gpu/SDL_gpu.c",

    "src/haptic/SDL_haptic.c",
    "src/haptic/dummy/SDL_syshaptic.c",

    "src/hidapi/SDL_hidapi.c",

    "src/joystick/controller_type.c",
    "src/joystick/SDL_gamepad.c",
    "src/joystick/SDL_joystick.c",
    "src/joystick/SDL_steam_virtual_gamepad.c",
    "src/joystick/dummy/SDL_sysjoystick.c",
    "src/joystick/hidapi/SDL_hidapi_combined.c",
    "src/joystick/hidapi/SDL_hidapi_gamecube.c",
    "src/joystick/hidapi/SDL_hidapi_luna.c",
    "src/joystick/hidapi/SDL_hidapi_ps3.c",
    "src/joystick/hidapi/SDL_hidapi_ps4.c",
    "src/joystick/hidapi/SDL_hidapi_ps5.c",
    "src/joystick/hidapi/SDL_hidapi_rumble.c",
    "src/joystick/hidapi/SDL_hidapi_shield.c",
    "src/joystick/hidapi/SDL_hidapi_stadia.c",
    "src/joystick/hidapi/SDL_hidapi_steam.c",
    "src/joystick/hidapi/SDL_hidapi_steam_hori.c",
    "src/joystick/hidapi/SDL_hidapi_steamdeck.c",
    "src/joystick/hidapi/SDL_hidapi_switch.c",
    "src/joystick/hidapi/SDL_hidapi_wii.c",
    "src/joystick/hidapi/SDL_hidapi_xbox360.c",
    "src/joystick/hidapi/SDL_hidapi_xbox360w.c",
    "src/joystick/hidapi/SDL_hidapi_xboxone.c",
    "src/joystick/hidapi/SDL_hidapijoystick.c",
    "src/joystick/virtual/SDL_virtualjoystick.c",

    "src/libm/e_atan2.c",
    "src/libm/e_exp.c",
    "src/libm/e_fmod.c",
    "src/libm/e_log.c",
    "src/libm/e_log10.c",
    "src/libm/e_pow.c",
    "src/libm/e_rem_pio2.c",
    "src/libm/e_sqrt.c",
    "src/libm/k_cos.c",
    "src/libm/k_rem_pio2.c",
    "src/libm/k_sin.c",
    "src/libm/k_tan.c",
    "src/libm/s_atan.c",
    "src/libm/s_copysign.c",
    "src/libm/s_cos.c",
    "src/libm/s_fabs.c",
    "src/libm/s_floor.c",
    "src/libm/s_isinf.c",
    "src/libm/s_isinff.c",
    "src/libm/s_isnan.c",
    "src/libm/s_isnanf.c",
    "src/libm/s_modf.c",
    "src/libm/s_scalbn.c",
    "src/libm/s_sin.c",
    "src/libm/s_tan.c",

    "src/loadso/dummy/SDL_sysloadso.c",

    "src/locale/SDL_locale.c",
    "src/locale/dummy/SDL_syslocale.c",

    "src/main/SDL_main_callbacks.c",
    "src/main/SDL_runapp.c",
    "src/main/generic/SDL_sysmain_callbacks.c",

    "src/misc/SDL_url.c",
    "src/misc/dummy/SDL_sysurl.c",

    "src/power/SDL_power.c",

    "src/process/SDL_process.c",
    "src/process/dummy/SDL_dummyprocess.c",

    "src/render/SDL_d3dmath.c",
    "src/render/SDL_render.c",
    "src/render/SDL_render_unsupported.c",
    "src/render/SDL_yuv_sw.c",
    "src/render/gpu/SDL_pipeline_gpu.c",
    "src/render/gpu/SDL_render_gpu.c",
    "src/render/gpu/SDL_shaders_gpu.c",

    "src/sensor/SDL_sensor.c",
    "src/sensor/dummy/SDL_dummysensor.c",

    "src/stdlib/SDL_crc16.c",
    "src/stdlib/SDL_crc32.c",
    "src/stdlib/SDL_getenv.c",
    "src/stdlib/SDL_iconv.c",
    "src/stdlib/SDL_malloc.c",
    "src/stdlib/SDL_memcpy.c",
    "src/stdlib/SDL_memmove.c",
    "src/stdlib/SDL_memset.c",
    "src/stdlib/SDL_mslibc.c",
    "src/stdlib/SDL_murmur3.c",
    "src/stdlib/SDL_qsort.c",
    "src/stdlib/SDL_random.c",
    "src/stdlib/SDL_stdlib.c",
    "src/stdlib/SDL_string.c",
    "src/stdlib/SDL_strtokr.c",

    "src/storage/SDL_storage.c",
    "src/storage/generic/SDL_genericstorage.c",

    "src/thread/SDL_thread.c",

    "src/time/SDL_time.c",

    "src/timer/SDL_timer.c",

    "src/video/SDL_blit.c",
    "src/video/SDL_blit_0.c",
    "src/video/SDL_blit_1.c",
    "src/video/SDL_blit_A.c",
    "src/video/SDL_blit_auto.c",
    "src/video/SDL_blit_copy.c",
    "src/video/SDL_blit_N.c",
    "src/video/SDL_blit_slow.c",
    "src/video/SDL_bmp.c",
    "src/video/SDL_clipboard.c",
    "src/video/SDL_egl.c",
    "src/video/SDL_fillrect.c",
    "src/video/SDL_pixels.c",
    "src/video/SDL_rect.c",
    "src/video/SDL_RLEaccel.c",
    "src/video/SDL_stretch.c",
    "src/video/SDL_surface.c",
    "src/video/SDL_video.c",
    "src/video/SDL_video_unsupported.c",
    "src/video/SDL_vulkan_utils.c",
    "src/video/SDL_yuv.c",
    "src/video/dummy/SDL_nullevents.c",
    "src/video/dummy/SDL_nullframebuffer.c",
    "src/video/dummy/SDL_nullvideo.c",
    "src/video/offscreen/SDL_offscreenevents.c",
    "src/video/offscreen/SDL_offscreenframebuffer.c",
    "src/video/offscreen/SDL_offscreenopengles.c",
    "src/video/offscreen/SDL_offscreenvideo.c",
    "src/video/offscreen/SDL_offscreenvulkan.c",
    "src/video/offscreen/SDL_offscreenwindow.c",
    "src/video/yuv2rgb/yuv_rgb_lsx.c",
    "src/video/yuv2rgb/yuv_rgb_sse.c",
    "src/video/yuv2rgb/yuv_rgb_std.c",
};

const windows_src_files: []const []const u8 = &.{
    "src/audio/directsound/SDL_directsound.c",
    "src/audio/disk/SDL_diskaudio.c",
    "src/audio/wasapi/SDL_wasapi.c",
    "src/audio/wasapi/SDL_wasapi_win32.c",

    "src/camera/mediafoundation/SDL_camera_mediafoundation.c",

    "src/core/windows/pch.c",
    "src/core/windows/SDL_hid.c",
    "src/core/windows/SDL_immdevice.c",
    "src/core/windows/SDL_windows.c",
    "src/core/windows/SDL_xinput.c",

    "src/dialog/windows/SDL_windowsdialog.c",

    "src/filesystem/windows/SDL_sysfilesystem.c",
    "src/filesystem/windows/SDL_sysfsops.c",

    "src/gpu/d3d12/SDL_gpu_d3d12.c",
    "src/gpu/vulkan/SDL_gpu_vulkan.c",

    "src/haptic/windows/SDL_dinputhaptic.c",
    "src/haptic/windows/SDL_windowshaptic.c",

    "src/hidapi/windows/hid.c",
    "src/hidapi/windows/hidapi_descriptor_reconstruct.c",

    "src/joystick/windows/SDL_dinputjoystick.c",
    "src/joystick/windows/SDL_rawinputjoystick.c",
    "src/joystick/windows/SDL_windows_gaming_input.c",
    "src/joystick/windows/SDL_windowsjoystick.c",
    "src/joystick/windows/SDL_xinputjoystick.c",

    "src/loadso/windows/SDL_sysloadso.c",

    "src/locale/windows/SDL_syslocale.c",

    "src/main/windows/SDL_sysmain_runapp.c",

    "src/misc/windows/SDL_sysurl.c",

    "src/power/windows/SDL_syspower.c",

    "src/process/windows/SDL_windowsprocess.c",

    "src/render/direct3d/SDL_render_d3d.c",
    "src/render/direct3d/SDL_shaders_d3d.c",
    "src/render/direct3d11/SDL_render_d3d11.c",
    "src/render/direct3d11/SDL_shaders_d3d11.c",
    "src/render/direct3d12/SDL_render_d3d12.c",
    "src/render/direct3d12/SDL_shaders_d3d12.c",
    "src/render/opengl/SDL_render_gl.c",
    "src/render/opengl/SDL_shaders_gl.c",
    "src/render/opengles2/SDL_render_gles2.c",
    "src/render/opengles2/SDL_shaders_gles2.c",
    "src/render/vulkan/SDL_render_vulkan.c",
    "src/render/vulkan/SDL_shaders_vulkan.c",

    "src/sensor/windows/SDL_windowssensor.c",

    "src/thread/generic/SDL_syscond.c",
    "src/thread/generic/SDL_sysrwlock.c",
    "src/thread/windows/SDL_syscond_cv.c",
    "src/thread/windows/SDL_sysmutex.c",
    "src/thread/windows/SDL_sysrwlock_srw.c",
    "src/thread/windows/SDL_syssem.c",
    "src/thread/windows/SDL_systhread.c",
    "src/thread/windows/SDL_systls.c",

    "src/time/windows/SDL_systime.c",

    "src/timer/windows/SDL_systimer.c",

    "src/video/windows/SDL_windowsclipboard.c",
    "src/video/windows/SDL_windowsevents.c",
    "src/video/windows/SDL_windowsframebuffer.c",
    "src/video/windows/SDL_windowsgameinput.c",
    "src/video/windows/SDL_windowskeyboard.c",
    "src/video/windows/SDL_windowsmessagebox.c",
    "src/video/windows/SDL_windowsmodes.c",
    "src/video/windows/SDL_windowsmouse.c",
    "src/video/windows/SDL_windowsopengl.c",
    "src/video/windows/SDL_windowsopengles.c",
    "src/video/windows/SDL_windowsrawinput.c",
    "src/video/windows/SDL_windowsshape.c",
    "src/video/windows/SDL_windowsvideo.c",
    "src/video/windows/SDL_windowsvulkan.c",
    "src/video/windows/SDL_windowswindow.c",
};

const render_driver_software_src_files: []const []const u8 = &.{
    "src/render/software/SDL_blendfillrect.c",
    "src/render/software/SDL_blendline.c",
    "src/render/software/SDL_blendpoint.c",
    "src/render/software/SDL_drawline.c",
    "src/render/software/SDL_drawpoint.c",
    "src/render/software/SDL_render_sw.c",
    "src/render/software/SDL_rotate.c",
    "src/render/software/SDL_triangle.c",
};
