//
//  FQWebEngineError.h
//  FQFrameWork
//
//  Created by fengsh on 13-2-27.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//
//  Copyright (c) 2014年 fengsh998@163.com
//  blog:http://blog.csdn.net/fengsh998
//

#ifndef FQFrameWork_FQWebEngineError_h
#define FQFrameWork_FQWebEngineError_h

#define FQ_Extern extern

typedef enum {
    FQWebNone                            = 0x1000,
    FQWebUrlEmptyError                   = 0x1001,                  // URL为空错误
    FQWebRequestTimeoutError             = 0x1002,                  // 请求超时错误
    FQWebReadDataStreamError             = 0x1003,                  // 网络或读响应流错误
    FQWebProxySettingError               = 0x1004,                  // 代理配置错误
    FQWebNetWorkConnectError             = 0x1005,                  // 网络连接错误(断网或有网但连不上internet)
    FQWebConnectToServerRefusedError     = 0x1006,                  // 不能连接到服务器错误(能上网但找不到host服务器)
    FQWebSSLConnectError                 = 0x1007,                  // 使用SSL连接时出现错误
    FQWebCredentialsApplyError           = 0x1008,                  // 证书在当前请求应用中失败了
    FQWebAuthenticationFailedError       = 0x1009,                  // 证书认证失败
    FQUnhandledExceptionError            = 0x100A
}FQRequestErrorType;

FQ_Extern NSString *FQWebErrorDomain;

@interface FQWebError : NSObject

+ (NSString *)getErrorDescriptionByErrType:(FQRequestErrorType)err;

+ (NSError *)makeFQWebEngineErrorWith:(FQRequestErrorType)errtype;
+ (NSError *)makeFQWebEngineErrorWith:(FQRequestErrorType)errtype andReason:(NSString *)reason;

@end

#endif
