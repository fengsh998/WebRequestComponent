//
//  FQWebRequestBlock.h
//  FQFrameWork
//
//  Created by apple on 14-5-30.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FQWebRequest;

#pragma mark - 使用block方式回调
typedef void (^FQWebRequestStartedBlock)(FQWebRequest * request);
typedef void (^FQWebRequestFinishedBlock)(FQWebRequest * request);
typedef void (^FQWebRequestFailedBlock)(FQWebRequest * request);
typedef NSDictionary * (^FQWebRequestAuthenticationNeededBlock)(FQWebRequest * request);
typedef NSDictionary * (^FQWebRequestProxyAuthenticationNeededBlock)(FQWebRequest * request);
typedef BOOL (^FQWebRequestIsContinueWhenUnsafeConnectBlock)(FQWebRequest * request);
typedef void (^FQWebRequestDownloadProgressBlock)(FQWebRequest * request,unsigned long long total, unsigned long long size);
typedef void (^FQWebRequestUploadProgressBlock)(FQWebRequest * request,unsigned long long total, unsigned long long size);


/*
    block方式回调
 设置样例
 req.reqBlockManager = [[[FQWebRequestBlockManager alloc]init]autorelease];
 
 [req.reqBlockManager setStartedBlock:^(FQWebRequest * req){
 
 }];
 
 [req.reqBlockManager setFinishedBlock:^(FQWebRequest * req){
 
 }];
 
 
 [req.reqBlockManager setAuthenticationNeededBlock:^NSDictionary *(FQWebRequest * req){
        return nil;
 }];
 
 [req.reqBlockManager setProxyAuthenticationNeededBlock:^NSDictionary *(FQWebRequest * req){
        return nil;
 }];
 */

@interface FQWebRequestBlockManager : NSObject
{
    FQWebRequestStartedBlock                            startedBlock;
    FQWebRequestFinishedBlock                           finishedBlock;
    FQWebRequestFailedBlock                             failedBlock;
    FQWebRequestAuthenticationNeededBlock               authenticationNeededBlock;
    FQWebRequestProxyAuthenticationNeededBlock          proxyAuthenticationNeededBlock;
    FQWebRequestIsContinueWhenUnsafeConnectBlock        isContinueWhenUnsafeConnectBlock;
    FQWebRequestDownloadProgressBlock                   downLoadProgressBlock;
    FQWebRequestUploadProgressBlock                     uploadProgressBlock;
}

@property (nonatomic,copy) FQWebRequestStartedBlock                     startedBlock;
@property (nonatomic,copy) FQWebRequestFinishedBlock                    finishedBlock;
@property (nonatomic,copy) FQWebRequestFailedBlock                      failedBlock;
@property (nonatomic,copy) FQWebRequestAuthenticationNeededBlock        authenticationNeededBlock;
@property (nonatomic,copy) FQWebRequestProxyAuthenticationNeededBlock   proxyAuthenticationNeededBlock;
@property (nonatomic,copy) FQWebRequestIsContinueWhenUnsafeConnectBlock isContinueWhenUnsafeConnectBlock;
@property (nonatomic,copy) FQWebRequestDownloadProgressBlock            downLoadProgressBlock;
@property (nonatomic,copy) FQWebRequestUploadProgressBlock              uploadProgressBlock;

@end
