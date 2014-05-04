//
//  FQWebEngine.m
//  FQFrameWork
//
//  Created by fengsh on 13-2-27.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//
//  Copyright (c) 2014年 fengsh998@163.com
//  blog:http://blog.csdn.net/fengsh998
/*
 
 辅助资料:
    使用CFNetwork框架（CFHttp），设置 CFHTTPMessageSetHeaderFieldValue(request, CFSTR("Connection"), 
    CFSTR("Keep-Alive")); 并不会生效。原因是框架会接管这一属性，所以即使你做了这样的设置，抓包后你可以看到conn
    -ection的属性还是被设置成了closed，如果需要更改connection的属性，就必须设置CFReadStreamSetProperty(re-
    adStream, kCFStreamPropertyHTTPAttemptPersistentConnection, kCFBooleanTrue);
 */
 
#import "FQWebEngine.h"
#import "FQWebEngineDefines.h"
#import "FQWebEngineError.h"
#import "FQWebGlobalCookies.h"
#import "FQWebEngineZlibX.h"
#import "FQWebAuthenticationManager.h"

#if TARGET_OS_IPHONE
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>
#else
#import <SystemConfiguration/SystemConfiguration.h>
#endif

#import <CFNetwork/CFNetwork.h>
#ifdef FQLOG
#import "FQLogAPI.h"
#endif


#define MIN_REQUEST_TIMEOUT_MINCSECONDS     3000                    //最小超时时间3秒
#define TEMP_COMPRESS_FILEEXT               @".cps"                 //用于存放临时被压缩的文件后缀
#define AUTHENTICATION_FAIL_COUNTS          3                       //认证失败3次则不再重新认证

#define DIRECT_CALL_ERROR                   FQWebComponentErrorLog(@"Abstract Class Call Error,can not to opration Abstract lcass")


@implementation  FQWebRequestAbstractList

- (NSArray *)allRequest
{
    //sub class to do.
    return nil;
}

- (void)requestfinsh
{
    //sub class to do.
}
@end
/**************************************************************************************************
 
                                FQWebHeaders class implementation
 
 **************************************************************************************************/
#pragma mark - FQWebHeaders implementation
@interface FQWebHeaders ()
{

}

@end

@implementation FQWebHeaders
@synthesize headers;

+ (NSString *)defaultUseAgent
{
    @synchronized (self) {
        
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        
        // 从plist中获取应用程序名
        NSString *appName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        if (!appName) {
            appName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
        }
        
        NSData *latin1Data = [appName dataUsingEncoding:NSUTF8StringEncoding];
        appName = [[[NSString alloc] initWithData:latin1Data encoding:NSISOLatin1StringEncoding] autorelease];
        
        //如果找不到，就直接使用 CFNetwork中的 user agent
        if (!appName) {
            return nil;
        }
        
        NSString *appVersion = nil;
        NSString *marketingVersionNumber = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString *developmentVersionNumber = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        if (marketingVersionNumber && developmentVersionNumber) {
            if ([marketingVersionNumber isEqualToString:developmentVersionNumber]) {
                appVersion = marketingVersionNumber;
            } else {
                appVersion = [NSString stringWithFormat:@"%@ rv:%@",marketingVersionNumber,developmentVersionNumber];
            }
        } else {
            appVersion = (marketingVersionNumber ? marketingVersionNumber : developmentVersionNumber);
        }
        
        NSString *deviceName;
        NSString *OSName;
        NSString *OSVersion;
        NSString *locale = [[NSLocale currentLocale] localeIdentifier];
        
#if TARGET_OS_IPHONE 
        //uikit.framework
        UIDevice *device = [UIDevice currentDevice];
        deviceName = [device model];
        OSName = [device systemName];
        OSVersion = [device systemVersion];
        
#else
        deviceName = @"Macintosh";
        OSName = @"Mac OS X";
        
        OSVersion = [[NSProcessInfo processInfo] operatingSystemVersionString];
        
        //    #if __MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_8
        //            //取得版本序号
        //            OSErr err;
        //            SInt32 versionMajor, versionMinor, versionBugFix;
        //            err = Gestalt(gestaltSystemVersionMajor, &versionMajor);
        //            if (err != noErr) return nil;
        //            err = Gestalt(gestaltSystemVersionMinor, &versionMinor);
        //            if (err != noErr) return nil;
        //            err = Gestalt(gestaltSystemVersionBugFix, &versionBugFix);
        //            if (err != noErr) return nil;
        //            OSVersion = [NSString stringWithFormat:@"%u.%u.%u", versionMajor, versionMinor, versionBugFix];
        //    #else
        //            OSVersion = @"little 10.8";
        //    #endif
#endif
        
        // 格式 "My Application 1.0 (Macintosh; Mac OS X 10.8.5; en_GB)"
        return [NSString stringWithFormat:@"%@ %@ (%@; %@ %@; %@) FQWebEngine V%@", appName, appVersion, deviceName, OSName, OSVersion, locale,FQWebEngineVersion];
	}
    
	return nil;
}

