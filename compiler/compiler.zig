usingnamespace @import("imports.zig");

const DirEntry = fs.Walker.Entry;


pub var files: std.ArrayList(DirEntry) = undefined;
pub var sources: std.ArrayList([]u8) = undefined;


pub fn main() anyerror!void {
    const allocator = heap.c_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        warn("Please provide an input folder path to compile\n");
        std.process.exit(1);
    }

    const dir_path = try fs.realpathAlloc(allocator, args[1]);
    defer allocator.free(dir_path);

    files = std.ArrayList(DirEntry).init(allocator);
    defer {
        for(files.toSlice()) |file| {
            allocator.free(file.path);
            allocator.free(file.basename);
        }
        files.deinit();
    }

    var cwd_buffer: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    var cwd = try os.getcwd(&cwd_buffer);

    var walker = try fs.walkPath(allocator, dir_path);
    defer walker.deinit();

    while(try walker.next()) |file| {
        if(file.kind == .File and mem.endsWith(u8, file.basename, ".mtn")) {
            try files.append(DirEntry {
                .path = try fs.path.relative(allocator, cwd, file.path),//try mem.dupe(allocator, u8, file.path),
                .basename = try mem.dupe(allocator, u8, file.basename),
                .kind = file.kind,
            });
        }
    }

    var token_allocator = heap.ArenaAllocator.init(heap.c_allocator);
    defer token_allocator.deinit();

    sources = std.ArrayList([]u8).init(&token_allocator.allocator);

    for(files.toSlice()) |file| {
        var source = try io.readFileAlloc(&token_allocator.allocator, file.path);
        try sources.append(source);

        var tokens = std.ArrayList(tokenizer.Token).init(&token_allocator.allocator);

        try tokenizer.tokenize_file(source, sources.len-1, &tokens);
        try parser.parse_file(tokens.toSlice());
    }
}
