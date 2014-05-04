//
//  FQWebProxySettings.h
//  FQFrameWork
//
//  Created by fengsh on 13-2-27.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//
//  Copyright (c) 2014年 fengsh998@163.com
//  blog:http://blog.csdn.net/fengsh998
//

#import <Foundation/Foundation.h>

typedef enum {
    wpProxyNone,                    //不设置代理类型
    wpProxyHttp,                    //http
    wpProxyHttps,                   //https代理
    wpProxySockets                  //socket代理
}WebProxyType;

@interface FQWebProxySettings : NSObject
{
    NSString       *proxyUserName;
    NSString       *proxyPassWord;
    NSString       *proxyDomain;
    NSString       *proxyHost;
    WebProxyType    proxyType;
    NSInteger       proxyPort;
    NSURL          *pacFileURL;
}

@property (nonatomic,retain) NSString       *proxyUserName;
@property (nonatomic,retain) NSString       *proxyPassWord;
/*
    主要是针对NTLM授权时使用
 */
@property (nonatomic,retain) NSString       *proxyDomain;
@property (nonatomic,retain) NSString       *proxyHost;
@property (nonatomic,assign) WebProxyType    proxyType;
@property (nonatomic,assign) NSInteger       proxyPort;
/*
    使用PAC 文件进行配置代理,URL可能是本地file://也可能是网上的pac文件。
 */
@property (nonatomic,retain) NSURL          *pacFileURL;


@end
