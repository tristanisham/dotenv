# dotenv

This is an implementation of the `dotenv` utility library for Zig. 

## Installation
```sh
zig fetch --save git+https://github.com/tristanisham/dotenv#HEAD
```
Then add the following to your `build.zig` file.

```zig

const dotenv = b.dependency("dotenv", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("dotenv", dotenv.module("dotenv"));
```

Finally, include it in your main.zig or wherever!
```zig
const std = @import("std");
const dotenv = @import("dotenv");

pub fn main() !void {
    const alloc = std.heap.page_allocator;
    var hash = dotenv.EnvMap.init(alloc);
    hash.deinit();
}

```

