const std = @import("std");
const fmt = std.fmt;
const log = std.log;
const json = std.json;
const heap = std.heap;
const File = std.fs.File;
const Allocator = std.mem.Allocator;
const Client = std.http.Client;
const Field = std.http.Field;
const Headers = std.http.Headers;
const Method = std.http.Method;
const Status = std.http.Status;
const FetchOptions = std.http.Client.FetchOptions;
const Location = std.http.Client.FetchOptions.Location;
const Payload = std.http.Client.FetchOptions.Payload;
const FetchResult = std.http.Client.FetchResult;
const RequestOptions = std.http.Client.RequestOptions;
const Reader = std.http.Client.Reader;

pub const log_level = .debug;

const HttpClient = @This();

allocator: Allocator,
client: Client,

pub fn init(allocator: Allocator) HttpClient {
    return HttpClient{
        .allocator = allocator,
        .client = Client{
            .allocator = allocator,
        },
    };
}

pub fn deinit(self: *HttpClient) void {
    self.client.deinit();
}

pub const FetchParams = struct {
    headers: []const Field,
    location: Location,
    method: Method,
    payload: Payload,
};

pub const FetchError = error{
    ServerError,
    NoBody,
};

pub fn BuildResponseType(comptime T: anytype) type {
    const string = []const u8;
    if (T == string) {
        return union(enum) { file: File, none };
    }
    const U = union(enum) { parse: T, none };
    return U;
}

pub fn fetch_raw(self: *HttpClient, params: FetchParams) !FetchResult {
    var headers = try Headers.initList(self.allocator, params.headers);
    defer headers.deinit();

    const fetch_options = FetchOptions{
        .headers = headers,
        .location = params.location,
        .method = params.method,
        .payload = params.payload,
    };

    const result = try self.client.fetch(self.allocator, fetch_options);

    if (result.status == .ok) {
        return result;
    } else {
        return FetchError.ServerError;
    }
}

pub fn fetch_text(self: *HttpClient, params: FetchParams) ![]const u8 {
    var result = try self.fetch_raw(params);
    defer result.deinit();
    if (result.body) |body| {
        return body;
    } else {
        return FetchError.NoBody;
    }
}

pub fn fetch_json(self: *HttpClient, comptime T: type, params: FetchParams) !T {
    var result = try self.fetch_raw(params);
    defer result.deinit();
    if (result.body) |body| {
        const json_value = try json.parseFromSlice(T, self.allocator, body, .{});
        defer json_value.deinit();
        return json_value.value;
    } else {
        return FetchError.NoBody;
    }
}

test "OpenAI Client HTTP Test" {
    const testing = std.testing;
    const expect = testing.expect;
    const testingAllocator = testing.allocator;
    const debug = std.debug.print;

    const Order = struct {
        id: u64,
        customer: []const u8,
        quantity: u32,
        price: u64,
        completed: bool,
    };

    const input_order = Order{
        .id = 123,
        .customer = "Acme Corp",
        .quantity = 1,
        .price = 100,
        .completed = false,
    };

    const RespT = BuildResponseType([]const u8);
    // const RespT = BuildResponseType(Order);
    debug("Response Type: {}\n", .{RespT});

    // const respTInfo = @typeInfo(respT);
    // debug("Response Type Info: {}\n", .{respTInfo});

    // const sample: RespT = .{ .parse = input_order };
    const sample: RespT = .none;
    debug("Sample of Type: {}\n", .{sample});

    const payload = try json.stringifyAlloc(testingAllocator, input_order, .{ .whitespace = .indent_4 });
    defer testingAllocator.free(payload);
    // const content_length = try fmt.allocPrint(testingAllocator, "{d}", .{payload.len});
    debug("Payload: {s}\n", .{payload});

    var http_client = HttpClient.init(testingAllocator);
    defer http_client.deinit();

    const headers: []const Field = &.{
        .{ .name = "Authorization", .value = "Bearer sk_test_1234567890" },
        .{ .name = "Host", .value = "reqbin.com" },
        .{ .name = "Accept", .value = "application/json" },
        .{ .name = "Content-Type", .value = "application/json" },
        // .{ .name = "Content-Length", .value = content_length},
    };

    const prms = FetchParams{
        .headers = headers,
        .location = .{
            .url = "https://reqbin.com/echo/post/json",
        },
        .method = .POST,
        .payload = .{ .string = payload },
    };

    var post_result = try http_client.fetch_raw(prms);
    defer post_result.deinit();

    debug("Fetch Post_Result Status: {}\n", .{post_result.status});

    if (post_result.body) |body| {
        debug("Fetch Post Result Body: {s}\n", .{body});
    }

    const order_status_txt = try http_client.fetch_text(prms);

    debug("Fetch Order Status Text Type: {s}\n", .{@typeName(@TypeOf(order_status_txt))});
    debug("Fetch Order Status Text: {any}\n", .{order_status_txt});

    const OrderStatus = struct {
        success: []u8,
    };

    const order_status = try http_client.fetch_json(OrderStatus, prms);

    debug("Fetch Order Status Type: {s}\n", .{@typeName(@TypeOf(order_status))});
    debug("Fetch Order Status: {}\n", .{order_status});

    _ = try expect(1 == 1);
    try expect(2 == 2);
}
