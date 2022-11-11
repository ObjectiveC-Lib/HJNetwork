//
//  HJNetworkMetrics.m
//  HJNetwork
//
//  Created by navy on 2022/8/29.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJNetworkMetrics.h"

@implementation HJNetworkMetrics

- (instancetype)initWithMetrics:(NSURLSessionTaskMetrics *)metrics
                        session:(NSURLSession *)session
                           task:(NSURLSessionTask *)task API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {
    self = [super init];
    if (self) {
        [self setupMetrics:metrics session:session task:task];
    }
    return self;
}

- (void)setupMetrics:(NSURLSessionTaskMetrics *)metrics
             session:(NSURLSession *)session
                task:(NSURLSessionTask *)task API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {
    __weak __typeof(self)weakSelf = self;
    
    [metrics.transactionMetrics enumerateObjectsUsingBlock:^(NSURLSessionTaskTransactionMetrics * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.resourceFetchType == NSURLSessionTaskMetricsResourceFetchTypeNetworkLoad) {
            weakSelf.req_url = [obj.request.URL absoluteString];
            weakSelf.req_params = [obj.request.URL parameterString];
            weakSelf.req_headers = obj.request.allHTTPHeaderFields;
            
            if (@available(iOS 13.0, *)) {
                weakSelf.req_header_byte = obj.countOfRequestHeaderBytesSent;
                weakSelf.req_body_byte = obj.countOfRequestBodyBytesSent;
                
                weakSelf.res_header_byte = obj.countOfResponseHeaderBytesReceived;
                weakSelf.res_body_byte = obj.countOfResponseBodyBytesReceived;
            }
            
            if (@available(iOS 13.0, *)) {
                weakSelf.local_ip = obj.localAddress;
                weakSelf.local_port = obj.localPort.integerValue;
                
                weakSelf.remote_ip = obj.remoteAddress;
                weakSelf.remote_port = obj.remotePort.integerValue;
            }
            
            if (@available(iOS 13.0, *)) {
                weakSelf.cellular = obj.cellular;
            }
            
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)obj.response;
            if ([response isKindOfClass:NSHTTPURLResponse.class]) {
                weakSelf.res_headers = response.allHeaderFields;
                weakSelf.status_code = response.statusCode;
            }
            
            weakSelf.http_method = obj.request.HTTPMethod;
            weakSelf.protocol_name = obj.networkProtocolName;
            weakSelf.proxy_connection = obj.proxyConnection;
            
            if (obj.domainLookupStartDate && obj.domainLookupEndDate) {
                weakSelf.dns_time = ceil([obj.domainLookupEndDate timeIntervalSinceDate:obj.domainLookupStartDate] * 1000);
            }
            
            if (obj.connectStartDate && obj.connectEndDate) {
                weakSelf.tcp_time = ceil([obj.connectEndDate timeIntervalSinceDate:obj.connectStartDate] * 1000);
            }
            
            if (obj.secureConnectionStartDate && obj.secureConnectionEndDate) {
                weakSelf.ssl_time = ceil([obj.secureConnectionEndDate timeIntervalSinceDate:obj.secureConnectionStartDate] * 1000);
            }
            
            if (obj.requestStartDate && obj.requestEndDate) {
                weakSelf.req_time = ceil([obj.requestEndDate timeIntervalSinceDate:obj.requestStartDate] * 1000);
            }
            
            if (obj.responseStartDate && obj.responseEndDate) {
                weakSelf.res_time = ceil([obj.responseEndDate timeIntervalSinceDate:obj.responseStartDate] * 1000);
            }
            
            if (obj.fetchStartDate && obj.responseEndDate) {
                weakSelf.req_total_time = ceil([obj.responseEndDate timeIntervalSinceDate:obj.fetchStartDate] * 1000);
            }
        }
    }];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>\n (http_method: %@,\n protocol_name: %@,\n status_code: %@,\n req_url: %@,\n req_params: %@,\n req_headers: %@,\n req_header_byte: %@,\n req_body_byte: %@,\n res_headers: %@,\n res_header_byte: %@,\n res_body_byte: %@,\n proxy_connection: %@,\n cellular: %@,\n local_ip: %@,\n local_port: %@,\n remote_ip: %@,\n remote_port: %@,\n dns_time: %@,\n tcp_time: %@,\n ssl_time: %@,\n req_time: %@,\n res_time: %@,\n req_total_time: %@)",
            self.class, self,
            _http_method,
            _protocol_name,
            @(_status_code),
            _req_url,
            _req_params,
            _req_headers,
            @(_req_header_byte),
            @(_req_body_byte),
            _res_headers,
            @(_res_header_byte),
            @(_res_body_byte),
            @(_proxy_connection),
            @(_cellular),
            _local_ip,
            @(_local_port),
            _remote_ip,
            @(_remote_port),
            @(_dns_time),
            @(_tcp_time),
            @(_ssl_time),
            @(_req_time),
            @(_res_time),
            @(_req_total_time)
    ];
}

@end
