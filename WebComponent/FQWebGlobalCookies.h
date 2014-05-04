//
//  FQWebGlobalCookies.h
//  FQFrameWork
//
//  Created by fengsh on 13-2-27.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//
//  Copyright (c) 2014年 fengsh998@163.com
//  blog:http://blog.csdn.net/fengsh998


//              全局 Cookies

#import <Foundation/Foundation.h>

@interface FQWebGlobalCookies : NSObject
/*
    全局单例
 */
+ (id)globalCookiesManager;
/*
    对每份URL产生的Cookie 保存起来，以便管理
    对响应头域中的cookie进行保存
 */
- (void)storeResponseCookies:(NSDictionary *)headerFields forURL:(NSURL *)requrl;
/*
    通过requrl获取对应的cookie
    返回url所有对应的cookie
 */
- (NSArray *)getCookiesByURL:(NSURL *)requrl;
/*
    通过getCookiesByURL提取出的cookies 解释出可以被请求头域Cookie使用的字符值
    返回一个供Cookie头域使用的值，如果提取不到返回nil
 */
- (NSString *)makeCookieValueOfHeaderByCookies:(NSArray *)cookies;
- (NSString *)makeCookieValueOfHeaderByURL:(NSURL *)requrl;
/*
    通过URL清除Cookie
 */
- (void)deleteCookiesByURL:(NSURL *)requrl;
/*
    所有URL
 */
- (NSArray *)allURL;
@end
