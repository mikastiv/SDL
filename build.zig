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
            lib.addCSourceFiles(.{ .files = render_driver_software_src_files });
            lib.linkSystemLibrary("gdi32");
            lib.linkSystemLibrary("imm32");
            lib.linkSystemLibrary("ole32");
            lib.linkSystemLibrary("oleaut32");
            lib.linkSystemLibrary("setupapi");
            lib.linkSystemLibrary("version");
            lib.linkSystemLibrary("winmm");
        },
        .linux => {
            lib.addCSourceFiles(.{ .files = linux_src_files });
            lib.addCSourceFiles(.{ .files = render_driver_software_src_files });
            lib.linkSystemLibrary("X11");
            lib.linkSystemLibrary("Xext");
            lib.linkSystemLibrary("pulse");
        },
        else => @panic("unsupported"),
    }

    const use_pregenerated_config = switch (target.result.os.tag) {
        .windows => true,
        else => false,
    };

    if (use_pregenerated_config) {
        lib.addIncludePath(b.path("include/build_config"));
        lib.installHeadersDirectory(b.path("include/build_config"), "SDL3", .{});
    } else {
        lib.defineCMacro("USING_GENERATED_CONFIG_H", "");

        const config_header = b.addConfigHeader(.{
            .style = .{ .cmake = b.path("include/build_config/SDL_build_config.h.cmake") },
            .include_path = "SDL_build_config.h",
        }, cmake_header_config);
        lib.addConfigHeader(config_header);
        lib.installHeader(config_header.getOutput(), "SDL3/SDL_build_config.h");

        const revision_header = b.addConfigHeader(.{
            .style = .{ .cmake = b.path("include/build_config/SDL_revision.h.cmake") },
            .include_path = "SDL_revision.h",
        }, .{
            .SDL_VENDOR_INFO = "",
            .SDL_REVISION = 0,
        });
        lib.addConfigHeader(revision_header);
        lib.installHeader(revision_header.getOutput(), "SDL3/SDL_build_config.h");
    }

    lib.addIncludePath(b.path("include"));
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

