//
//  FQWebGlobalCookies.m
//  FQFrameWork
//
//  Created by fengsh on 13-2-27.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//
//  Copyright (c) 2014年 fengsh998@163.com
//  blog:http://blog.csdn.net/fengsh998

#import "FQWebGlobalCookies.h"

@interface FQWebGlobalCookies()
{
    NSMutableDictionary     *cookiesDictionary;
}
@end

@implementation FQWebGlobalCookies

static FQWebGlobalCookies *globalCookiesInstance = nil;

+ (id)globalCookiesManager
{
    if (!globalCookiesInstance) {
        static dispatch_once_t GCM = 0;
        dispatch_once(&GCM,^{
            globalCookiesInstance = [[FQWebGlobalCookies alloc]init];
        });
    }
    return globalCookiesInstance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        cookiesDictionary   = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (void)dealloc
{
    [cookiesDictionary release];
    [super dealloc];
}

/*
 对每份URL产生的Cookie 保存起来，以便管理
 对响应头域中的cookie进行保存
 */
- (void)storeResponseCookies:(NSDictionary *)headerFields forURL:(NSURL *)requrl
{
    @synchronized (cookiesDictionary) {
        NSArray *newCookies = [NSHTTPCookie cookiesWithResponseHeaderFields:headerFields forURL:requrl];
        
        if ([newCookies count] > 0)
        {
            NSHTTPCookie *cookie;
            NSMutableArray *globalCookies = [[NSMutableArray alloc]init];
            for (cookie in newCookies)
            {
                [globalCookies addObject:cookie];
            }
            
            //如果URL相同会把旧的替换掉
            if ([globalCookies count] > 0)
            {
                [cookiesDictionary setObject:globalCookies forKey:requrl];
            }
            
            [globalCookies release];
            
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:newCookies forURL:requrl mainDocumentURL:nil];
        }
    }
}
/*
 通过requrl获取对应的cookie
 返回url所有对应的cookie
 */
- (NSArray *)getCookiesByURL:(NSURL *)requrl
{
    NSArray *cookies = nil;
    @synchronized (self)
    {
        cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[requrl absoluteURL]];
    }
    return cookies;
}
/*
 通过getCookiesByURL提取出的cookies 解释出可以被请求头域Cookie使用的字符值
 返回一个供Cookie头域使用的值，如果提取不到返回nil
 */
- (NSString *)makeCookieValueOfHeaderByCookies:(NSArray *)cookies
{
    NSString *cookieHeader = nil;
    @synchronized (self){
        if ([cookies count] > 0)
        {
            NSHTTPCookie *cookie;
            
            for (cookie in cookies)
            {
                if (!cookieHeader) {
                    cookieHeader = [NSString stringWithFormat: @"%@=%@",[cookie name],[cookie value]];
                } else {
                    cookieHeader = [NSString stringWithFormat: @"%@; %@=%@",cookieHeader,[cookie name],[cookie value]];
                }
            }
        }
    }
    return cookieHeader;
}

- (NSString *)makeCookieValueOfHeaderByURL:(NSURL *)requrl
{
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[requrl absoluteURL]];
    return [self makeCookieValueOfHeaderByCookies:cookies];
}
/*
 通过URL清除Cookie
 */
- (void)deleteCookiesByURL:(NSURL *)requrl
{
    @synchronized (cookiesDictionary){
        NSArray *cookies = [cookiesDictionary objectForKey:requrl];
        for (NSHTTPCookie *cookie in cookies)
        {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
        
        [cookiesDictionary removeObjectForKey:requrl];
    }
}
/*
 所有URL
 */
- (NSArray *)allURL
{
    NSArray *urls = nil;
    @synchronized (cookiesDictionary){
        urls = [cookiesDictionary allKeys];
    }
    return urls ? urls : [NSArray array];
}

@end
