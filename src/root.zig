//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const bi = @import("builtin");
const testing = std.testing;

pub const EnvMap = struct {
    alloc: std.mem.Allocator,
    map: std.StringHashMap([]const u8),

    pub fn init(alloc: std.mem.Allocator) @This() {
        return .{ .alloc = alloc, .map = std.StringHashMap([]const u8).init(alloc) };
    }

    pub fn load(this: *@This(), opts: LoadOptions) !void {
        var dir = std.fs.cwd();

        var i: u32 = 0;
        var file: ?[]u8 = null;

        while (i < opts.recursive_height) : (i += 1) {
            file = dir.readFileAlloc(this.alloc, ".env", opts.max_size) catch |err| {
                switch (err) {
                    error.FileNotFound => {
                        dir = try dir.openDir("../", .{});
                        continue;
                    },
                    else => return err,
                }
            };

            break;
        }

        if (file) |data| {
            try extractEnvMap(this.alloc, &this.map, data, opts);
            this.alloc.free(data);
            return;
        }
    }

    pub fn deinit(this: *@This()) void {
        var iter = this.map.iterator();
        while (iter.next()) |e| {
            this.alloc.free(e.key_ptr.*);
            this.alloc.free(e.value_ptr.*);
        }
        this.map.deinit();
    }

    pub fn get(this: *@This(), key: []const u8) ?[]const u8 {
        return this.map.get(key);
    }
};

const LoadOptions = struct {
    recursive_height: u32 = 1,
    max_size: usize = std.math.maxInt(usize),
    trim_quotes: bool = false,
};

fn extractEnvMap(alloc: std.mem.Allocator, map: *std.StringHashMap([]const u8), src: []u8, opts: LoadOptions) !void {
    var iter = std.mem.splitAny(u8, src, "\n");

    while (iter.next()) |line| {
        for (line, 0..line.len) |c, i| {
            if (c == '=') {
                var key = line[0..i];
                var val = line[i + 1 .. line.len];

                key = std.mem.trim(u8, key, " ");
                val = std.mem.trim(u8, val, " ");

                if (opts.trim_quotes) {
                    // std.debug.print("trimming quotes", .{});
                    key = std.mem.trim(u8, key, "\"");
                    val = std.mem.trim(u8, val, "\"");
                }

                // Allocate memory for key and value
                const key_dup = try alloc.dupe(u8, key);
                const val_dup = try alloc.dupe(u8, val);

                // Store the duplicated key and value in the map
                try map.put(key_dup, val_dup);
            }
        }
    }
}

test "basic memory hole" {
    const alloc = testing.allocator;
    var hash = EnvMap.init(alloc);
    hash.deinit();
}