-(id)init
{
    self = [super init];
    if (self) {
        headers = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (void)dealloc
{
    [headers release];
    [super dealloc];
}

- (void)setHeaderName:(NSString *)name WithValue:(NSString*)value
{
    @synchronized (self)
    {
        [headers setObject:value forKey:name];
    }
}

- (NSString *)getHeaderValueByName:(NSString*)name
{
    return [headers objectForKey:name];
}

- (void)removeHeaderByName:(NSString *)name
{
    @synchronized (self)
    {
        [headers removeObjectForKey:name];
    }
}

- (void)removeAllHeaders
{
    @synchronized (self)
    {
        [headers removeAllObjects];
    }
}

- (NSInteger)headerCounts
{
    return [headers count];
}

- (NSString *)toString
{
    @synchronized (self)
    {
       NSString *retstr = nil;
        NSMutableArray *itemvlaues = [NSMutableArray array];
        for (NSString *item in headers)
        {
            NSString *tmp = [item stringByAppendingFormat:@" = \"%@\"",[headers objectForKey:item]];
            [itemvlaues addObject:tmp];
        }
        
        if ([itemvlaues count] > 0) {
            retstr = [itemvlaues componentsJoinedByString:@"\n"];
        }
        
        return retstr;
    }
}

- (void)addHeadersFromDictionary:(NSDictionary *)dictionary
{
    [headers addEntriesFromDictionary:dictionary];
}

- (id)copyWithZone:(NSZone *)zone
{
	FQWebHeaders *webheader = [[self class]allocWithZone:zone];
    webheader->headers = [[self->headers mutableCopyWithZone:zone]autorelease];
    
	return webheader;
}

@end

/**************************************************************************************************
 
                        FQWebResquestHeaders class implementation
 
 **************************************************************************************************/
#pragma mark - FQWebResquestHeaders class implementation

@implementation FQWebResquestHeaders

+ (id)requestHeadersWithDictionary:(NSDictionary *)headerDictionary
{
    FQWebResquestHeaders *reqheader = [[[self alloc]init]autorelease];
    [reqheader removeAllHeaders];
    [reqheader addHeadersFromDictionary:headerDictionary];
    
    return reqheader;
}

+ (id)requestHeadersWithJsonString:(NSString *)jsonstring
{
    //to do later.
    return nil;
}

+ (id)requestHeadersWithXmlString:(NSString *)xmlString
{
    //to do later.
    return nil;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@",self->headers];
}

- (void)setRequestHeaderByDictionary:(NSDictionary *)headerDictionary
{
    [super addHeadersFromDictionary:headerDictionary];
}

-(NSDictionary*)values
{
    return self->headers;
}

- (BOOL)isRequestKeepLive
{
    NSString *connection = [self->headers objectForKey:http_Connection];
    if (connection) {
        connection = [connection lowercaseString];
        if ([connection isEqualToString:@"keep-alive"])
        {
            return YES;
        }
    }
    return NO;
}

- (void)setRequestHeader:(NSString *)name value:(NSString*)value
{
    [super setHeaderName:name WithValue:value];
}

- (void)removeRequestHeaderByName:(NSString *)name
{
    [super removeHeaderByName:name];
}

- (void)removeAllRequestHeaders
{
    [super removeAllHeaders];
}

- (NSInteger) count
{
    return [super headerCounts];
}

- (NSString *)requestHeadersString
{
    return [super toString];
}

- (NSString *)range
{
    return [self->headers objectForKey:http_Range];
}

- (NSString *)acceptValue
{
    return [self->headers objectForKey:http_Accept];
}

- (NSString *)contentLength
{
    return [self->headers objectForKey:http_Content_Length];
}

- (NSString *)userAgentValue
{
    NSString *uagent = [self->headers objectForKey:http_User_Agent];
    if (!uagent) {
        uagent = [self.superclass defaultUseAgent];
    }
    return uagent;
}

- (NSString *)connectionValue
{
    return [self->headers objectForKey:http_Connection];
}

- (void)reBuildRequestHeader
{
    if (![self->headers objectForKey:http_User_Agent])
    {
        [self setRequestHeader:http_User_Agent value:[self.superclass defaultUseAgent]];
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    FQWebResquestHeaders *reqheader = [super copyWithZone:zone];
    
    return reqheader;
}

@end


/**************************************************************************************************
 
                            FQWebResponseHeaders class implementation
 
 **************************************************************************************************/

#pragma mark - FQWebResponseHeaders class implementation
@implementation FQWebResponseHeaders
@synthesize statusCode;
@synthesize httpVersion;
@synthesize statuLine;
@synthesize authenticationInfo;

+ (id)responseHeadersWithDictionary:(NSDictionary *)headerDictionary
{
    FQWebResponseHeaders *rspheader = [[[self alloc]init]autorelease];
    [rspheader removeAllHeaders];
    [rspheader addHeadersFromDictionary:headerDictionary];
    
    return rspheader;
}

+ (id)responseHeadersWithJsonString:(NSString *)jsonstring
{
    return nil;
}

+ (id)responseHeadersWithXmlString:(NSString *)xmlString
{
    return nil;
}

+ (void)parseMimeType:(NSString **)mimeType andResponseEncoding:(NSStringEncoding *)stringEncoding fromContentType:(NSString *)contentType
{
	if (!contentType) {
		return;
	}
	NSScanner *charsetScanner = [NSScanner scannerWithString: contentType];
	if (![charsetScanner scanUpToString:@";" intoString:mimeType] || [charsetScanner scanLocation] == [contentType length]) {
		*mimeType = [contentType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		return;
	}
	*mimeType = [*mimeType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSString *charsetSeparator = @"charset=";
	NSString *IANAEncoding = nil;
    
	if ([charsetScanner scanUpToString: charsetSeparator intoString: NULL] && [charsetScanner scanLocation] < [contentType length])
    {
		[charsetScanner setScanLocation: [charsetScanner scanLocation] + [charsetSeparator length]];
		[charsetScanner scanUpToString: @";" intoString: &IANAEncoding];
	}
    
	if (IANAEncoding)
    {
        CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)IANAEncoding);
        if (cfEncoding != kCFStringEncodingInvalidId) {
            *stringEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
        }
	}
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"%@",self->headers];
}

- (void)dealloc
{
    [httpVersion release];
    [statuLine release];
    
    if (authenticationInfo) {
        CFRelease(authenticationInfo);
        authenticationInfo = nil;
    }
    
    [super dealloc];
}

#pragma mark FQWebResponseHeaders getter
- (NSStringEncoding)responseEncoding
{
    NSStringEncoding charset = 0;
	NSString *mimeType = nil;
    
	[[self class] parseMimeType:&mimeType
            andResponseEncoding:&charset
                fromContentType:[self->headers valueForKey:@"Content-Type"]];
	if (charset != 0)
    {
		return charset;
	}
    //对于中文件的html最好是返回encode , NSISOLatin1StringEncoding对中文的支持不好。
    //unsigned long encode = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    return NSISOLatin1StringEncoding; //default
}

- (unsigned long long)contentLength
{
    return [[self->headers objectForKey:http_Content_Length] longLongValue];
}

- (NSString *)transferEncoding
{
    return [self->headers objectForKey:http_Transfer_Encoding];
}

-(NSDictionary*)values
{
    return self->headers;
}

- (NSString *)contentDisposition
{
    return [self->headers objectForKey:http_Content_Disposition];
}

- (NSString *)contentRange
{
    return [self->headers objectForKey:http_Content_Range];
}

- (NSString *)contentType
{
    return [self->headers objectForKey:http_Content_Type];
}

//查看响应的数据是否被压缩了
- (BOOL)isResponseCompressed
{
	NSString *encoding = [self->headers objectForKey:http_Content_Encoding];
	return encoding && [encoding rangeOfString:@"gzip"].location != NSNotFound;
}

- (NSString *)redirectURL
{
    return [self->headers valueForKey:http_Location];
}

- (BOOL)requestShouldRedirect
{
    //如果不含有Location，则不需要重定向
    if (!self.redirectURL)
    {
        return NO;
    }
    //如果有location 看响应码
    NSInteger stcode = self.statusCode;
	if ( stcode != 301 && stcode != 302 && stcode != 303 && stcode != 307)
    {
		return NO;
	}
    
    return YES;
}

#pragma mark FQWebResponseHeaders setter
- (void)setResponseHeaderByDictionary:(NSDictionary *)headerDictionary
{
    [super addHeadersFromDictionary:headerDictionary];
}

- (void)setResponseHeader:(NSString *)name value:(NSString*)value
{
    [super setHeaderName:name WithValue:value];
}

- (void)setResponseHttpVersion:(NSString *)httpversion
{
    [httpVersion release];
    httpVersion = nil;
    httpVersion = [httpversion retain];
}

- (void)setResponseStatuLine:(NSString *)statuline
{
    [statuLine release];
    statuLine = nil;
    statuLine = [statuline retain];
}

- (void)setAuthenticationInfo:(CFHTTPAuthenticationRef)authentication
{
    if (authenticationInfo) {
        CFRelease(authenticationInfo);
        authenticationInfo = nil;
    }

    authenticationInfo = (CFHTTPAuthenticationRef)CFRetain(authentication);
}
#pragma mark 其它
- (void)removeResponseHeaderByName:(NSString *)name
{
    [super removeHeaderByName:name];
}

- (void)removeAllResponseHeaders
{
    [super removeAllHeaders];
}

- (NSInteger)count
{
    return [super headerCounts];
}

- (NSString *)responseHeadersString
{
    return [super toString];
}

- (id)copyWithZone:(NSZone *)zone
{
    FQWebResponseHeaders *rspheader = [super copyWithZone:zone];
    
    return rspheader;
}

@end


/**************************************************************************************************
 
                                FQWebRequestAbstract class implementation
 
 **************************************************************************************************/
#pragma mark - FQWebRequestAbstract implementation
@interface FQWebRequestAbstract ()
{
    //最后心跳时间
    NSDate                  *lastActivityTime;
    dispatch_source_t       requesttimesourc;
    dispatch_queue_t        timerQueue;
    //用来记录重定向执行次数
    NSInteger               redirectRec;
    NSMutableData           *postBodyData;              /*未压缩的body*/
    NSMutableData           *compressPostBodyData;      /*经压缩的body*/
    
    unsigned long long      recevicebytesTotal;         //用于记录总长度
    
    NSString                *postBodyFilePath;          //需要post的文件全路径名(path+filename)
    NSString                *compressFilePath;          //通过对postBodyFilePath文件的压缩产生的

    CFHTTPMessageRef        currentRequestHandle;       //存放当前请求的handle，以备后期重发请求时，不需要再次新建请求，使用原来的请求即可
    NSInteger               authenticaionNums;          //认证次数
    
#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
	UIBackgroundTaskIdentifier backgroundTask;
#endif
}
@property (nonatomic,retain) NSMutableData           *postBodyData;
@property (nonatomic,retain) NSMutableData           *compressPostBodyData;
@property (nonatomic,retain) NSString                *postBodyFilePath;
@property (nonatomic,retain) NSString                *compressFilePath;
@property (nonatomic,assign) CFHTTPMessageRef        currentRequestHandle;
@property (nonatomic,assign) NSInteger               authenticaionNums;
#pragma mark FQWebRequestAbstract 私有函数声明
- (void)startRequestTimer:(CFReadStreamRef)sender;
- (void)stopRequestTimer;
- (void)shouledRefreshActivityTime;

//ios 后台申请10分钟运行时间
- (void)applyBackGroundTenMinuteTask;

/*
 *      检测代理设置是否正确
 */
- (BOOL)checkProxyConfigations;
/*
 *      获取代理配置
 */
- (NSMutableDictionary *)getProxyConfigationsInfo;

//回调
- (void)handleFetchResponsHeaderFinish;
- (void)handleReceiveData:(const void *)bufferBytes length:(NSUInteger)length;
/**
 *  报告并分发错码给上层
 */
- (void)handleFailedAndError:(NSError *)error;

- (void)handleRequestFinish;

//通知
//请求已经开始
- (void)doRequestStartedDispatcher;
- (void)doRequestFinishDispatcher;
- (void)doRequestFailedDispatcher;
- (void)doUesrCancelRequestDispatcher;
- (void)doProgressIndicatorOfTotalSize:(unsigned long long)totalSize
                     withRecevicedSize:(unsigned long long)receviceSize;


- (NSDictionary *)doAskAuthenticationDelegate;
- (NSDictionary *)doAskProxyAuthenticationDelegate;
- (BOOL)doAskContinueUseUnsafeConnection;



//存储，缓存
/*如果上次请求带回Cookies保存下来以便下次访问时用*/
- (void)applyCookies;
- (void)applyAuthenticationToCureentRequest:(CFHTTPMessageRef)curRequest;
- (void)storeResponseCookies;

//检查项
- (BOOL)hasPostBody;
//重新发送请求
- (void)resendRequest;

@end

@implementation FQWebRequestAbstract
@synthesize requestID;
@synthesize isCancelRequest;
@synthesize requestMethod;
@synthesize requestHeader;
@synthesize isTimeOut;
@synthesize requestTimeOutInterval;
@synthesize reqUrl;
@synthesize isHttpsRequest;
@synthesize currentRequestHandle;

@synthesize responseHeader;
@synthesize responseData;
@synthesize responseStrings;

@synthesize autoSaveUseCookies;
@synthesize useHttpVersion10;
@synthesize maxRedirectCount;
@synthesize shouldCompressRequestBody;
@synthesize proxySettings;
@synthesize cancelValidatesSecureCertificate;
@synthesize continueRequestWhenSSLFailed;
@synthesize authenticaionNums;
@synthesize shouldContinueWhenAppEntersBackground;

@synthesize postBodyData;
@synthesize postBodyFilePath;
@synthesize compressFilePath;
@synthesize compressPostBodyData;

+ (void)attchToSendQueue:(FQWebRequestAbstract *)task
{
    [task applyBackGroundTenMinuteTask];
    
    if (task.allowComplicating)
    {
        [[FQWebEngine shareInstance] addRequest:task];
    }
    else
    {
        [[FQWebEngine shareInstance] addSerialRequest:task];
    }
}

#pragma mark 初始化
- (id)init
{
    self = [super init];
    if (self) {
        requestHeader   = [[FQWebResquestHeaders alloc]init];
        responseHeader  = [[FQWebResponseHeaders alloc]init];
        timerQueue      = dispatch_queue_create("com.FQWebRequest.fengsh", 0);

        shouldCompressRequestBody = NO;
        cancelValidatesSecureCertificate = NO;
        continueRequestWhenSSLFailed = NO;
        shouldContinueWhenAppEntersBackground = NO;
        useHttpVersion10 = NO;
        maxRedirectCount = 5;       //将来使用宏进行配置
        redirectRec = 0;
        authenticaionNums = 0;
    }
    return self;
}

- (void)dealloc
{
    [reqUrl release];
    [requestHeader release];
    [responseHeader release];
    [proxySettings release];
    [compressPostBodyData release];
    [postBodyData release];
    [postBodyFilePath release];
    [compressFilePath release];
    [lastActivityTime release];
    
    if (currentRequestHandle) {
        CFRelease(currentRequestHandle);
        currentRequestHandle = nil;
    }
    dispatch_release(timerQueue);
    [super dealloc];
}

//#pragma mark - Copying
//- (id)copyWithZone:(NSZone *)zone
//{
//    FQWebRequestAbstract *webreqatract = [[self class]allocWithZone:zone];
//    
//    return webreqatract;
//}

#pragma mark - ios后台运行申请

#if TARGET_OS_IPHONE
+ (BOOL)isMultitaskingSupported
{
	BOOL multiTaskingSupported = NO;
	if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]) {
		multiTaskingSupported = [(id)[UIDevice currentDevice] isMultitaskingSupported];
	}
	return multiTaskingSupported;
}
#endif