const linux_src_files: []const []const u8 = &.{
    "src/audio/pulseaudio/SDL_pulseaudio.c",

    "src/core/linux/SDL_evdev.c",
    "src/core/linux/SDL_evdev_kbd.c",
    "src/core/linux/SDL_threadprio.c",
    "src/core/linux/SDL_evdev_capabilities.c",
    "src/core/unix/SDL_poll.c",
    "src/core/unix/SDL_appid.c",

    "src/dialog/unix/SDL_unixdialog.c",
    "src/dialog/unix/SDL_portaldialog.c",
    "src/dialog/unix/SDL_zenitydialog.c",

    "src/filesystem/unix/SDL_sysfilesystem.c",
    "src/filesystem/posix/SDL_sysfsops.c",

    "src/gpu/vulkan/SDL_gpu_vulkan.c",

    "src/haptic/linux/SDL_syshaptic.c",

    "src/hidapi/linux/hid.c",

    "src/joystick/linux/SDL_sysjoystick.c",
    "src/joystick/steam/SDL_steamcontroller.c",

    "src/locale/unix/SDL_syslocale.c",

    "src/loadso/dlopen/SDL_sysloadso.c",

    "src/misc/unix/SDL_sysurl.c",

    "src/power/linux/SDL_syspower.c",

    "src/process/posix/SDL_posixprocess.c",

    "src/render/opengl/SDL_render_gl.c",
    "src/render/opengl/SDL_shaders_gl.c",
    "src/render/opengles2/SDL_render_gles2.c",
    "src/render/opengles2/SDL_shaders_gles2.c",
    "src/render/vulkan/SDL_render_vulkan.c",
    "src/render/vulkan/SDL_shaders_vulkan.c",

    "src/thread/pthread/SDL_systls.c",
    "src/thread/pthread/SDL_syssem.c",
    "src/thread/pthread/SDL_syscond.c",
    "src/thread/pthread/SDL_sysmutex.c",
    "src/thread/pthread/SDL_systhread.c",
    "src/thread/pthread/SDL_sysrwlock.c",

    "src/time/unix/SDL_systime.c",

    "src/timer/unix/SDL_systimer.c",

    "src/video/x11/SDL_x11dyn.c",
    "src/video/x11/SDL_x11pen.c",
    "src/video/x11/SDL_x11shape.c",
    "src/video/x11/SDL_x11mouse.c",
    "src/video/x11/SDL_x11video.c",
    "src/video/x11/SDL_x11touch.c",
    "src/video/x11/SDL_x11modes.c",
    "src/video/x11/SDL_x11opengl.c",
    "src/video/x11/SDL_x11window.c",
    "src/video/x11/SDL_x11xfixes.c",
    "src/video/x11/SDL_x11events.c",
    "src/video/x11/SDL_x11vulkan.c",
    "src/video/x11/SDL_x11xinput2.c",
    "src/video/x11/SDL_x11keyboard.c",
    "src/video/x11/SDL_x11settings.c",
    "src/video/x11/SDL_x11opengles.c",
    "src/video/x11/SDL_x11clipboard.c",
    "src/video/x11/SDL_x11messagebox.c",
    "src/video/x11/SDL_x11framebuffer.c",
    "src/video/x11/edid-parse.c",
    "src/video/x11/xsettings-client.c",
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

const cmake_header_config = .{
    .HAVE_LIBC = "1",
    .HAVE_FLOAT_H = "1",
    .HAVE_ICONV_H = "1",
    .HAVE_INTTYPES_H = "1",
    .HAVE_LIMITS_H = "1",
    .HAVE_MALLOC_H = "1",
    .HAVE_MATH_H = "1",
    .HAVE_MEMORY_H = "1",
    .HAVE_SIGNAL_H = "1",
    .HAVE_STDARG_H = "1",
    .HAVE_STDBOOL_H = "1",
    .HAVE_STDDEF_H = "1",
    .HAVE_STDINT_H = "1",
    .HAVE_STDIO_H = "1",
    .HAVE_STDLIB_H = "1",
    .HAVE_STRINGS_H = "1",
    .HAVE_STRING_H = "1",
    .HAVE_SYS_TYPES_H = "1",
    .HAVE_WCHAR_H = "1",

    .HAVE_MALLOC = "1",
    .HAVE_CALLOC = "1",
    .HAVE_REALLOC = "1",
    .HAVE_FDATASYNC = "1",
    .HAVE_FREE = "1",
    .HAVE_GETENV = "1",
    .HAVE_GETHOSTNAME = "1",
    .HAVE_SETENV = "1",
    .HAVE_PUTENV = "1",
    .HAVE_UNSETENV = "1",
    .HAVE_ABS = "1",
    .HAVE_MEMSET = "1",
    .HAVE_MEMCPY = "1",
    .HAVE_MEMMOVE = "1",
    .HAVE_MEMCMP = "1",
    .HAVE_STRLEN = "1",
    .HAVE_STRCHR = "1",
    .HAVE_STRRCHR = "1",
    .HAVE_STRSTR = "1",
    .HAVE_STRTOLL = "1",
    .HAVE_STRTOULL = "1",
    .HAVE_STRTOD = "1",
    .HAVE_ATOI = "1",
    .HAVE_ATOF = "1",
    .HAVE_STRCMP = "1",
    .HAVE_STRNCMP = "1",
    .HAVE_SSCANF = "1",
    .HAVE_VSSCANF = "1",
    .HAVE_VSNPRINTF = "1",
    .HAVE_ACOS = "1",
    .HAVE_ACOSF = "1",
    .HAVE_ASIN = "1",
    .HAVE_ASINF = "1",
    .HAVE_ATAN = "1",
    .HAVE_ATANF = "1",
    .HAVE_ATAN2 = "1",
    .HAVE_ATAN2F = "1",
    .HAVE_CEIL = "1",
    .HAVE_CEILF = "1",
    .HAVE_COPYSIGN = "1",
    .HAVE_COPYSIGNF = "1",
    .HAVE_COS = "1",
    .HAVE_COSF = "1",
    .HAVE_EXP = "1",
    .HAVE_EXPF = "1",
    .HAVE_FABS = "1",
    .HAVE_FABSF = "1",
    .HAVE_FLOOR = "1",
    .HAVE_FLOORF = "1",
    .HAVE_FMOD = "1",
    .HAVE_FMODF = "1",
    .HAVE_ISINF = "1",
    .HAVE_ISINFF = "1",
    .HAVE_ISINF_FLOAT_MACRO = "1",
    .HAVE_ISNAN = "1",
    .HAVE_ISNANF = "1",
    .HAVE_ISNAN_FLOAT_MACRO = "1",
    .HAVE_LOG = "1",
    .HAVE_LOGF = "1",
    .HAVE_LOG10 = "1",
    .HAVE_LOG10F = "1",
    .HAVE_LROUND = "1",
    .HAVE_LROUNDF = "1",
    .HAVE_MODF = "1",
    .HAVE_MODFF = "1",
    .HAVE_POW = "1",
    .HAVE_POWF = "1",
    .HAVE_ROUND = "1",
    .HAVE_ROUNDF = "1",
    .HAVE_SCALBN = "1",
    .HAVE_SCALBNF = "1",
    .HAVE_SIN = "1",
    .HAVE_SINF = "1",
    .HAVE_SQRT = "1",
    .HAVE_SQRTF = "1",
    .HAVE_TAN = "1",
    .HAVE_TANF = "1",
    .HAVE_TRUNC = "1",
    .HAVE_TRUNCF = "1",
    .HAVE_SIGACTION = "1",
    .HAVE_SA_SIGACTION = "1",
    .HAVE_NANOSLEEP = "1",
    .HAVE_CLOCK_GETTIME = "1",
    .HAVE_GETPAGESIZE = "1",

    .HAVE_LINUX_INPUT_H = "1",

    .HAVE_GCC_ATOMICS = 1,
    .HAVE_GCC_SYNC_LOCK_TEST_AND_SET = 0,

    .HAVE_D3D11_H = 0,
    .HAVE_DDRAW_H = 0,
    .HAVE_DSOUND_H = 0,
    .HAVE_DINPUT_H = 0,
    .HAVE_XINPUT_H = 0,
    .HAVE_WINDOWS_GAMING_INPUT_H = 0,
    .HAVE_GAMEINPUT_H = 0,
    .HAVE_DXGI_H = 0,
    .HAVE_DXGI1_6_H = 0,

    .HAVE_MMDEVICEAPI_H = 0,
    .HAVE_AUDIOCLIENT_H = 0,
    .HAVE_TPCSHRD_H = 0,
    .HAVE_SENSORSAPI_H = 0,
    .HAVE_ROAPI_H = 0,
    .HAVE_SHELLSCALINGAPI_H = 0,

    .USE_POSIX_SPAWN = 0,

    .SDL_AUDIO_DISABLED = 0,
    .SDL_JOYSTICK_DISABLED = 0,
    .SDL_HAPTIC_DISABLED = 0,
    .SDL_HIDAPI_DISABLED = 0,
    .SDL_SENSOR_DISABLED = 0,
    .SDL_RENDER_DISABLED = 0,
    .SDL_THREADS_DISABLED = 0,
    .SDL_VIDEO_DISABLED = 0,
    .SDL_POWER_DISABLED = 0,
    .SDL_CAMERA_DISABLED = 0,
    .SDL_GPU_DISABLED = 0,

    .SDL_AUDIO_DRIVER_ALSA = 0,
    .SDL_AUDIO_DRIVER_ALSA_DYNAMIC = 0,
    .SDL_AUDIO_DRIVER_OPENSLES = 0,
    .SDL_AUDIO_DRIVER_AAUDIO = 0,
    .SDL_AUDIO_DRIVER_COREAUDIO = 0,
    .SDL_AUDIO_DRIVER_DISK = 0,
    .SDL_AUDIO_DRIVER_DSOUND = 0,
    .SDL_AUDIO_DRIVER_DUMMY = 0,
    .SDL_AUDIO_DRIVER_EMSCRIPTEN = 0,
    .SDL_AUDIO_DRIVER_HAIKU = 0,
    .SDL_AUDIO_DRIVER_JACK = 0,
    .SDL_AUDIO_DRIVER_JACK_DYNAMIC = 0,
    .SDL_AUDIO_DRIVER_NETBSD = 0,
    .SDL_AUDIO_DRIVER_OSS = 0,
    .SDL_AUDIO_DRIVER_PIPEWIRE = 0,
    .SDL_AUDIO_DRIVER_PIPEWIRE_DYNAMIC = 0,
    .SDL_AUDIO_DRIVER_PULSEAUDIO = 1,
    .SDL_AUDIO_DRIVER_PULSEAUDIO_DYNAMIC = 0,
    .SDL_AUDIO_DRIVER_SNDIO = 0,
    .SDL_AUDIO_DRIVER_SNDIO_DYNAMIC = 0,
    .SDL_AUDIO_DRIVER_WASAPI = 0,
    .SDL_AUDIO_DRIVER_VITA = 0,
    .SDL_AUDIO_DRIVER_PSP = 0,
    .SDL_AUDIO_DRIVER_PS2 = 0,
    .SDL_AUDIO_DRIVER_N3DS = 0,
    .SDL_AUDIO_DRIVER_QNX = 0,

    .SDL_INPUT_LINUXEV = 1,
    .SDL_INPUT_LINUXKD = 0,
    .SDL_INPUT_FBSDKBIO = 0,
    .SDL_INPUT_WSCONS = 0,
    .SDL_HAVE_MACHINE_JOYSTICK_H = 0,
    .SDL_JOYSTICK_ANDROID = 0,
    .SDL_JOYSTICK_DINPUT = 0,
    .SDL_JOYSTICK_DUMMY = 0,
    .SDL_JOYSTICK_EMSCRIPTEN = 0,
    .SDL_JOYSTICK_GAMEINPUT = 0,
    .SDL_JOYSTICK_HAIKU = 0,
    .SDL_JOYSTICK_HIDAPI = 1,
    .SDL_JOYSTICK_IOKIT = 0,
    .SDL_JOYSTICK_LINUX = 1,
    .SDL_JOYSTICK_MFI = 0,
    .SDL_JOYSTICK_N3DS = 0,
    .SDL_JOYSTICK_PS2 = 0,
    .SDL_JOYSTICK_PSP = 0,
    .SDL_JOYSTICK_RAWINPUT = 0,
    .SDL_JOYSTICK_USBHID = 0,
    .SDL_JOYSTICK_VIRTUAL = 0,
    .SDL_JOYSTICK_VITA = 0,
    .SDL_JOYSTICK_WGI = 0,
    .SDL_JOYSTICK_XINPUT = 0,
    .SDL_HAPTIC_DUMMY = 0,
    .SDL_HAPTIC_LINUX = 1,
    .SDL_HAPTIC_IOKIT = 0,
    .SDL_HAPTIC_DINPUT = 0,
    .SDL_HAPTIC_ANDROID = 0,
    .SDL_LIBUSB_DYNAMIC = 0,
    .SDL_UDEV_DYNAMIC = 0,

    .SDL_PROCESS_DUMMY = 0,
    .SDL_PROCESS_POSIX = 1,
    .SDL_PROCESS_WINDOWS = 0,

    .SDL_SENSOR_ANDROID = 0,
    .SDL_SENSOR_COREMOTION = 0,
    .SDL_SENSOR_WINDOWS = 0,
    .SDL_SENSOR_DUMMY = 0,
    .SDL_SENSOR_VITA = 0,
    .SDL_SENSOR_N3DS = 0,

    .SDL_LOADSO_DLOPEN = 1,
    .SDL_LOADSO_DUMMY = 0,
    .SDL_LOADSO_LDG = 0,
    .SDL_LOADSO_WINDOWS = 0,

    .SDL_THREAD_GENERIC_COND_SUFFIX = 0,
    .SDL_THREAD_GENERIC_RWLOCK_SUFFIX = 0,
    .SDL_THREAD_PTHREAD = 1,
    .SDL_THREAD_PTHREAD_RECURSIVE_MUTEX = 1,
    .SDL_THREAD_PTHREAD_RECURSIVE_MUTEX_NP = 0,
    .SDL_THREAD_WINDOWS = 0,
    .SDL_THREAD_VITA = 0,
    .SDL_THREAD_PSP = 0,
    .SDL_THREAD_PS2 = 0,
    .SDL_THREAD_N3DS = 0,

    .SDL_TIME_UNIX = 1,
    .SDL_TIME_WINDOWS = 0,
    .SDL_TIME_VITA = 0,
    .SDL_TIME_PSP = 0,
    .SDL_TIME_PS2 = 0,
    .SDL_TIME_N3DS = 0,

    .SDL_TIMER_HAIKU = 0,
    .SDL_TIMER_DUMMY = 0,
    .SDL_TIMER_UNIX = 1,
    .SDL_TIMER_WINDOWS = 0,
    .SDL_TIMER_VITA = 0,
    .SDL_TIMER_PSP = 0,
    .SDL_TIMER_PS2 = 0,
    .SDL_TIMER_N3DS = 0,

    .SDL_VIDEO_DRIVER_ANDROID = 0,
    .SDL_VIDEO_DRIVER_COCOA = 0,
    .SDL_VIDEO_DRIVER_DUMMY = 0,
    .SDL_VIDEO_DRIVER_EMSCRIPTEN = 0,
    .SDL_VIDEO_DRIVER_HAIKU = 0,
    .SDL_VIDEO_DRIVER_KMSDRM = 0,
    .SDL_VIDEO_DRIVER_KMSDRM_DYNAMIC = 0,
    .SDL_VIDEO_DRIVER_KMSDRM_DYNAMIC_GBM = 0,
    .SDL_VIDEO_DRIVER_N3DS = 0,
    .SDL_VIDEO_DRIVER_OFFSCREEN = 0,
    .SDL_VIDEO_DRIVER_PS2 = 0,
    .SDL_VIDEO_DRIVER_PSP = 0,
    .SDL_VIDEO_DRIVER_RISCOS = 0,
    .SDL_VIDEO_DRIVER_ROCKCHIP = 0,
    .SDL_VIDEO_DRIVER_RPI = 0,
    .SDL_VIDEO_DRIVER_UIKIT = 0,
    .SDL_VIDEO_DRIVER_VITA = 0,
    .SDL_VIDEO_DRIVER_VIVANTE = 0,
    .SDL_VIDEO_DRIVER_VIVANTE_VDK = 0,
    .SDL_VIDEO_DRIVER_OPENVR = 0,
    .SDL_VIDEO_DRIVER_WAYLAND = 0,
    .SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC = 0,
    .SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_CURSOR = 0,
    .SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_EGL = 0,
    .SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_LIBDECOR = 0,
    .SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_XKBCOMMON = 0,
    .SDL_VIDEO_DRIVER_WINDOWS = 0,
    .SDL_VIDEO_DRIVER_X11 = 1,
    .SDL_VIDEO_DRIVER_X11_DYNAMIC = 0,
    .SDL_VIDEO_DRIVER_X11_DYNAMIC_XCURSOR = 0,
    .SDL_VIDEO_DRIVER_X11_DYNAMIC_XEXT = 0,
    .SDL_VIDEO_DRIVER_X11_DYNAMIC_XFIXES = 0,
    .SDL_VIDEO_DRIVER_X11_DYNAMIC_XINPUT2 = 0,
    .SDL_VIDEO_DRIVER_X11_DYNAMIC_XRANDR = 0,
    .SDL_VIDEO_DRIVER_X11_DYNAMIC_XSS = 0,
    .SDL_VIDEO_DRIVER_X11_HAS_XKBLOOKUPKEYSYM = 0,
    .SDL_VIDEO_DRIVER_X11_SUPPORTS_GENERIC_EVENTS = 1,
    .SDL_VIDEO_DRIVER_X11_XCURSOR = 0,
    .SDL_VIDEO_DRIVER_X11_XDBE = 0,
    .SDL_VIDEO_DRIVER_X11_XFIXES = 0,
    .SDL_VIDEO_DRIVER_X11_XINPUT2 = 0,
    .SDL_VIDEO_DRIVER_X11_XINPUT2_SUPPORTS_MULTITOUCH = 0,
    .SDL_VIDEO_DRIVER_X11_XRANDR = 0,
    .SDL_VIDEO_DRIVER_X11_XSCRNSAVER = 0,
    .SDL_VIDEO_DRIVER_X11_XSHAPE = 0,
    .SDL_VIDEO_DRIVER_QNX = 0,

    .SDL_VIDEO_RENDER_D3D = 0,
    .SDL_VIDEO_RENDER_D3D11 = 0,
    .SDL_VIDEO_RENDER_D3D12 = 0,
    .SDL_VIDEO_RENDER_GPU = 1,
    .SDL_VIDEO_RENDER_METAL = 0,
    .SDL_VIDEO_RENDER_VULKAN = 1,
    .SDL_VIDEO_RENDER_OGL = 1,
    .SDL_VIDEO_RENDER_OGL_ES2 = 1,
    .SDL_VIDEO_RENDER_PS2 = 0,
    .SDL_VIDEO_RENDER_PSP = 0,
    .SDL_VIDEO_RENDER_VITA_GXM = 0,

    .SDL_VIDEO_OPENGL = 1,
    .SDL_VIDEO_OPENGL_ES = 1,
    .SDL_VIDEO_OPENGL_ES2 = 1,
    .SDL_VIDEO_OPENGL_BGL = 1,
    .SDL_VIDEO_OPENGL_CGL = 1,
    .SDL_VIDEO_OPENGL_GLX = 1,
    .SDL_VIDEO_OPENGL_WGL = 1,
    .SDL_VIDEO_OPENGL_EGL = 1,
    .SDL_VIDEO_OPENGL_OSMESA = 1,
    .SDL_VIDEO_OPENGL_OSMESA_DYNAMIC = 1,

    .SDL_VIDEO_VULKAN = 1,

    .SDL_VIDEO_METAL = 0,

    .SDL_GPU_D3D11 = 0,
    .SDL_GPU_D3D12 = 0,
    .SDL_GPU_VULKAN = 1,
    .SDL_GPU_METAL = 0,

    .SDL_POWER_ANDROID = 0,
    .SDL_POWER_LINUX = 1,
    .SDL_POWER_WINDOWS = 0,
    .SDL_POWER_MACOSX = 0,
    .SDL_POWER_UIKIT = 0,
    .SDL_POWER_HAIKU = 0,
    .SDL_POWER_EMSCRIPTEN = 0,
    .SDL_POWER_HARDWIRED = 0,
    .SDL_POWER_VITA = 0,
    .SDL_POWER_PSP = 0,
    .SDL_POWER_N3DS = 0,

    .SDL_FILESYSTEM_ANDROID = 0,
    .SDL_FILESYSTEM_HAIKU = 0,
    .SDL_FILESYSTEM_COCOA = 0,
    .SDL_FILESYSTEM_DUMMY = 0,
    .SDL_FILESYSTEM_RISCOS = 0,
    .SDL_FILESYSTEM_UNIX = 1,
    .SDL_FILESYSTEM_WINDOWS = 0,
    .SDL_FILESYSTEM_EMSCRIPTEN = 0,
    .SDL_FILESYSTEM_VITA = 0,
    .SDL_FILESYSTEM_PSP = 0,
    .SDL_FILESYSTEM_PS2 = 0,
    .SDL_FILESYSTEM_N3DS = 0,

    .SDL_STORAGE_GENERIC = 0,
    .SDL_STORAGE_STEAM = 0,

    .SDL_FSOPS_POSIX = 1,
    .SDL_FSOPS_WINDOWS = 0,
    .SDL_FSOPS_DUMMY = 0,

    .SDL_CAMERA_DRIVER_DUMMY = 0,
    .SDL_CAMERA_DRIVER_V4L2 = 0,
    .SDL_CAMERA_DRIVER_COREMEDIA = 0,
    .SDL_CAMERA_DRIVER_ANDROID = 0,
    .SDL_CAMERA_DRIVER_EMSCRIPTEN = 0,
    .SDL_CAMERA_DRIVER_MEDIAFOUNDATION = 0,
    .SDL_CAMERA_DRIVER_PIPEWIRE = 0,
    .SDL_CAMERA_DRIVER_PIPEWIRE_DYNAMIC = 0,
    .SDL_CAMERA_DRIVER_VITA = 0,

    .SDL_DIALOG_DUMMY = 0,

    .SDL_MISC_DUMMY = 0,

    .SDL_LOCALE_DUMMY = 0,

    .SDL_ALTIVEC_BLITTERS = 0,

    .DYNAPI_NEEDS_DLOPEN = 0,

    .SDL_USE_IME = 0,

    .SDL_IPHONE_KEYBOARD = 0,
    .SDL_IPHONE_LAUNCHSCREEN = 0,

    .SDL_VIDEO_VITA_PIB = 0,
    .SDL_VIDEO_VITA_PVR = 0,
    .SDL_VIDEO_VITA_PVR_OGL = 0,

    .SDL_LIBDECOR_VERSION_MAJOR = 0,
    .SDL_LIBDECOR_VERSION_MINOR = 0,
    .SDL_LIBDECOR_VERSION_PATCH = 0,

    .SDL_DEFAULT_ASSERT_LEVEL_CONFIGURED = 0,
    .SDL_DEFAULT_ASSERT_LEVEL = 0,

    .SDL_CAMERA_DRIVER_DISK = 0,
};
