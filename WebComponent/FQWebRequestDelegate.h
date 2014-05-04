//
//  FQWebRequestDelegate.h
//  FQFrameWork
//
//  Created by fengsh on 13-2-27.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//
//  Copyright (c) 2014年 fengsh998@163.com
//  blog:http://blog.csdn.net/fengsh998
//

#ifndef FQFrameWork_FQWebRequestDelegate_h
#define FQFrameWork_FQWebRequestDelegate_h

@class FQWebRequest;
@class FQWebGroupRequest;

@protocol FQWebRequestDelegate <NSObject>
@optional
- (void)requestStarted:(FQWebRequest *)request;
- (void)requestFinished:(FQWebRequest *)request;
- (void)requestFailed:(FQWebRequest *)request;
/*
    当前请求需要证书认证时
    字点中使用的Key为
    FQWebAuthenticationUsername
    FQWebAuthenticationPassword
 */
- (NSDictionary *)authenticationNeededForRequest:(FQWebRequest *)request;
- (NSDictionary *)proxyAuthenticationNeededForRequest:(FQWebRequest *)request;

/*
    该网站的安全证书不受信任！此时提示仍然继续还是返回安全连接
    如果返回True,则使用不安全连接继续访问，FALSE则此次访问失败
 */
- (BOOL)isContinueWhenUnsafeConnectInCureentRequest:(FQWebRequest *)request;

/*
    接收到的进度
 */
- (void)requestReceviceProgress:(FQWebRequest *)request
                  withTotalSize:(FQULLInteger) total withRecvicedSize:(FQULLInteger)size;
/*
    发送进度
 */
- (void)requestSendProgress:(FQWebRequest *)request
                  withTotalSize:(FQULLInteger) total withSendSize:(FQULLInteger)size;

@end


@protocol FQWebRequestProgressDelegate <FQWebRequestDelegate>
@optional
/*
     当有数据下发时会触发
 */
- (void)downloadProgress:(FQWebRequest *)request
           withTotalSize:(FQULLInteger) total
        withRecvicedSize:(FQULLInteger)size;

/*
     当有post数据时会触发
 */
- (void)uploadProgress:(FQWebRequest *)request
         withTotalSize:(FQULLInteger) total
        withUploadsize:(FQULLInteger)size;

@end

@protocol FQWebRequestInGroupDelegate <NSObject>
@optional
- (void)allRequestFinish:(FQWebGroupRequest *)groupRequest;

@end

#endif