- (void)applyBackGroundTenMinuteTask
{
#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
    if (shouldContinueWhenAppEntersBackground && [[self class]isMultitaskingSupported]) {
        if (!backgroundTask || backgroundTask == UIBackgroundTaskInvalid)
        {
            backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (backgroundTask != UIBackgroundTaskInvalid)
                    {
                        [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
                        backgroundTask = UIBackgroundTaskInvalid;
                        
                        isCancelRequest = YES;
                    }
                });
            }];
        }
    }
#endif
}

#pragma mark -代理检测与配置
- (void)setProxyForPACScript:(NSString *)script
{
	if (script)
    {
        CFErrorRef err = NULL;
		NSArray *proxies = [NSMakeCollectable(CFNetworkCopyProxiesForAutoConfigurationScript((CFStringRef)script,
                                                                                             (CFURLRef)self.reqUrl,
                                                                                             &err))
                            autorelease];
        
		if (!err && [proxies count] > 0)
        {
			NSDictionary *settings = [proxies objectAtIndex:0];

            NSString *proxyhost = [settings objectForKey:(NSString *)kCFProxyHostNameKey];
            NSInteger proxyport = [[settings objectForKey:(NSString *)kCFProxyPortNumberKey] intValue];
            NSString *proxytype = [settings objectForKey:(NSString *)kCFProxyTypeKey];
            
            self.proxySettings.proxyHost = proxyhost;
            self.proxySettings.proxyPort = proxyport;
            
            if ([proxytype isEqualToString:(NSString *)kCFProxyTypeNone])
            {
                self.proxySettings.proxyType = wpProxyNone;
            }
            else if ([proxytype isEqualToString:(NSString *)kCFProxyTypeHTTP])
            {
                self.proxySettings.proxyType = wpProxyHttp;
            }
            else if ([proxytype isEqualToString:(NSString *)kCFProxyTypeHTTPS])
            {
                self.proxySettings.proxyType = wpProxyHttps;
            }
            else if ([proxytype isEqualToString:(NSString *)kCFProxyTypeSOCKS])
            {
                self.proxySettings.proxyType = wpProxySockets;
            }
		}
	}
}

- (BOOL)fetchPACFileInfo
{
    NSURL *pacUrl = self.proxySettings.pacFileURL;
    NSString *scheme = [[pacUrl scheme]lowercaseString];
    NSData *pacdata = nil;
    NSString *pacScript = nil;
    if ([pacUrl isFileURL])
    {
        //读取本地的pac文件
        pacdata = [NSData dataWithContentsOfURL:pacUrl];
        
        if (pacdata)
        {
            pacScript = [[NSString alloc]initWithData:pacdata encoding:NSUTF8StringEncoding];
        }
    }
    else if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"])
    {
        //从网上下载
        //注意网络超时
        //此时请求本身还没有开启计时，所以可以不理会self发起的请求，还没到请求部分呢
        double startpac = CFAbsoluteTimeGetCurrent();
        pacdata = [NSData dataWithContentsOfURL:pacUrl];
        double endpac = CFAbsoluteTimeGetCurrent();
        
        //当从网络上下载pac文件超时时
        if ((endpac - startpac) >= self.requestTimeOutInterval / 1000)
        {
            NSString *reason = @"proxy pac file download timeout.";
            NSError *err = [FQWebError makeFQWebEngineErrorWith:FQWebProxySettingError
                                                      andReason:reason];
            [self handleFailedAndError:err];
            return NO;
        }
        
        if (pacdata)
        {
            pacScript = [[NSString alloc]initWithData:pacdata encoding:NSUTF8StringEncoding];
        }
    }
    
    if (!pacScript)
    {
        NSString *reason = @"proxy pac file load failed.";
        NSError *err = [FQWebError makeFQWebEngineErrorWith:FQWebProxySettingError
                                                  andReason:reason];
        [self handleFailedAndError:err];
        return NO;
    }
    
    //如果脚本中运行出错未进行处理
    [self setProxyForPACScript:pacScript];
    
    [pacScript release];
    
    return YES;
}

- (BOOL)checkProxyConfigations
{
    BOOL ok = YES;
    if (!self.proxySettings) //用户没有外部设定代理
    {
        //检测是否使用系统配置的代理
        ok = [self checkSystemHadSettingProxy];
        //如果读取系统配置有问题则停止访问请求
        if (!ok)
        {
            return ok;
        }
    }
    
    if (self.proxySettings.pacFileURL) // 是pac 文件
    {
        //检查是否在网络上的pac
        ok =  [self fetchPACFileInfo];
    }
        
    return ok;
}

- (NSMutableDictionary *)getProxyConfigationsInfo
{

    if (self.proxySettings.proxyType == wpProxyNone)
    {
        return nil;
    }
    
    NSString *hostKey = nil;
    NSString *portKey = nil;
    // socket代理设置
    if (self.proxySettings.proxyType == wpProxySockets)
    {
        hostKey = (NSString *)kCFStreamPropertySOCKSProxyHost;
        portKey = (NSString *)kCFStreamPropertySOCKSProxyPort;
    }
    else if (self.proxySettings.proxyType == wpProxyHttps) //https设置
    {
        hostKey = (NSString *)kCFStreamPropertyHTTPSProxyHost;
        portKey = (NSString *)kCFStreamPropertyHTTPSProxyPort;
    }
    else //http
    {
        hostKey = (NSString *)kCFStreamPropertyHTTPProxyHost;
        portKey = (NSString *)kCFStreamPropertyHTTPProxyPort;
    }

    NSMutableDictionary *proxyToUse = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       self.proxySettings.proxyHost,
                                       hostKey,
                                       [NSNumber numberWithInteger:self.proxySettings.proxyPort],
                                       portKey,
                                       nil];

    return proxyToUse;
}

/*
    使用系统网络设置中的代理配置（default）
 */
