const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{
        .cpu_arch = .x86,
        .os_tag = .freestanding,
    } });

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig-os",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linker_script = b.path("src/linker.ld");

    b.installArtifact(exe);

    // Run QEMU with some extra flags for debug info
    const run_cmd = b.addSystemCommand(&.{ "qemu-system-x86_64", "-kernel", "zig-out/bin/zig-os", "-d", "int,cpu_reset" });

    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
