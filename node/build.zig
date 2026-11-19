const std = @import("std");
const mbedtls = @import("build/mbedtls.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSafe });

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

    const mbedtls_lib = mbedtls.build(b, target, optimize);
    const mbedtls_c = b.addTranslateC(.{
        .root_source_file = b.path("build/mbedtls/smoke.h"),
        .target = target,
        .optimize = optimize,
    });
    mbedtls_c.addIncludePath(b.dependency("mbedtls", .{}).path("include"));
    mbedtls_c.addIncludePath(b.path("build/mbedtls"));
    mbedtls_c.defineCMacro("MBEDTLS_USER_CONFIG_FILE", "\"" ++ mbedtls.config_header ++ "\"");
    const mbedtls_smoke = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("build/mbedtls/smoke_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "mbedtls_c", .module = mbedtls_c.createModule() },
            },
        }),
    });
    mbedtls_smoke.root_module.linkLibrary(mbedtls_lib);
    test_step.dependOn(&b.addRunArtifact(mbedtls_smoke).step);
}