- (BOOL)checkSystemHadSettingProxy
{
    NSArray *proxies = nil;
#if TARGET_OS_IPHONE
    NSDictionary *proxySetting = [NSMakeCollectable(CFNetworkCopySystemProxySettings()) autorelease];
#else
    NSDictionary *proxySetting = [NSMakeCollectable(SCDynamicStoreCopyProxies(NULL)) autorelease];
#endif
    //如果请求的requrl是https则会找https的代理地址
    proxies = [NSMakeCollectable(CFNetworkCopyProxiesForURL((CFURLRef)self.reqUrl,
                                                            (CFDictionaryRef)proxySetting))
               autorelease];
    
    //如果获取代理设置错误
    if (!proxies) {
        NSString *reason = @"Unable to obtain information on proxy servers needed for request";
        NSError *err = [FQWebError makeFQWebEngineErrorWith:FQWebProxySettingError andReason:reason];
        [self handleFailedAndError:err];
        
        return NO;
    }
    
    if ([proxies count] > 0)
    {
        //重新设置最新的代理
        FQWebProxySettings *osproxy = [[[FQWebProxySettings alloc]init]autorelease];
        self.proxySettings = osproxy;
        
        //如果网络设置使用的是PACURL文件代里的则进行请求
        NSDictionary *settings = [proxies objectAtIndex:0];
        //如果系统的代理配置的是pac文件则直接返回
        if ([settings objectForKey:(NSString *)kCFProxyAutoConfigurationURLKey])
        {
            self.proxySettings.pacFileURL = [settings objectForKey:(NSString *)kCFProxyAutoConfigurationURLKey];
            
            FQWebComponentLog(@"current os proxy config use pac file .url = %@",self.proxySettings.pacFileURL);
        }
        else
        {
            NSString *proxyhost = [settings objectForKey:(NSString *)kCFProxyHostNameKey];
            NSInteger proxyport = [[settings objectForKey:(NSString *)kCFProxyPortNumberKey] intValue];
            NSString *proxytype = [settings objectForKey:(NSString *)kCFProxyTypeKey];
            
            self.proxySettings.proxyHost = proxyhost;
            self.proxySettings.proxyPort = proxyport;
            
            if ([proxytype isEqualToString:(NSString *)kCFProxyTypeNone])
            {
                self.proxySettings.proxyType = wpProxyNone;
            }
            else if ([proxytype isEqualToString:(NSString *)kCFProxyTypeHTTP])
            {
                self.proxySettings.proxyType = wpProxyHttp;
            }
            else if ([proxytype isEqualToString:(NSString *)kCFProxyTypeHTTPS])
            {
                self.proxySettings.proxyType = wpProxyHttps;
            }
            else if ([proxytype isEqualToString:(NSString *)kCFProxyTypeSOCKS])
            {
                self.proxySettings.proxyType = wpProxySockets;
            }
            
            FQWebComponentLog(@"current os proxy config host= %@,port = %ld,type = %@",proxyhost,proxyport,proxytype);
        }
    }
    
    return YES;
}

#pragma mark 对接收数据长度处理
//实始为0
- (void)setZeroToRecevicebytesTotal
{
    recevicebytesTotal = 0;
}

//返回当前总共接收到的总长度
- (unsigned long long)increaseBytesToRecevicebytesTotal:(unsigned long long)bytelength
{
    recevicebytesTotal += bytelength;
    
    return recevicebytesTotal;
}

#pragma mark setter
- (void)setRequestTimeout:(NSTimeInterval)interval
{
    if (interval < MIN_REQUEST_TIMEOUT_MINCSECONDS)
    {
        requestTimeOutInterval = MIN_REQUEST_TIMEOUT_MINCSECONDS;
    }
    else
    {
        requestTimeOutInterval = interval;
    }
}

- (void)setPostData:(NSMutableData *)postBody
{
    self.postBodyData = postBody;
}

- (void)setPostBodyFromFile:(NSString *)filePath
{
    self.postBodyFilePath = filePath;
}


#pragma mark getter
-(NSData *)responseData
{
    // sub class do it.
    DIRECT_CALL_ERROR;
    
    return nil;
}

- (NSString *)responseStrings
{
    // sub class do it.
    DIRECT_CALL_ERROR;
    
    return nil;
}

- (BOOL)isHttpsRequest
{
    return [[[self.reqUrl scheme] lowercaseString] isEqualToString:@"https"];
}

#pragma mark 超时处理
//创建心跳时钟
dispatch_source_t createRequestTimer(uint64_t interval,
                                     uint64_t leeway,
                                     dispatch_queue_t queue,
                                     dispatch_block_t block)
{
    //创建Timer事件源
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                     0, 0, queue);
    if (timer)
    {
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}

//开始
- (void)startRequestTimer:(CFReadStreamRef)sender
{
//    @synchronized(requesttimesourc)
//    {
        [self refreshLastActivityTime];
        //1/4 秒检查一次
        requesttimesourc = createRequestTimer(250ull * NSEC_PER_MSEC,
                                              1ull * NSEC_PER_MSEC,       //精度
                                              timerQueue,
                                              ^{
                                                  [self checkRequestStatus:sender];
                                              });
//    }
}

//停止
- (void)stopRequestTimer
{
//    @synchronized(requesttimesourc)
//    {
        if (requesttimesourc)
        {
            dispatch_release(requesttimesourc);
            requesttimesourc = nil;
        }
//    }
}

//刷新心跳
- (void)refreshLastActivityTime
{
    [lastActivityTime release];
    lastActivityTime = nil;
    lastActivityTime = [[NSDate date]retain];
}

//应该超时？
- (BOOL)shouldTimeOut
{
    int seconds = self.requestTimeOutInterval / 1000;
    //时间差
    NSTimeInterval secondsSinceLastActivity = [[NSDate date] timeIntervalSinceDate:lastActivityTime];
    if (secondsSinceLastActivity > seconds)
    {
        return YES;
    }
    return NO;
}

- (void)shouledRefreshActivityTime
{
    [self refreshLastActivityTime];
}

- (void)checkRequestStatus:(CFReadStreamRef)sender
{
    //用户取消请求
    if (self.isCancelRequest)
    {
        [self stopRequestTimer];
        
        [self doUesrCancelRequestDispatcher];
		return;
	}
    
    //对上传的文件进行进度跟踪
    NSString *postLength = self.requestHeader.contentLength;
    if (postLength)
    {
        unsigned long long postTotalLength = [postLength intValue];
        unsigned long long uploadedlen = [[NSMakeCollectable(CFReadStreamCopyProperty((CFReadStreamRef)sender, kCFStreamPropertyHTTPRequestBytesWrittenCount)) autorelease] unsignedLongLongValue];
        
        //进行通知
        [self sendProgress:postTotalLength withSended:uploadedlen];
        
        //刷新心跳时间
        [self refreshLastActivityTime];
        FQWebComponentLog(@"upload total : %llu, current upload size : %llu",postTotalLength,uploadedlen);
    }
    
    if ([self shouldTimeOut])
    {
        //下载的，可配置重试次数
        NSError *err = [FQWebError makeFQWebEngineErrorWith:FQWebRequestTimeoutError];
        [self handleFailedAndError:err];
    }
}

#pragma mark Cookies
- (void)applyCookies
{
    //如果用户设置了保存cookies
	if ([self autoSaveUseCookies])
    {
        NSString *cookieValue = [[FQWebGlobalCookies globalCookiesManager]makeCookieValueOfHeaderByURL:self.reqUrl];
        if (cookieValue)
        {
            [self.requestHeader setRequestHeader:http_Cookie value:cookieValue];
        }
	}
}

//在发起请求前，应用上一次设置的证书
- (void)applyAuthenticationToCureentRequest:(CFHTTPMessageRef)curRequest
{
    NSString *host = [self.reqUrl host];
    NSInteger port = [[self.reqUrl port]integerValue];
    NSString *protocal = [self.reqUrl scheme];
    NSString *user = nil;
    NSString *pwd = nil;
    BOOL     isProxy = NO;
    CFHTTPAuthenticationRef auth = nil;
    
    FQWebCredentials *credential = [[FQWebAuthenticationManager defaultManager]
                                    fetchCredentialsFromSessionByHost:host
                                    withPort:port
                                    withProtocol:protocal];
    if (credential)
    {
        user = credential.username;
        pwd = credential.password;
        auth = credential.reqAuthentication;
    }
    
    //如果此次请求是从代理找到的，优先级比不上面的高，因此需要先进行代理的认证
    credential = [[FQWebAuthenticationManager defaultManager]fetchProxyCredentialsFromSessionByHost:host withPort:port];
    
    if (credential)
    {
        user = credential.username;
        pwd = credential.password;
        isProxy = YES;
        auth = credential.reqAuthentication;
    }
    
    if (user && pwd && auth)
    {
        NSMutableDictionary *credentials = [NSMutableDictionary dictionary];
        [credentials setObject:user forKey:(NSString *)kCFHTTPAuthenticationUsername];
        [credentials setObject:pwd forKey:(NSString *)kCFHTTPAuthenticationPassword];
        
        BOOL ok = CFHTTPMessageApplyCredentialDictionary(curRequest,auth,(CFMutableDictionaryRef)credentials, nil);
        if (!ok)
        {
            //如果证书无效了则移除之
            if (isProxy)
            {
                [[FQWebAuthenticationManager defaultManager]removeProxyCredentialsFromSession:credential];
            }
            else
            {
                [[FQWebAuthenticationManager defaultManager]removeCredentialsFromSession:credential];
            }
        }
    }
}

/*
 *  储存cookies 这个是相对于mac os有效的不单单是应用
 */
- (void)storeResponseCookies
{
    //如果用户需要保存cookie
    if (self.autoSaveUseCookies)
    {
        //如果头中没有函有cookie则此方法无效
        [[FQWebGlobalCookies globalCookiesManager]storeResponseCookies:self.responseHeader.values forURL:self.reqUrl];
    }
}

