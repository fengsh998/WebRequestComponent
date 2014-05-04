//
//  FQWebEngine.h
//  FQFrameWork
//
//  Created by fengsh on 13-2-27.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//
//  Copyright (c) 2014年 fengsh998@163.com
//  blog:http://blog.csdn.net/fengsh998
//
//                      状态码RFC资料
//  http://zh.wikipedia.org/wiki/HTTP%E7%8A%B6%E6%80%81%E7%A0%81
//
/*  1.重定向                                   supported
    2.超时                                     supported
    3.gzip                                    supported
    4.cancel                                  supported
    5.cookies                                 supported
    6.https ssl                               supported
    7.proxy                                   supported(Credentials nok)
    8.cache
    9.post/get/put/delete                     supported
   10.断点续传下载                              supported
   11.等待多个请求完成后才统一抛通知(因为有时同一功能调用多个接口，需要等待所有接口完成) supported
   12.串行请求/并发请求                          supported
   13.ios后台运行下载                           supported(600s)
   14.长链接支持
 
 
 unsupport BUG:
    对于响应头Transfer-Encoding中带chunked时的解编码未处理（目前暂未支持）。后期碰到相应的问题时补上。
 
 
 mac 只支持64位编译，不支持32位编译，因此使用xcode 5.0 以上版本
 ios 支持xcode 4.6以上。ios SDK支持5.0及更高版本
 
 依赖:
    ios : UIKit.framework,mobileCoreServices.framework
    mac : systemConfiguration.framework,cocoa.framework,appkit.framework
    sdk依赖(ios,mac共同依赖):CFNewwork.framework,libz.dylib,Foundation.framework
*/

#import <Foundation/Foundation.h>
#import "FQWebProxySettings.h"


typedef unsigned long long  FQULLInteger;

typedef NSMutableArray FQWebRequestList;

@interface  FQWebRequestAbstractList : NSObject

/**
 *	@说明	获取所有添加的请求
 *
 *	@return	所有添加的请求
 */
- (NSArray *)allRequest;

- (void)requestfinsh;

@end

/**************************************************************************************************
 
 FQWebHeaders class
 
 **************************************************************************************************/

#pragma mark - FQWebHeaders class
@interface FQWebHeaders : NSObject<NSCopying>
{
    NSMutableDictionary         *headers;
}

#pragma mark FQWebHeaders 属性
@property (nonatomic,readonly)  NSMutableDictionary                 *headers;

#pragma mark FQWebHeaders 成员函数
/**
  *     默认uesr agent
  */
+ (NSString *)defaultUseAgent;
/**
  *     增加多个头域
  */
- (void)addHeadersFromDictionary:(NSDictionary *)dictionary;
/**
  *     设置一个头域和值
  */
- (void)setHeaderName:(NSString *)name WithValue:(NSString*)value;
/**
  *     通过头域名获取对应的值，如果没有该域名对应的值，返回nil
  */
- (NSString *)getHeaderValueByName:(NSString*)name;
/**
  *     移除一个头域
  */
- (void)removeHeaderByName:(NSString *)name;
/**
  *     移除所有头域
  */
- (void)removeAllHeaders;
/**
  *     获取头域的字段数
  */
- (NSInteger)headerCounts;
/**
  *     以字符的形工输出当前所有头域信息
  */
- (NSString *)toString;

@end


/**************************************************************************************************
 
                                    FQWebResquestHeaders class
 
 **************************************************************************************************/
#pragma mark - FQWebResquestHeaders class
@interface FQWebResquestHeaders : FQWebHeaders

#pragma mark FQWebResquestHeaders 属性
/*      返回请求头域字典        */
@property (nonatomic,readonly) NSDictionary             *values;
/*      获取Accept头域的值     */
@property (nonatomic,readonly) NSString                 *acceptValue;
/*      获取UserAgent头域的值  */
@property (nonatomic,readonly) NSString                 *userAgentValue;
/*      获了Connection头域值   */
@property (nonatomic,readonly) NSString                 *connectionValue;
/*      获取Content-Length值  */
@property (nonatomic,readonly) NSString                 *contentLength;
/*  如果当前请求头域 Connection = "keep-alive" 则返回TRUE 返之FALSE  */
@property (nonatomic,readonly) BOOL                     isRequestKeepLive;
/*      获取Range头域值        */
@property (nonatomic,readonly) NSString                 *range;

#pragma mark FQWebResquestHeaders 成员函数
/**
  *     根所头域字点产生实例
  */
+ (id)requestHeadersWithDictionary:(NSDictionary *)headerDictionary;
/**
  *     根所json格式的头域生成实例 （未实现）
  */
+ (id)requestHeadersWithJsonString:(NSString *)jsonstring;
/**
  *     根所xml格式的头域生成实例 （未实现）
  */
+ (id)requestHeadersWithXmlString:(NSString *)xmlString;
/**
  *     通过dic设置请求头域
  */
- (void)setRequestHeaderByDictionary:(NSDictionary *)headerDictionary;
/**
  *     设置请求头域
  *     name  : 域名称
  *     value : 域对应的值
  */
