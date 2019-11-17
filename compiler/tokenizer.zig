const std = @import("std");
const mem = std.mem;
const io = std.io;
const unicode = std.unicode;

usingnamespace @import("utils.zig");



pub const Token = struct {
    line: LineNumber,
    start: CharNumber,
    end: CharNumber,
    string: []u8,
};


pub fn tokenize_file(allocator: *mem.Allocator, path: []const u8) anyerror![]Token {
    var tokens = std.ArrayList(Token).init(allocator);

    var source = try io.readFileAlloc(allocator, path);
    defer allocator.free(source);
    if(source.len <= 0) {
        return tokens.toOwnedSlice();
    }

    var iterator = unicode.Utf8Iterator {
        .bytes = source,
        .i = 0,
    };

    var line: i32 = 1;
    var column: i32 = 0;
    var token = Token {
        .line = newLineNumber(0),
        .start = newCharNumber(0),
        .end = newCharNumber(0),
        .string = [_]u8 {},
    };
    while(iterator.nextCodepoint()) |codepoint32| {
        var point = try CodePoint8.init(codepoint32);

        column += 1;
        if(point.bytes[0] == '\n') {
            line += 1;
            column = 1;
        }

        if(token.string.len <= 0) {
            token = Token  {
                .line = newLineNumber(line),
                .start = newCharNumber(column),
                .end = newCharNumber(column),
                .string = [_]u8 {},
            };
        }
        token.end = newCharNumber(column);

        switch(point.bytes[0]) {
            ' ', '\t', '\n' => {
                if(token.string.len > 0) {
                    try tokens.append(token);
                    token = Token  {
                        .line = newLineNumber(line),
                        .start = newCharNumber(column),
                        .end = newCharNumber(column),
                        .string = [_]u8 {},
                    };
                }

                continue;
            },

            ':', '.', ';', ',', '#', '=', '>', '<', '+', '-', '*', '/', '!', '&', '$', '(', ')', '{', '}', '[', ']', => {
                if(token.string.len > 0) {
                    try tokens.append(token);
                    token = Token {
                        .line = newLineNumber(line),
                        .start = newCharNumber(column),
                        .end = newCharNumber(column),
                        .string = [_]u8 {},
                    };
                    iterator.i -= point.length;
                }
                else {
                    try tokens.append(Token {
                        .line = newLineNumber(line),
                        .start = newCharNumber(column),
                        .end = newCharNumber(column),
                        .string = try mem.dupe(allocator, u8, point.chars()),
                    });
                }

                continue;
            },

            else => {},
        }

        var new_string = try mem.concat(allocator, u8, [_] []u8 { token.string, point.chars() });
        allocator.free(token.string);
        token.string = new_string;
    }

    return tokens.toOwnedSlice();
}