#pragma mark 重定向操作
- (void)doRedirect
{
    ++redirectRec;
    if (redirectRec < self.maxRedirectCount)
    {
        NSURL *redirecturl = [[NSURL URLWithString:self.responseHeader.redirectURL
                                       relativeToURL:self.reqUrl]
                              absoluteURL];
        
        NSInteger responseCode = self.responseHeader.statusCode;
        if (responseCode != 307 || responseCode == 303)
        {
            NSString *userAgentHeader   = self.requestHeader.userAgentValue;
            NSString *acceptHeader      = self.requestHeader.acceptValue;
            NSString *connectionHeader  = self.requestHeader.connectionValue;
            NSString *range      = self.requestHeader.range;
            
            [self.requestHeader removeAllRequestHeaders];
            //重定向时只需要保留这两个
            if (userAgentHeader)
            {
                [self.requestHeader setRequestHeader:http_User_Agent value:userAgentHeader];
            }
            if (acceptHeader)
            {
                [self.requestHeader setRequestHeader:http_Accept value:acceptHeader];
            }
            if (connectionHeader) {
                [self.requestHeader setRequestHeader:http_Connection value:connectionHeader];
            }
            if (range) //目的在于支持断点续传
            {
                [self.requestHeader setRequestHeader:http_Range value:range];
            }
            
            [self.requestHeader setRequestHeader:http_Accept_Encoding value:@"gzip,deflate"];
        }

        //将准备重定向到URL
        [self doWillRedirectUrl:redirecturl];
        
        [self setReqUrl:redirecturl];
        //重新发送请求
        [self resendRequest];
    }
    else
    {
        FQWebComponentErrorLog(@"FQWebEngine Error : redirect count too deep.");
    }
}

- (void)resendRequest
{
    [self retain];
    [self cleanMemoryWhileReSendRequest];
    [[self class]attchToSendQueue:self];
    [self release];
}

#pragma mark 处理postbody
//filepath : 全路径文件名
- (BOOL)checkPostFileAvailability:(NSString *)filepath
{
    return [[NSFileManager defaultManager]fileExistsAtPath:filepath];
}

//取得临时文件名(带路径的)，使用当前进程id
- (NSString *)makeTempFilepathName
{
    NSString *uniquestring = [[NSProcessInfo processInfo] globallyUniqueString];
    return [NSTemporaryDirectory() stringByAppendingPathComponent:uniquestring];
}

//删除上传完成(成功或失败)时因压缩产生的临时文件
- (void)removeTemporaryCompressedUploadFile
{
	NSError *err = nil;
	if (self.compressFilePath)
    {
		[[NSFileManager defaultManager] removeItemAtPath:self.compressFilePath error:&err];
	}
    self.compressFilePath = nil;
}

/*
    构造可被http读取的数据流。
    通过NSData 产生。
    通过file产生。
 */
- (NSInputStream *)buildRequestBody
{
    FQULLInteger bodylen = 0;
    NSInputStream *inputStream = nil;
    
    BOOL isPostFile = self.postBodyFilePath.length > 0 ? YES : NO;

    if (self.shouldCompressRequestBody)
    {
        //直接post文件
        if (isPostFile)
        {
            BOOL ok = [self checkPostFileAvailability:self.postBodyFilePath];
            if (!ok) {
                FQWebComponentErrorLog(@"FQWebEngine Error : not found file at path %@",self.postBodyFilePath);
                return nil;
            }
            //压缩的全路径文件名
            NSString *tmpPath = [[self makeTempFilepathName]stringByAppendingString:TEMP_COMPRESS_FILEEXT];
            
            NSError *err = nil;
            //如果压缩文件失败
            if (![FQWebEngineZlibX compressDataFromFile:self.postBodyFilePath toFile:tmpPath error:&err])
            {
                FQWebComponentErrorLog(@"FQWebEngine Error : post file compress failed. %@" ,err);
                return nil;
            }
            
            //保存下这个上传时因压缩产生的文件，目的在于后面上传完成(失败)时进行删除
            self.compressFilePath = tmpPath;
            
            //获取压缩后的文件长度
            bodylen = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.compressFilePath
                                                                                        error:nil]fileSize];
            
            inputStream = [NSInputStream inputStreamWithFileAtPath:self.compressFilePath];
            
        }
        else //post body Data
        {
            //如果设置对body进行压缩
            NSError *err = nil;
            NSData *compressedBody = [FQWebEngineZlibX compressData:self.postBodyData error:&err];
            if (err) {
                [self handleFailedAndError:err];
                return nil;
            }
            
            self.compressPostBodyData = [NSMutableData dataWithData:compressedBody];
            
            bodylen = [self.compressPostBodyData length];
            
            inputStream = [NSInputStream inputStreamWithData:self.compressPostBodyData];
        }
        
        //使用压缩后的数据上传
        [self.requestHeader setRequestHeader:http_Content_Encoding
                                       value:@"gzip"];
    }
    else
    {
        if (isPostFile)
        {
            bodylen = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.postBodyFilePath
                                                                        error:nil]fileSize];
            inputStream = [NSInputStream inputStreamWithFileAtPath:self.postBodyFilePath];
        }
        else
        {
            bodylen = [self.postBodyData length];
            inputStream = [NSInputStream inputStreamWithData:self.postBodyData];
        }
    }
    
    if (bodylen > 0) //通常只有PUT ,POST 会有body
    {
		if ([self.requestMethod isEqualToString:@"GET"] ||
            [self.requestMethod isEqualToString:@"DELETE"] ||
            [self.requestMethod isEqualToString:@"HEAD"])
        {
			requestMethod =@"POST";
		}
        
        [self.requestHeader setRequestHeader:http_Content_Length
                                       value:[NSString stringWithFormat:@"%llu",(unsigned long long)bodylen]];
	}
    
    return  inputStream;
}

#pragma mark 检查项
//检查项
- (BOOL)hasPostBody
{
    return ([self.postBodyData length] > 0 || self.postBodyFilePath.length > 0);
}

#pragma mark 重置
- (void)cleanMemoryWhileReSendRequest
{
    [self stopRequestTimer];
    
    isTimeOut = NO;
    
    if (!self.responseHeader.requestShouldRedirect)
    {   //不是重定向时则需要回归到0初态
        redirectRec = 0;
    }
    else
    {   //只有重定向时，需要重新建立新的请求
        if (self.currentRequestHandle)
        {
            CFRelease(currentRequestHandle);
            self.currentRequestHandle = nil;
        }
    }
    //清空响应头
    [self.responseHeader removeAllResponseHeaders];
}

#pragma mark 回调
- (void)handleFailedAndError:(NSError *)error
{
    @synchronized(self){
        //如果超时及用户取消的，则不再上抛其它错误
        if (isTimeOut || isCancelRequest) {
            return;
        }
  
        [self stopRequestTimer];

        NSInteger errcode = (FQRequestErrorType)[error code];
        switch (errcode)
        {
            case FQWebRequestTimeoutError:
            {
                isTimeOut = YES;
                FQWebComponentLog(@"request [%@] time out.",self.requestID);
            }
                break;
            case FQWebSSLConnectError: //SSL 证书可能过期，或错误这时看是否需要提示用户不验证证书继续访问（可能成功，可能不成功）
            {
                if (self.continueRequestWhenSSLFailed)
                {
                    //忽略证书
                    BOOL willContinue = [self doAskContinueUseUnsafeConnection];
                    if (willContinue)
                    {
                        self.cancelValidatesSecureCertificate = YES;
                        [self resendRequest];
                        return;
                    }
                }
                NSString *description = [error localizedDescription];
                FQWebComponentErrorLog(description,nil);
            }
                break;
            default://不需要上抛的统一打日志方式
            {
                NSString *description = [error localizedDescription];
                FQWebComponentErrorLog(description,nil);
            }
                break;
        }
        
        [self doRequestFailedDispatcher];
    }
}

//http 响应头读取完成
- (void)handleFetchResponsHeaderFinish
{
    [self storeResponseCookies];
    
    //初始化接收数据长度的变量，主要用于进行进度跟踪用
    [self setZeroToRecevicebytesTotal];
    
    [self responseReadHeaderFinish];
}

//网络请求，有数据读取时触发
//此时回来的是原始数据的长度，如果返回的是压缩数据，哪么每部份是压缩数据的一部份
- (void)handleReceiveData:(const void *)bufferBytes length:(NSUInteger)length
{
    [self receviceData:bufferBytes length:length];
    
    //添加每次接收到的长度
    unsigned long long curRecTotalLen = [self increaseBytesToRecevicebytesTotal:length];
    
    //说明返回的有总长度，这个时候可以进行进度显示了
    if (self.responseHeader && self.responseHeader.contentLength > 0)
    {
        unsigned long long totallen = self.responseHeader.contentLength;
        //输出进度
        [self doProgressIndicatorOfTotalSize:totallen withRecevicedSize:curRecTotalLen];
    }
    
    FQWebComponentLog(@"recevice buffer len = %ld ,total length = %llu",length,curRecTotalLen);
}

