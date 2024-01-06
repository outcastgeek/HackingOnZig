const std = @import("std");
const log = std.log;
const json = std.json;
const heap = std.heap;
const Allocator = std.mem.Allocator;
const Client = std.http.Client;
const Uri = std.Uri;
const Headers = std.http.Headers;
const Method = std.http.Client.Method;
const Options = std.http.Client.Options;
const RequestTransfer = std.http.Client.RequestTransfer;
const Reader = std.http.Client.Reader;

const Params = struct {
    allocator: *Allocator,
    url: []const u8,
    method: Method,
    headers: Headers,
    options: Options,
    request_transfer: RequestTransfer,
    body: ?[]const u8,
};

const HttpError = error{ BadUriError, ClientError, ServerError };

fn doRequest(params: Params) HttpError!Reader {
    const uri = Uri.parse(params.allocator, params.url) catch |err| {
        _ = err;
        return error.BadUriError;
    };
    const client = Client{ .allocator = params.allocator };
    defer client.deinit();
    const request = client.request(params.method, uri, params.headers, params.options) catch |err| {
        _ = err;
        return error.ClientError;
    };
    defer request.deinit();
    request.start() catch |err| {
        _ = err;
        return error.ClientError;
    };
    if (params.body) |body| {
        request.writeAll(body);
    }
    request.finish() catch |err| {
        _ = err;
        return error.ClientError;
    };
    request.finish() catch |err| {
        _ = err;
        return error.ClientError;
    };
    request.wait() catch |err| {
        _ = err;
        return error.ClientError;
    };
    return request.reader();
}

pub const PostParams = struct {
    url: []u8,
    headers: ?Headers = .{},
    options: Options,
    request_transfer: RequestTransfer,
    body: []const u8,
};

pub fn post(allocator: Allocator, prms: PostParams) !void {
    const params = Params{
        .allocator = allocator,
        .url = prms.url,
        .method = .POST,
        .headers = prms.headers,
        .options = prms.options,
        .request_transfer = prms.request_transfer,
        .body = prms.body,
    };
    const response = try doRequest(params);
    _ = response;
}

const testing = std.testing;
const expect = testing.expect;
const testingAllocator = testing.allocator;

test "OpenAI Client HTTP Test" {
    // var jsonReader = json.Reader(8192, .{}).init(testingAllocator);
    // defer jsonReader.deinit();
    var jsonScanner = json.Scanner.initStreaming(testingAllocator);
    defer jsonScanner.deinit();

    const opts = Options{
        .timeout = 10,
        .max_response_headers = 10,
        .max_response_body_size = 1024 * 1024,
    };
    _ = Params{
        .url = "",
        .headers = .{},
        .options = opts,
        .request_transfer = .none,
        .body = "",
    };

    _ =
        try expect(1 == 1);
    try expect(2 == 2);
}
