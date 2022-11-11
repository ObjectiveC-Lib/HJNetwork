//
//  HJNetworkMetrics.h
//  HJNetwork
//
//  Created by navy on 2022/8/29.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HJNetworkMetrics : NSObject
/// HTTP 方法
@property (nonatomic, copy) NSString *http_method;

/// 协议名
@property (nonatomic, copy) NSString *protocol_name;

/// 响应码
@property (nonatomic, assign) NSInteger status_code;

/// 请求的 URL 地址
@property (nonatomic, copy) NSString *req_url;

/// 请求参数
@property (nonatomic, copy) NSString *req_params;

/// 请求头
@property (nonatomic, strong) NSDictionary *req_headers;

/// 请求头流量
@property (nonatomic, assign) int64_t req_header_byte;

/// 请求体流量
@property (nonatomic, assign) int64_t req_body_byte;

/// 响应头
@property (nonatomic, strong) NSDictionary *res_headers;

/// 响应头流量
@property (nonatomic, assign) int64_t res_header_byte;

/// 响应体流量
@property (nonatomic, assign) int64_t res_body_byte;

/// 是否使用代理
@property (nonatomic, assign) BOOL proxy_connection;

/// 是否蜂窝连接
@property (nonatomic, assign) BOOL cellular;

/// 本地 ip
@property (nonatomic, copy) NSString *local_ip;

/// 本地端口
@property (nonatomic, assign) NSInteger local_port;

/// 远端 ip
@property (nonatomic, copy) NSString *remote_ip;

/// 远端端口
@property (nonatomic, assign) NSInteger remote_port;

#pragma mark - cost time

/// DNS 解析耗时
@property (nonatomic, assign) int64_t dns_time;

/// TCP 连接耗时
@property (nonatomic, assign) int64_t tcp_time;

/// SSL 握手耗时
@property (nonatomic, assign) int64_t ssl_time;

/// Request 请求耗时
@property (nonatomic, assign) int64_t req_time;

/// Response 响应耗时
@property (nonatomic, assign) int64_t res_time;

/// 请求到响应总耗时
@property (nonatomic, assign) int64_t req_total_time;

- (instancetype)initWithMetrics:(NSURLSessionTaskMetrics *)metrics
                        session:(NSURLSession *)session
                           task:(NSURLSessionTask *)task API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));

@end

NS_ASSUME_NONNULL_END