- (void)doAuthenticationIsProxy:(BOOL)proxyauth
{
    //查看认证是否有效
    CFStreamError err;
    CFHTTPAuthenticationRef authentication = self.responseHeader.authenticationInfo;
    BOOL authenticationValid = CFHTTPAuthenticationIsValid(authentication, &err);
    if (authenticationValid) //证书有效
    {
        //获取认证方式
        //        NSLog(@"AuthenticationScheme = %@",(NSString *)kCFHTTPAuthenticationSchemeNTLM);
        //        NSLog(@"AuthenticationScheme = %@",(NSString *)kCFHTTPAuthenticationSchemeBasic);
        //        NSLog(@"AuthenticationScheme = %@",(NSString *)kCFHTTPAuthenticationSchemeDigest);
        //        NSLog(@"AuthenticationScheme = %@",(NSString *)kCFHTTPAuthenticationSchemeNegotiate);
        //        NSLog(@"AuthenticationScheme = %@",(NSString *)kCFHTTPAuthenticationSchemeNegotiate2);
        //        NSLog(@"AuthenticationScheme = %@",(NSString *)kCFHTTPAuthenticationSchemeXMobileMeAuthToken);
        CFStringRef *scheme = (CFStringRef *)[NSMakeCollectable(CFHTTPAuthenticationCopyMethod(authentication)) autorelease];
        
        CFStringRef *realm = nil;
        NSString    *ntlmDomain = @"";
        //获取认证域
        BOOL hasDomain = CFHTTPAuthenticationRequiresAccountDomain(authentication);
        if (!hasDomain)
        {
            realm = (CFStringRef *)[NSMakeCollectable(CFHTTPAuthenticationCopyRealm(authentication)) autorelease];
        }
        
        BOOL needRequireNameAndPwd = CFHTTPAuthenticationRequiresUserNameAndPassword(authentication);
        
        //询问账号和密码
        if (needRequireNameAndPwd)
        {
            NSString *host = [self.reqUrl host];
            NSInteger port = [[self.reqUrl port]integerValue];
            NSString  *protocol = [self .reqUrl scheme];
            NSString *user = nil;
            NSString *pwd = nil;
            
            FQWebCredentials *hascredentials = nil;

            if (proxyauth)//407代理证书查找
            {
                //先查看代理设置
//                self.proxySettings.proxyUserName;
//                self.proxySettings.proxyPassWord;
//                self.proxySettings.proxyPort;
//                self.proxySettings.proxyHost;
//                self.proxySettings.proxyDomain;
                
                //从session中找
                hascredentials = [[FQWebAuthenticationManager defaultManager]
                                  fetchProxyCredentialsFromSessionByHost:host
                                  withPort:port];
                
                //找不到从key chain中找
                if (!hascredentials)
                {
                    //从keyChain中提取
                    hascredentials = [[FQWebAuthenticationManager defaultManager]
                                      fetchProxyCredentialsFromKeyChainByHost:host
                                      withPort:port
                                      withRealm:(__bridge NSString *)realm];
                }
            }
            else //401 证书查找
            {
                //从session中找
                hascredentials = [[FQWebAuthenticationManager defaultManager]
                                  fetchCredentialsFromSessionByHost:host
                                  withPort:port
                                  withProtocol:protocol];
                
                //找不到从key chain中找
                if (!hascredentials)
                {
                    hascredentials = [[FQWebAuthenticationManager defaultManager]
                                      fetchCredentialsFromKeyChainByHost:host
                                      withPort:port
                                      withProtocol:protocol
                                      withRealm:(__bridge NSString *)realm];
                }
            }
            
            //不在session又不在keyChain中，从delegate找
            if (!hascredentials)
            {
                NSDictionary * dic =nil;
                if (proxyauth)
                {
                    dic = [self doAskProxyAuthenticationDelegate];
                }
                else
                {
                    dic = [self doAskAuthenticationDelegate];
                }
                
                if (dic)
                {
                    //拿到用户名和密码
                    user = [dic objectForKey:FQWebAuthenticationUsername];
                    pwd = [dic objectForKey:FQWebAuthenticationPassword];
                }
            }
            else
            {
                user = hascredentials.username;
                pwd = hascredentials.password;
                ntlmDomain = hascredentials.domain;
            }
            
            //如果用户名，密码都没有，就是认证失败了
            if (!user && !pwd) {
                NSString *emptyUserOrPwd = @"user and password is empty error.";
                NSError *err = [FQWebError makeFQWebEngineErrorWith:FQWebAuthenticationFailedError
                                                          andReason:emptyUserOrPwd];
                [self handleFailedAndError:err];
                return;
            }
            
            //应该认证到当前请求
            NSMutableDictionary *credentials = [NSMutableDictionary dictionary];
            if (user)
            {
                [credentials setObject:user forKey:(NSString *)kCFHTTPAuthenticationUsername];
            }
            
            if (pwd)
            {
                [credentials setObject:pwd forKey:(NSString *)kCFHTTPAuthenticationPassword];
            }
            //如果是NTLM认证需要加上域
            if ([((__bridge NSString *)scheme)isEqualToString:(NSString *)kCFHTTPAuthenticationSchemeNTLM])
            {
                [credentials setObject:ntlmDomain forKey:(NSString *)kCFHTTPAuthenticationAccountDomain];
            }
            
            BOOL ok = CFHTTPMessageApplyCredentialDictionary(self.currentRequestHandle,self.responseHeader.authenticationInfo, (CFMutableDictionaryRef)credentials, &err);
            if (!ok)
            {
                NSError *error =  [FQWebError makeFQWebEngineErrorWith:FQWebCredentialsApplyError];
                [self handleFailedAndError:error];
                
                return;
            }
            else //保存证书到会话，keyChain
            {
                FQWebCredentials *storeCredential = [[[FQWebCredentials alloc]init]autorelease];
                storeCredential.username = user;
                storeCredential.password = pwd;
                storeCredential.host = host;
                storeCredential.port = port;
                storeCredential.protocol = protocol;
                storeCredential.realm = (__bridge NSString *)realm;
                storeCredential.reqAuthentication = self.responseHeader.authenticationInfo;
                
                if (proxyauth) {
                    [[FQWebAuthenticationManager defaultManager]storeProxyCredentialsToSession:storeCredential];
                    [[FQWebAuthenticationManager defaultManager]storeProxyCredentialsToKeyChain:storeCredential];
                }
                else
                {   //存储的时候会提示用户访问keyChain
                    [[FQWebAuthenticationManager defaultManager]storeCredentialsToSession:storeCredential];
//                    [[FQWebAuthenticationManager defaultManager]storeCredentialsToKeyChain:storeCredential];
                }
            }
            
            //重发请求
            [self resendRequest];
            
        }
    }
    else
    {
        // 如果证书无效
        if (err.domain == kCFStreamErrorDomainHTTP &&
            (err.error == kCFStreamErrorHTTPAuthenticationBadUserName ||
             err.error == kCFStreamErrorHTTPAuthenticationBadPassword))
        {
            //先移除缓存存的证书
            
            //从session中查找证书如果找到就重新发起请求，否则需要代理咨询用户
            
            //如果还没有认证，哪就直接结束请求，报错吧。
        }
    }
}

//进行认证证书
- (void)doAuthenticationCredential:(NSInteger)statecode
{
    //当认证大于失败次数
    if (authenticaionNums > AUTHENTICATION_FAIL_COUNTS) {
        NSString *reason = @"authentication count too much.";
        NSError *err = [FQWebError makeFQWebEngineErrorWith:FQWebAuthenticationFailedError
                                                  andReason:reason];
        [self handleFailedAndError:err];
        return;
    }
    
    if (statecode == 401)
    {
        [self doAuthenticationIsProxy:NO];
    }
    else if (statecode == 407)
    {
        //请求的代理服务器需要验证证书
        [self doAuthenticationIsProxy:YES];
    }
}

/*
    请求完成，即所有数据读写都完成了
 */
- (void)handleRequestFinish
{
    //请求完成时先停止超时检测时钟
    [self stopRequestTimer];
    
    if (self.responseHeader.requestShouldRedirect)
    {
        FQWebComponentLog(@"request will do redirect.");
        [self doRedirect];
        return ; //如果重定向时就不响应分发了
    }
    
    NSInteger statecode = self.responseHeader.statusCode;
    
    if (401 == statecode || 407 == statecode)
    {
        //如果做认证了，就要不通知用户请求完成了
        [self doAuthenticationCredential:statecode];
        //每认证一次自增1
        authenticaionNums++;
        return;
    }
    
    //只要有认证成功，认证次数就复位
    authenticaionNums = 0;
    [self doRequestFinishDispatcher];
}

#pragma mark 通知上层调用者
- (void)doUesrCancelRequestDispatcher
{
    [self requestCanceled];
}

- (void)doRequestStartedDispatcher
{
    [self requestStarted];
}

- (void)doRequestFinishDispatcher
{
    [self requestFinish];
}

- (void)doRequestFailedDispatcher
{
    [self requestFailed];
}

- (void)doProgressIndicatorOfTotalSize:(unsigned long long)totalSize
                     withRecevicedSize:(unsigned long long)receviceSize
{
    [self receviceProgress:totalSize withReviced:receviceSize];
}


- (NSDictionary *)doAskAuthenticationDelegate
{
    return [self requestNeedAuthentication];
}

- (NSDictionary *)doAskProxyAuthenticationDelegate
{
    return [self requestNeedProxyAuthentication];
}

- (BOOL)doAskContinueUseUnsafeConnection
{
    return [self requestWhenHadMistrustCertificate];
}

#pragma mark 需要子类实现的
- (NSDictionary *)requestNeedAuthentication
{
    // sub class to do it;
    DIRECT_CALL_ERROR;
    return nil;
}

- (NSDictionary *)requestNeedProxyAuthentication
{
    // sub class to do it;
    DIRECT_CALL_ERROR;
    return nil;
}

- (BOOL)requestWhenHadMistrustCertificate
{
    // sub class to do it;
    DIRECT_CALL_ERROR;
    return NO;
}

- (void)requestCanceled
{
    // sub class to do it;
    DIRECT_CALL_ERROR;
}

- (void)requestStarted
{
    // sub class to do it;
    DIRECT_CALL_ERROR;
}

- (void)requestFailed
{
    // sub class to do it;
    DIRECT_CALL_ERROR;
}

