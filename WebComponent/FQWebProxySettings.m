//
//  FQWebProxySettings.m
//  FQFrameWork
//
//  Created by fengsh on 13-2-27.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//
//  Copyright (c) 2014年 fengsh998@163.com
//  blog:http://blog.csdn.net/fengsh998
//

#import "FQWebProxySettings.h"

@implementation FQWebProxySettings
@synthesize proxyUserName;
@synthesize proxyPassWord;
@synthesize proxyDomain;
@synthesize proxyHost;
@synthesize proxyPort;
@synthesize proxyType;
@synthesize pacFileURL;

- (id)init
{
    self = [super init];
    if (self)
    {
        proxyType = wpProxyNone;
        proxyPort = 80;
    }
    return self;
}

- (void)dealloc
{
    [proxyUserName release];
    [proxyPassWord release];
    [proxyDomain release];
    [proxyHost release];
    [pacFileURL release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    FQWebProxySettings *copy    = [[self class]copyWithZone:zone];
    copy.proxyUserName          = self.proxyUserName;
    copy.proxyPassWord          = self.proxyPassWord;
    copy.proxyDomain            = self.proxyDomain;
    copy.proxyPort              = self.proxyPort;
    copy.proxyHost              = self.proxyHost;
    copy.proxyType              = self.proxyType;
    copy.pacFileURL             = self.pacFileURL;
    return copy;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{proxyUserName : %@, proxyPassWord : %@, proxyDomain : %@, \
proxyHost : %@, proxyPort : %ld, proxyType : %d, pacFileUrl : %@ }",proxyUserName,proxyPassWord,
            proxyDomain,proxyHost,(long)proxyPort,proxyType,pacFileURL];
}

@end