- (void)setRequestHeader:(NSString *)name value:(NSString*)value;
/**
  *     移除头域
  *     name  : 域名称
  */
- (void)removeRequestHeaderByName:(NSString *)name;
/**
  *     移除所有头域
  */
- (void)removeAllRequestHeaders;

- (NSInteger) count;
- (NSString *)requestHeadersString;

/**
  *  调用此方法，会自动添加一些头域当用户没有设置时
  *  如：User-Agent
  */
- (void)reBuildRequestHeader;
@end


/**************************************************************************************************
 
                                    FQWebResponseHeaders class
 
 **************************************************************************************************/
#pragma mark - FQWebResponseHeaders class
@interface FQWebResponseHeaders : FQWebHeaders
{
@private
    NSInteger                statusCode;
    NSString                 *httpVersion;
    NSString                 *statuLine;
    CFHTTPAuthenticationRef  authenticationInfo;
}

#pragma mark FQWebResponseHeaders 属性
/*      返回响应头域字典           */
@property (nonatomic,readonly) NSDictionary             *values;
/*      响应的状态码   1xx,2xx,3xx,4xx,5xx    */
@property (nonatomic,assign)   NSInteger                statusCode;
/*      响应的http版本号          */
@property (nonatomic,readonly) NSString                 *httpVersion;
/*      响应的状态行              */
@property (nonatomic,readonly) NSString                 *statuLine;
/*      从Content-Type头域提取出来的内容编码    */
@property (nonatomic,readonly) NSStringEncoding         responseEncoding;
/*      从Content-Length中获取的值            */
@property (nonatomic,readonly) unsigned long long       contentLength;
/*      从Content-Encoding中获取内容是否被gzip压缩    */
@property (nonatomic,readonly) BOOL                     isResponseCompressed;
/*      判断请求是否需要重定向       */
@property (nonatomic,readonly) BOOL                     requestShouldRedirect;
/*      重定向的URL               */
@property (nonatomic,readonly) NSString                 *redirectURL;
/*      传输编码，不是内容编码，一般情况下与content-length互斥
        其值只有(identity 没有编码,chunked 分块传输 )   */
@property (nonatomic,readonly) NSString                 *transferEncoding;
/*      从Content-Description中取值          */
@property (nonatomic,readonly) NSString                 *contentDisposition;
/*      从Content-Range中提取值                      */
@property (nonatomic,readonly) NSString                 *contentRange;
/*      从Content-Type中提取值               */
@property (nonatomic,readonly) NSString                 *contentType;
/*      响应的(401 或 407)时响应头中的认证信息  */
@property (nonatomic,readonly) CFHTTPAuthenticationRef  authenticationInfo;

#pragma mark FQWebResponseHeaders 成员函数
+ (id)responseHeadersWithDictionary:(NSDictionary *)headerDictionary;
+ (id)responseHeadersWithJsonString:(NSString *)jsonstring;
+ (id)responseHeadersWithXmlString:(NSString *)xmlString;

- (void)setResponseHeaderByDictionary:(NSDictionary *)headerDictionary;
- (void)setResponseHeader:(NSString *)name value:(NSString*)value;
- (void)setResponseHttpVersion:(NSString *)httpversion;
- (void)setResponseStatuLine:(NSString *)statuline;
- (void)setAuthenticationInfo:(CFHTTPAuthenticationRef)authentication;


- (void)removeResponseHeaderByName:(NSString *)name;
- (void)removeAllResponseHeaders;

- (NSInteger) count;
- (NSString *)responseHeadersString;

@end


/**************************************************************************************************
 
                                    FQWebRequestAbstract class
 
 **************************************************************************************************/
#pragma mark - FQWebRequestAbstract class
@interface FQWebRequestAbstract : NSObject
{
    FQWebProxySettings      *proxySettings;
}

#pragma mark FQWebRequestAbstract 属性
/*********************************************请求属性**********************************************/
/*  每个请求唯一ID            */
@property (nonatomic,readonly) NSString                     *requestID;
/*  便于调用者设定自己的tag请求 */
@property (nonatomic,readonly) NSInteger                    tag;
/*  便于调用者在上下文中进行区别时使用 */
@property (nonatomic,readonly) NSString                     *identity;
/*  请求URL                  */
@property (nonatomic,retain)   NSURL                        *reqUrl;
/*  获取请求方法              */
@property (nonatomic,readonly) NSString                     *requestMethod;
/*  获取请求是否被取消         */
@property (nonatomic,readonly) BOOL                         isCancelRequest;
/*  请求是否超时              */
@property (nonatomic,readonly) BOOL                         isTimeOut;
/*  请求超时时间（毫秒）       */
@property (nonatomic,readonly) NSTimeInterval               requestTimeOutInterval;
/*  获取请求头域              */
@property (nonatomic,readonly) FQWebResquestHeaders         *requestHeader;
/*  是否为https请求           */
@property (nonatomic,readonly) BOOL                         isHttpsRequest;
/**************************************************************************************************/
/*********************************************响应属性**********************************************/
/*  获取响应头               */
@property (nonatomic,readonly) FQWebResponseHeaders         *responseHeader;
/*  响应的流数据              */
@property (nonatomic,readonly) NSData                       *responseData;
/*  响应的字符串(默认情况下会根据响应头的encoding进行解码)
    但如果发现头域中没有找到对应的编码会以NSISOLatin1StringEncoding作为默认编码。
    但发现NSISOLatin1StringEncoding这个对某此GBK,和GB2312的支持不太好，因此可能
    会解出乱码，如果有解出的乱码的情下，可以在外部使用
    CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)
    重新对responseData进行解码即可
 */