- (void)requestFinish
{
    // sub class to do it;
    DIRECT_CALL_ERROR;
}

- (void)responseReadHeaderFinish
{
    // sub class to do it;
}

- (void)receviceProgress:(FQULLInteger)totalsize withReviced:(FQULLInteger)recevicesize
{
    // sub class to do it;
}

- (void)receviceData:(const void *)bufferBytes length:(NSUInteger)length
{
    // sub class to do it;
}

- (void)sendProgress:(FQULLInteger)totalsize withSended:(FQULLInteger)sendsize
{
    // sub class to do it;
}

- (void)doWillRedirectUrl:(NSURL *)redirectUrl
{
    //sub class to do it;
}

@end;

/**************************************************************************************************
 
                                    FQWebEngine class implementation
 
                    核心引擎，采用GCD进行线程管理，同时对CFNetWork进行封装
 
 **************************************************************************************************/
#pragma mark - FQWebEngine implementation
#define MAX_QUEUE_SIZE            1000

/*
 网络事件回调
 */
static void ReadStreamClientCallBack(CFReadStreamRef readStream, CFStreamEventType event, void *clientRequestContext);

@implementation FQWebEngine


//请求队列
static dispatch_queue_t requestQueue = nil;
static dispatch_queue_t requestSerialQueue = nil;
//防止并发数过多导致系统开销大，可根据处理器数目来优化
static dispatch_semaphore_t semQueue = nil;

static FQWebEngine         *instance = nil;

#pragma mark - 类方法
+ (void)initialize
{
    if (!instance) {
        static dispatch_once_t FQW = 0;
        dispatch_once(&FQW,^{
            instance = [[FQWebEngine alloc]init];
        });
    }
}

+ (FQWebEngine*)shareInstance
{
    return instance;
}

#pragma mark - 初始化
- (id)init
{
    self = [super init];
    if (self) {
        requestQueue = dispatch_queue_create("com.fengsh.webEngine", DISPATCH_QUEUE_CONCURRENT);
        requestSerialQueue = dispatch_queue_create("com.fengsh.webEngine.serial", DISPATCH_QUEUE_SERIAL);
        semQueue = dispatch_semaphore_create(MAX_QUEUE_SIZE);
    }
    return self;
}

- (void)releaseQueue
{
    dispatch_release(requestQueue);
    dispatch_release(semQueue);
    dispatch_release(requestSerialQueue);
}

- (void)dealloc
{
    [self releaseQueue];
    [super dealloc];
}

#pragma mark - 添加请求到线程
//并发
- (void)addRequest:(FQWebRequestAbstract *)request
{
    [self attchToThread:request withQueue:requestQueue];
}

//串行
- (void)addSerialRequest:(FQWebRequestAbstract *)request
{
    [self attchToThread:request withQueue:requestSerialQueue];
}

- (void)attchToThread:(FQWebRequestAbstract *)request withQueue:(dispatch_queue_t)queue
{
    dispatch_semaphore_wait(semQueue, DISPATCH_TIME_FOREVER);
    
    dispatch_block_t ReqBlock = ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
        if (!request.isCancelRequest)
        {
            @try {
                [self sendRequest:request];
            }
            @catch (NSException *exception) {
                NSError *underlyingError = [NSError errorWithDomain:FQWebErrorDomain code:FQUnhandledExceptionError userInfo:[exception userInfo]];
                [request handleFailedAndError:[NSError errorWithDomain:FQWebErrorDomain code:FQUnhandledExceptionError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[exception name],NSLocalizedDescriptionKey,[exception reason],NSLocalizedFailureReasonErrorKey,underlyingError,NSUnderlyingErrorKey,nil]]];
            }
            @finally {
            }
        }
        [pool release];
    };
    
    dispatch_async(queue, ReqBlock);
}

- (void)addGroupRequest:(FQWebRequestAbstractList *)requestlist
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    
    for (id request in requestlist.allRequest)
    {
        if ([request isKindOfClass:[FQWebRequestAbstract class]])
        {
            dispatch_group_async(group, queue, ^{
                [self sendRequest:request];
            });
        }
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [requestlist requestfinsh];
    });
}

/*
 需要保证此方法是线程安全的。
 */
#pragma mark - 发送请求

void closeAndReleaseStream(CFReadStreamRef readStream)
{
    if (readStream) {
        // Clean up
        CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFReadStreamClose(readStream);
        CFRelease(readStream);
        readStream = NULL;
    }
    
    CFRunLoopStop(CFRunLoopGetCurrent());
    FQWebComponentLog(@"Run loop Made Exited.");
}

- (void)sendRequest:(FQWebRequestAbstract *)request
{
    if (!request.reqUrl)
    {
        //抛出错误
        [request handleFailedAndError:[FQWebError makeFQWebEngineErrorWith:FQWebUrlEmptyError]];
        return;
    }
    
    //设置请求URL
    CFStringRef url = (CFStringRef)[request.reqUrl absoluteString];
    CFURLRef requestUrl = CFURLCreateWithString(kCFAllocatorDefault, url, NULL);
    
    
    //如果请头体有问题
    NSInputStream *postbodyStream = nil;
    if ([request hasPostBody])
    {
        postbodyStream = [request buildRequestBody];
        if (!postbodyStream)
        {
            if (requestUrl) {
                CFRelease(requestUrl);
            }
            
            return;
        }
    }
    
    //请求方法
    CFStringRef requestMethod = (CFStringRef)request.requestMethod;

    
    CFHTTPMessageRef httpRequest = nil;
    //如果当前没有发起连接过，重新建立请求
    if (!request.currentRequestHandle)
    {
         httpRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault,
                                                                  requestMethod,
                                                                  requestUrl,
                                                                  request.useHttpVersion10 ? kCFHTTPVersion1_0 : kCFHTTPVersion1_1); //http 1.1
        
        request.currentRequestHandle = httpRequest;
        
    }
    else
    {   //直接使用当前请求即可
        httpRequest = request.currentRequestHandle;
    }
    
    if (requestUrl) {
        CFRelease(requestUrl);
    }
    
    //如果有cookies则添加cookies
    [request applyCookies];
    
    [request.requestHeader reBuildRequestHeader];
    
    //Authorization = "Basic ZldYMjA1NjY0OlRDWCF2ZDla";
    //[request.requestHeader setRequestHeader:@"Authorization" value:@"Basic ZldYMjA1NjY0OlRDWCF2ZDla"];
    FQWebComponentLog(@"Request Headers : %@",request.requestHeader);
    
    NSArray *allkeys = [request.requestHeader.values allKeys];
    for (NSString *item in allkeys)
    {
        CFStringRef headerFieldName = (CFStringRef)item;
        CFStringRef headerFieldValue = (CFStringRef)[request.requestHeader.values objectForKey:item];
        CFHTTPMessageSetHeaderFieldValue(httpRequest, headerFieldName, headerFieldValue);
        CFRelease(headerFieldName);
        //CFRelease(headerFieldValue);
    }
    
    CFReadStreamRef readStream = nil;
    if (postbodyStream)
    {
        readStream = CFReadStreamCreateForStreamedHTTPRequest(kCFAllocatorDefault,
                                                              httpRequest,
                                                              (CFReadStreamRef)postbodyStream);
    }
    else
    {
        //创建请求流
        readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, httpRequest);
    }
    
    //设置keep-live
    if (request.requestHeader.isRequestKeepLive)
    {
        CFReadStreamSetProperty((CFReadStreamRef)readStream,  kCFStreamPropertyHTTPAttemptPersistentConnection, kCFBooleanTrue);
    }
    
    //SSL检测
    if (request.isHttpsRequest)
    {
        //用户自行取消验证安全证书
        if (request.cancelValidatesSecureCertificate)
        {
            NSDictionary *sslProperties = [[NSDictionary alloc] initWithObjectsAndKeys:
                                           [NSNumber numberWithBool:YES], kCFStreamSSLAllowsExpiredCertificates,
                                           [NSNumber numberWithBool:YES], kCFStreamSSLAllowsAnyRoot,
                                           [NSNumber numberWithBool:NO],  kCFStreamSSLValidatesCertificateChain,
                                           kCFNull,kCFStreamSSLPeerName,
                                           nil];
            
            CFReadStreamSetProperty((CFReadStreamRef)readStream,
                                    kCFStreamPropertySSLSettings,
                                    (CFTypeRef)sslProperties);
            [sslProperties release];
        }
    }
    
    //应用证书到请求(只从session中找)
    //主要是第一次401/407时，会把认证存在临时会话，这样以后直接从临时缓存中取就可以了，减少401的质询
    [request applyAuthenticationToCureentRequest:httpRequest];
    
    //使用代理设置，如果有效就配置代理
    BOOL ok = [request checkProxyConfigations];
    if (!ok)
    {
        //如果代理配置有问题，则拒绝请求
        return;
    }
    
    //如果配置没有问题，则取配置信息
    NSMutableDictionary *proxyinfo = [request getProxyConfigationsInfo];
    if (proxyinfo)
    {
        if (request.proxySettings.proxyType == wpProxySockets)
        {
			CFReadStreamSetProperty(readStream, kCFStreamPropertySOCKSProxy, proxyinfo);
		}
        else
        {
			CFReadStreamSetProperty(readStream, kCFStreamPropertyHTTPProxy, proxyinfo);
		}
    }
    
    //因为有可能被复用，所以在dealloc中进行free.
    //CFRelease(httpRequest);
    //httpRequest = nil;
    
    //监听网络事件
    CFOptionFlags registeredEvents = (kCFStreamEventHasBytesAvailable | kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred);
    CFStreamClientContext ctxt = {0, (__bridge void *)(request), NULL, NULL, NULL};
    //监控网络流事件
    if (CFReadStreamSetClient(readStream, registeredEvents, ReadStreamClientCallBack, &ctxt))
    {
        CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    }
    else
    {
        FQWebComponentErrorLog(@"SDK Call Error : %s set callback failed.",__FUNCTION__);
        return;
    }
    
    //准备读流数据
    if (CFReadStreamOpen(readStream) == NO)
    {
        //获取当前流错误信息
        CFErrorRef error = CFReadStreamCopyError(readStream);
        
        if (error != NULL)
        {
            if (CFErrorGetCode(error) != 0)
            {
                NSString *errorInfo = [NSString stringWithFormat:@"SDK Call Error : Failed to \
                                        connect stream [%s]; error '%@' (code %ld)",
                                        __FUNCTION__,
                                        (__bridge NSString*)CFErrorGetDomain(error),
                                        CFErrorGetCode(error)];
                FQWebComponentErrorLog(errorInfo,nil);
            }
            
            CFRelease(error);
        }
        
        return;
    }
    
    [request startRequestTimer:readStream];
    
    //回调给调用者
    [request doRequestStartedDispatcher];

    //启动runloop 等待异步读写操作
    FQWebComponentLog(@"Run loop Made Statr. request %@ sended",request.requestID);
    CFRunLoopRun();
    
    dispatch_semaphore_signal(semQueue);
}

