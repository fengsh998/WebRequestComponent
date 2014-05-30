//
//  FQWebRequestBlock.m
//  FQFrameWork
//
//  Created by apple on 14-5-30.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//

#import "FQWebRequestBlock.h"
#import "FQWebRequest.h"

@implementation FQWebRequestBlockManager
@synthesize startedBlock;
@synthesize failedBlock;
@synthesize finishedBlock;
@synthesize isContinueWhenUnsafeConnectBlock;
@synthesize uploadProgressBlock;
@synthesize downLoadProgressBlock;
@synthesize authenticationNeededBlock;
@synthesize proxyAuthenticationNeededBlock;


- (id)copyWithZone:(NSZone *)zone
{
    FQWebRequestBlockManager *copy  = [[self class]copyWithZone:zone];
    copy.startedBlock = self.startedBlock;
    copy.finishedBlock = self.finishedBlock;
    copy.failedBlock = self.failedBlock;
    copy.isContinueWhenUnsafeConnectBlock = self.isContinueWhenUnsafeConnectBlock;
    copy.uploadProgressBlock = self.uploadProgressBlock;
    copy.downLoadProgressBlock = self.downLoadProgressBlock;
    copy.authenticationNeededBlock = self.authenticationNeededBlock;
    copy.proxyAuthenticationNeededBlock = self.proxyAuthenticationNeededBlock;
    return copy;
}

@end