@property (nonatomic,readonly) NSString                     *responseStrings;
/**************************************************************************************************/

/*******************************************请求配置属性*********************************************/
/*  cookies 持久性，当为True时，保存响应的cookies 否则不保存,默认为TRUE*/
@property (nonatomic,assign)   BOOL                         autoSaveUseCookies;

/*  设定HTTP请求的版本1.0 TRUE, 默认为1.1 :False           */
@property (nonatomic,assign)   BOOL                         useHttpVersion10;

/*  重定向深度 默认为5，如果超过5重重定向，则自动失败          */
@property (nonatomic,assign)   NSInteger                    maxRedirectCount;
/*  应该压缩请求体(针对post body)   default : NO          */
@property (nonatomic,assign)   BOOL                         shouldCompressRequestBody;
/*  设置代理                                            */
@property (nonatomic,retain)   FQWebProxySettings           *proxySettings;
/*  用户取消验证安全证书，当设为TRUE时客户端将不去验证证书
    默认为NO                                            */
@property (nonatomic,assign)   BOOL                         cancelValidatesSecureCertificate;
/*  当证书验证失败时，是否继续进行访问，如果YES，则此次的访问
    将不会验证服务器证书,如果是NO,则终止访问                 */
@property (nonatomic,assign)   BOOL                         continueRequestWhenSSLFailed;
/*
 只针对ios有效，内部集成了，退到后台时申请10分钟的运行时间
 */
@property (nonatomic,assign)   BOOL                         shouldContinueWhenAppEntersBackground;
/**************************************************************************************************/

/*  是否允许并发,默认是YES,当设为NO是则是串行请求            */
@property (nonatomic,readonly)   BOOL                         allowComplicating;

#pragma mark - FQWebRequestAbstract 成员函数
+ (void)attchToSendQueue:(FQWebRequestAbstract *)task;
/*  
 *      设置请求超时时间 
 *      interval :时间单位为毫秒如1稍则设为1000
 *      最小值不能低于3000
 */
- (void)setRequestTimeout:(NSTimeInterval)interval;
/*  
 *      请求体的原始数据
 */
- (void)setPostData:(NSMutableData *)postBody;
/*
 *      设置直接post文件的路径通常用于PUT大的文件
 *      filePath:带路径的文件名
 */
- (void)setPostBodyFromFile:(NSString *)filePath;

/**
 *     构键请求体,必须确保postBody有数据
 *     返回流对象表示成功，nil失败
 */
- (NSInputStream *)buildRequestBody;

//请求被用户取消后
- (void)requestCanceled;
//请求开始
- (void)requestStarted;
//请求失败
- (void)requestFailed;
//请求完成
- (void)requestFinish;
//响应头读取完成
- (void)responseReadHeaderFinish;
//接收数据
- (void)receviceProgress:(FQULLInteger)totalsize withReviced:(FQULLInteger)recevicesize;
//每次接收的数据
- (void)receviceData:(const void *)bufferBytes length:(NSUInteger)length;
//发送数据
- (void)sendProgress:(FQULLInteger)totalsize withSended:(FQULLInteger)sendsize;
//将得定向URL
- (void)doWillRedirectUrl:(NSURL *)redirectUrl;
// 当重新发请求前进行清空缓存变量
- (void)cleanMemoryWhileReSendRequest;
//请求需要认证
- (NSDictionary *)requestNeedAuthentication;
- (NSDictionary *)requestNeedProxyAuthentication;
//当证书不受信任时，需要用户返回True继续进行不安全连接，FALSE则停止本次连接
- (BOOL)requestWhenHadMistrustCertificate;

@end


/**************************************************************************************************
 
                                    FQWebEngine class
 
 **************************************************************************************************/
#pragma mark - FQWebEngine class
@interface FQWebEngine : NSObject

+ (FQWebEngine*)shareInstance;

/*
    并发线程
 */
- (void)addRequest:(FQWebRequestAbstract *)request;

/*
    串行线程，必须等待第一个完成才能到下一个
 */
- (void)addSerialRequest:(FQWebRequestAbstract *)request;

/*
    多个请求都完成后，最后才通知用户
    FQWebRequestAbstractList 存放多个FQWebRequestAbstract的子类
    使用此方法须小心，因为此方法只支持一次请求访问，如果请求的URL有重定向或需要认证的，则使用些方法时
    不会自动等待重定向。
    目前此方法使用只适用于每个请求的URL都是一次请求就完成的。
 */
- (void)addGroupRequest:(FQWebRequestAbstractList *)requestlist;

@end