#pragma mark - 响应请求
static void ReadStreamClientCallBack(CFReadStreamRef readStream, CFStreamEventType event, void *clientRequestContext)
{
    FQWebRequestAbstract *clientRequest =(FQWebRequestAbstract*)clientRequestContext;
    //当用户取消或都请求的响应等待超时
    if (clientRequest.isCancelRequest || clientRequest.isTimeOut)
    {
        closeAndReleaseStream(readStream);
        return;
    }
    
    switch(event) {
        case kCFStreamEventHasBytesAvailable:
        {
            handleHasBytesAvailable(readStream,clientRequestContext);
            break;
        }
            
        case kCFStreamEventErrorOccurred:       //流读取事件异常
        {
            handleErrorOccurred(readStream,clientRequestContext);
            break;
        }
            
        case kCFStreamEventEndEncountered:      //流数据读取完成
        {
            handleEndEncountered(readStream,clientRequestContext);
            break;
        }
        default:
            break;
    }
};

void handleHasBytesAvailable(CFReadStreamRef readStream, void *clientRequestContext)
{
    FQWebRequestAbstract *clientRequest =(FQWebRequestAbstract*)clientRequestContext;
    
    [clientRequest shouledRefreshActivityTime];
    
    //未设置响应头时
    if ([clientRequest.responseHeader count]==0)
    {
        //读取HTTP 响应头
        bool fetchOK = fetchResponseHeadersFromStream(readStream,clientRequest);
        //如果http提取完成
        if (fetchOK)
        {
            [clientRequest handleFetchResponsHeaderFinish];
        }
    }
    
    //添加限流操作to here
    
    FQULLInteger clen = clientRequest.responseHeader.contentLength;
    //读取本次流数据
    CFIndex bufferSize = 16384;
    while (CFReadStreamHasBytesAvailable(readStream))
    {
        if (clen > 262144)
        {
            bufferSize = 262144;
        }
        else if (clen > 65536)
        {
            bufferSize = 65536;
        }
        
        UInt8 buffer[bufferSize];
        CFIndex numBytesRead = CFReadStreamRead(readStream, buffer, bufferSize);

        [clientRequest handleReceiveData:buffer length:numBytesRead];
    }
}

void handleEndEncountered(CFReadStreamRef readStream, void *clientRequestContext)
{
    FQWebRequestAbstract *clientRequest =(FQWebRequestAbstract*)clientRequestContext;
    //有可能是没有数据回来，就直接连接完成了，在这里还需要重新检测一次是否已读取了响应头，如果没有，还得再取一次
    if ([clientRequest.responseHeader count]==0)
    {
        //读取HTTP 响应头
        bool fetchOK = fetchResponseHeadersFromStream(readStream,clientRequest);
        //如果http提取完成
        if (fetchOK)
        {
            [clientRequest handleFetchResponsHeaderFinish];
        }
    }
    
    closeAndReleaseStream(readStream);
    
    //成功读取回调
    [clientRequest handleRequestFinish];
}

void handleErrorOccurred(CFReadStreamRef readStream, void *clientRequestContext)
{
    FQWebRequestAbstract *clientRequest =(FQWebRequestAbstract*)clientRequestContext;
    
    CFErrorRef error = CFReadStreamCopyError(readStream);
    NSInteger errcode = 0;
    NSString    *errdomain = nil;
    if (error != NULL) {
        if (CFErrorGetCode(error) != 0) {
            CFStringRef errDomain = CFErrorGetDomain(error);
            errdomain = (__bridge NSString*)errDomain;
            CFStringRef errDescription = CFErrorCopyDescription(error);
            CFStringRef errReason = CFErrorCopyFailureReason(error);
            CFStringRef errSuggestion = CFErrorCopyRecoverySuggestion(error);
            errcode = CFErrorGetCode(error);
            NSString * errorInfo = [NSString stringWithFormat:@"Failed while reading stream;\
error '%@' (code %ld) error description : %@ \n failseason: %@ \n sugestion : %@",
                                    errdomain,
                                    (long)errcode,
                                    (__bridge NSString*)errDescription,
                                    (__bridge NSString*)errReason,
                                    (__bridge NSString*)errSuggestion
                                    ];
            
            CFRelease(errDescription);
            if (errReason) {
                CFRelease(errReason);
            }
            if (errSuggestion) {
                CFRelease(errSuggestion);
            }
            
            FQWebComponentErrorLog(errorInfo,nil);
        }
        
        CFRelease(error);
    }
    
    closeAndReleaseStream(readStream);
    
    NSError *err = nil;
    
    if (errcode <= - 9800 && errcode >= -9818 && [errdomain isEqualToString:NSOSStatusErrorDomain])
    {
        errcode = 0x99; //custom ssl error
    }
    
    switch (errcode) {
        case 2:
            err = [FQWebError makeFQWebEngineErrorWith:FQWebNetWorkConnectError];
            break;
        case 61:
            err = [FQWebError makeFQWebEngineErrorWith:FQWebConnectToServerRefusedError];
            break;
        case 303://可能是POST的方式，被使用了GET进行请求
            {
                NSString *reason = @",please your setting request method.post or get or other.";
                err = [FQWebError makeFQWebEngineErrorWith:FQWebReadDataStreamError andReason:reason];
            }
            break;
        case 0x99:
        {
            err = [FQWebError makeFQWebEngineErrorWith:FQWebSSLConnectError];
        }
            break;
        default:
        {
            //读取过程中异常回调
            err = [FQWebError makeFQWebEngineErrorWith:FQWebReadDataStreamError];
        }
            break;
    }
    if (err)
    {
        [clientRequest handleFailedAndError:err];
    }
}


bool fetchResponseHeadersFromStream(CFReadStreamRef readStream,void *clientRequestContext)
{
    CFHTTPMessageRef message = (CFHTTPMessageRef)CFReadStreamCopyProperty(readStream, kCFStreamPropertyHTTPResponseHeader);
    if (!message) {
        return false;
    }
    
    // 确保所有头域都完成后才读
    if (!CFHTTPMessageIsHeaderComplete(message)) {
        CFRelease(message);
        return false;
    }
    
    FQWebRequestAbstract *clientRequest =(FQWebRequestAbstract*)clientRequestContext;
    
    int statucode = (int)CFHTTPMessageGetResponseStatusCode(message);
    FQWebComponentLog(@"statucode = %d",statucode);
    
    CFStringRef *statuline = (CFStringRef *)[NSMakeCollectable(CFHTTPMessageCopyResponseStatusLine(message)) autorelease];
    NSDictionary *dic = [NSMakeCollectable(CFHTTPMessageCopyAllHeaderFields(message)) autorelease];
    NSString *httpVersion = [NSMakeCollectable(CFHTTPMessageCopyVersion(message)) autorelease];
    [clientRequest.responseHeader removeAllHeaders];
    
    clientRequest.responseHeader.statusCode = statucode;
    [clientRequest.responseHeader setResponseStatuLine:(__bridge NSString*)statuline];
    [clientRequest.responseHeader setResponseHttpVersion:(__bridge NSString *)httpVersion];
    [clientRequest.responseHeader setResponseHeaderByDictionary:dic];
    if (statucode == 401 || statucode == 407)
    {
        //如果响应中需要认证的，读取认证信息
        CFHTTPAuthenticationRef responseAuthentication = (CFHTTPAuthenticationRef)[NSMakeCollectable(CFHTTPAuthenticationCreateFromResponse(NULL, message)) autorelease];

        [clientRequest.responseHeader setAuthenticationInfo:responseAuthentication];
    }
    
    CFRelease(message);
    
    FQWebComponentLog(@"response Header %@",dic);
    return true;
}

@end

