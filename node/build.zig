const std = @import("std");
const mbedtls = @import("build/mbedtls.zig");
const libjuice = @import("build/libjuice.zig");
const libsrtp = @import("build/libsrtp.zig");
const usrsctp = @import("build/usrsctp.zig");
const libdatachannel = @import("build/libdatachannel.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .safe });

    const core = b.addModule("core", .{
        .root_source_file = b.path("src/core/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "bairdwire-node",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "core", .module = core },
            },
        }),
    });
    b.installArtifact(exe);

    const run_step = b.step("run", "Roda o nó");
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();
    run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Roda os testes");
    test_step.dependOn(&b.addRunArtifact(b.addTest(.{ .root_module = core })).step);
    test_step.dependOn(&b.addRunArtifact(b.addTest(.{ .root_module = exe.root_module })).step);

    const smoke: Smoke = .{ .b = b, .step = test_step, .target = target, .optimize = optimize };
    const mbedtls_lib = mbedtls.build(b, target, optimize);
    smoke.add("mbedtls", mbedtls_lib, &.{
        .{ "MBEDTLS_USER_CONFIG_FILE", "\"" ++ mbedtls.config_header ++ "\"" },
    });
    const deps: libdatachannel.Deps = .{
        .mbedtls = mbedtls_lib,
        .juice = libjuice.build(b, target, optimize),
        .srtp = libsrtp.build(b, target, optimize, mbedtls_lib),
        .usrsctp = usrsctp.build(b, target, optimize),
    };
    smoke.add("libjuice", deps.juice, &.{});
    smoke.add("libsrtp", deps.srtp, &.{});
    smoke.add("usrsctp", deps.usrsctp, &.{});
    smoke.add("libdatachannel", libdatachannel.build(b, target, optimize, deps), &libdatachannel.macros);
}

const Smoke = struct {
    b: *std.Build,
    step: *std.Build.Step,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,

    fn add(s: Smoke, comptime name: []const u8, lib: *std.Build.Step.Compile, macros: []const [2][]const u8) void {
        const translated = s.b.addTranslateC(.{
            .root_source_file = s.b.path("build/" ++ name ++ "/smoke.h"),
            .target = s.target,
            .optimize = s.optimize,
        });
        translated.addIncludePath(lib.getEmittedIncludeTree());
        for (macros) |macro| translated.defineCMacro(macro[0], macro[1]);

        const t = s.b.addTest(.{
            .name = name ++ "-smoke",
            .root_module = s.b.createModule(.{
                .root_source_file = s.b.path("build/" ++ name ++ "/smoke_test.zig"),
                .target = s.target,
                .optimize = s.optimize,
                .imports = &.{
                    .{ .name = name ++ "_c", .module = translated.createModule() },
                },
            }),
        });
        t.root_module.linkLibrary(lib);
        s.step.dependOn(&s.b.addRunArtifact(t).step);
    }
};
