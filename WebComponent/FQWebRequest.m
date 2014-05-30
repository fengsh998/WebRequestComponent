//
//  WebRequest.m
//  FQFrameWork
//
//  Created by fengsh on 13-2-27.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//
//  Copyright (c) 2014年 fengsh998@163.com
//  blog:http://blog.csdn.net/fengsh998
//

#import "FQWebRequest.h"
#import "FQWebEngineDefines.h"
#import "FQWebRequestDelegate.h"
#import "FQWebEngineZlibX.h"

#pragma mark - block
#import "FQWebRequestBlock.h"

#if TARGET_OS_IPHONE
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>
#endif

@interface FQWebRequest()
{
    //响应的流数据原始数据
    NSMutableData           *rawResponseStream;
    NSInteger               tag;
    NSString                *identity;
    BOOL                    allowComplicating;
}

@end

#pragma mark - FQWebRequest class implementation
@implementation FQWebRequest
@synthesize requestID;
@synthesize isCancelRequest;
@synthesize requestMethod;
@synthesize delegate;
@synthesize tag;
@synthesize identity;
@synthesize allowComplicating;
@synthesize reqBlockManager;

#pragma mark - 类方法
+ (id)requestWithURL:(NSString *)url
{
    NSURL *nurl = [NSURL URLWithString:url];
    return [[[self alloc]initWithURL:nurl]autorelease];
}

#pragma mark - 构造方法

- (NSString *)createUUID
{
    // Create universally unique identifier (object)
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    
    // Get the string representation of CFUUID object.
    NSString *uuidStr = [(NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObject) autorelease];
    
    // If needed, here is how to get a representation in bytes, returned as a structure
    // typedef struct {
    //   UInt8 byte0;
    //   UInt8 byte1;
    //   ...
    //   UInt8 byte15;
    // } CFUUIDBytes;
    //CFUUIDBytes bytes = CFUUIDGetUUIDBytes(uuidObject);
    
    CFRelease(uuidObject);
    
    return uuidStr;
}

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self)
    {
        requestID = [[self createUUID]retain];
        [self setReqUrl:url];
        [self setDefaultValue];
        rawResponseStream = [[NSMutableData alloc]init];
        [self setAllowComplicating:YES];
        [self setAutoSaveUseCookies:YES];
    }
    return self;
}

- (void)dealloc
{
    FQWebComponentLog(@"dealloc %@",requestID);
    [requestID release];
    [rawResponseStream release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    FQWebRequest *copy = [[[self class]alloc]initWithURL:self.reqUrl];
    return copy;
}

#pragma mark - 初始默认值设置
- (void)setDefaultValue
{
    isCancelRequest = NO;
    
    [self setRequestTimeout:10000];
}

- (void)go
{
    [[self class]attchToSendQueue:self];
}

- (void)cancelRequest
{
    isCancelRequest = YES;
}

#pragma mark - setter
- (void)setRequestMethod:(RequestMethod) requestmethod
{
    m_requestMethod = requestmethod;
}

- (void)setTag:(NSInteger)itag
{
    tag = itag;
}

- (void)setIdentity:(NSString *)identiter
{
    [identity release];
    identity = nil;
    identity = [identiter retain];
}

- (void)setAllowComplicating:(BOOL)flag
{
    allowComplicating = flag;
}

#pragma mark - getter
- (NSString *)requestMethod
{
    switch (m_requestMethod)
    {
        case requestUsePost:
            return @"POST";
            break;
        case requestUsePut:
            return @"PUT";
            break;
        case requestUseDelete:
            return @"DELETE";
            break;
        case requestUseHead:
            return @"HEAD";
            break;
        case requestUseTrace:
            return @"TRACE";
            break;
        case requestUseConnect:
            return @"CONNECT";
            break;
        case requestUseOptions:
            return @"OPTIONS";
            break;
        default:
            break;
    }
    
    return @"GET";
}


-(NSData *)responseData
{
    //如果回来的是gzip数据，需要解压
    if (self.responseHeader.isResponseCompressed)
    {
        return [FQWebEngineZlibX deCompressData:rawResponseStream error:NULL];
    }
    return rawResponseStream;
}

- (unsigned long)hexToint:(NSString *)hexString
{
    return strtoul([hexString UTF8String],0,16);
}

- (NSString *)responseStrings
{
    NSData *data = [self responseData];
    
    NSString *respString = nil;
    
    NSString *transfercoding = [self.responseHeader.transferEncoding lowercaseString];
    
    if ([transfercoding isEqualToString:@"identity"])
    {
        //还得看content-type中是否有charset
        unsigned long encode = NSUTF8StringEncoding;
        NSRange rg = [self.responseHeader.contentType rangeOfString:@"charset"];
        if (rg.location != NSNotFound)
        {
            encode = self.responseHeader.responseEncoding;
        }
        
        respString = [[[NSString alloc] initWithBytes:[data bytes]
                                               length:[data length]
                                             encoding:encode]autorelease];
    }
    else if ([transfercoding isEqualToString:@"chunked"])
    {
        //[self hexToint];未找到样例解释。暂缓
        FQWebComponentErrorLog(@"FQWebEngine not implementation chunked decoding.");
    }
    else
    {
        respString = [[[NSString alloc] initWithBytes:[data bytes]
                                               length:[data length]
                                             encoding:self.responseHeader.responseEncoding]
                      autorelease];
    }
    
    
    if (data.length > 0 && !respString)
    {
        //解编码失败了
        FQWebComponentErrorLog(@"FQWebEngine Error : Unsupport data format.");
    }
    
    return respString;
}

- (void)doWillRedirectUrl:(NSURL *)redirectUrl
{
    //清空接收的流数据
    [rawResponseStream setLength:0];
}

- (void)cleanMemoryWhileReSendRequest
{
    [rawResponseStream setLength:0];
    [super cleanMemoryWhileReSendRequest];
}

#pragma mark - 接收响应流

- (void)receviceData:(const void *)bufferBytes length:(NSUInteger)length
{
    [rawResponseStream appendBytes:bufferBytes length:length];
}

- (void)requestCanceled
{
    FQWebComponentLog(@"user cancel");
    //用户取消也算是失败请求的一种
    [self requestFailed];
}

- (NSDictionary *)requestNeedAuthentication
{
    //需要等待用户输入
    __block NSDictionary *authdic = nil;
    if ([delegate respondsToSelector:@selector(authenticationNeededForRequest:)])
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            authdic = [[delegate authenticationNeededForRequest:self]mutableCopy];
        });
    }
    
    //block的方式回调
    if(reqBlockManager && reqBlockManager.authenticationNeededBlock){
        dispatch_sync(dispatch_get_main_queue(), ^{
            authdic = [reqBlockManager.authenticationNeededBlock(self)mutableCopy];
        });
	}

    return [authdic autorelease];
}

- (NSDictionary *)requestNeedProxyAuthentication
{
    __block NSDictionary *authdic = nil;
    if ([delegate respondsToSelector:@selector(proxyAuthenticationNeededForRequest:)])
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            authdic = [[delegate proxyAuthenticationNeededForRequest:self]mutableCopy];
        });
    }
    
    //block方式回调
    if (reqBlockManager && reqBlockManager.proxyAuthenticationNeededBlock) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            authdic = [reqBlockManager.proxyAuthenticationNeededBlock(self)mutableCopy];
        });
    }
    
    return [authdic autorelease];
}

- (BOOL)requestWhenHadMistrustCertificate
{
    __block BOOL willcontinue = NO;
    if ([delegate respondsToSelector:@selector(isContinueWhenUnsafeConnectInCureentRequest:)])
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            willcontinue = [delegate isContinueWhenUnsafeConnectInCureentRequest:self];
        });
    }
    
    //block方式回调
    if (reqBlockManager && reqBlockManager.isContinueWhenUnsafeConnectBlock) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            willcontinue = reqBlockManager.isContinueWhenUnsafeConnectBlock(self);
        });
    }
    
    return willcontinue;
}

- (void)requestStarted
{
    if ([delegate respondsToSelector:@selector(requestStarted:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate requestStarted:self];
        });
    }
    
    //block方式回调
    if (reqBlockManager && reqBlockManager.startedBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            reqBlockManager.startedBlock(self);
        });
    }
}

- (void)requestFailed
{
    if ([delegate respondsToSelector:@selector(requestFailed:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate requestFailed:self];
        });
    }
    
    //block方式回调
    if (reqBlockManager && reqBlockManager.failedBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            reqBlockManager.failedBlock(self);
        });
    }
}

- (void)requestFinish
{
    if ([delegate respondsToSelector:@selector(requestFinished:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate requestFinished:self];
        });
    }
    
    //block方式回调
    if (reqBlockManager && reqBlockManager.finishedBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            reqBlockManager.finishedBlock(self);
        });
    }
}

- (void)receviceProgress:(FQULLInteger)totalsize withReviced:(FQULLInteger)recevicesize
{
    if ([delegate respondsToSelector:@selector(requestReceviceProgress:withTotalSize:withRecvicedSize:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate requestReceviceProgress:self withTotalSize:totalsize withRecvicedSize:recevicesize];
        });
    }
}

- (void)sendProgress:(FQULLInteger)totalsize withSended:(FQULLInteger)sendsize
{
    if ([delegate respondsToSelector:@selector(requestSendProgress:withTotalSize:withSendSize:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate requestSendProgress:self withTotalSize:totalsize withSendSize:sendsize];
        });
    }
}


@end

/**************************************************************************************************
 
                                FQWebGroupRequest implementation
 
 **************************************************************************************************/
@interface FQWebGroupRequest()
{
    FQWebRequestList                *reqlist;
}
@end

@implementation FQWebGroupRequest
@synthesize delegate;
@synthesize finishBlock;

- (id)init
{
    self = [super init];
    if (self) {
        reqlist = [[FQWebRequestList alloc]init];
    }
    return self;
}

- (void)dealloc
{
    [reqlist release];
    [super dealloc];
}

- (void)addRequest:(FQWebRequest *)request
{
    [reqlist addObject:request];
}

- (void)cleanAllsRequest
{
    [self cancel];
    
    [reqlist removeAllObjects];
}

- (NSArray *)allRequest
{
    return [NSArray arrayWithArray:reqlist];
}


- (void)start
{
    [[FQWebEngine shareInstance]addGroupRequest:self];
}

- (void)cancel
{
    for (FQWebRequest *item in reqlist)
    {
        [item cancelRequest];
    }
}

- (void)requestfinsh
{
    if ([delegate respondsToSelector:@selector(allRequestFinish:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate allRequestFinish:self];
        });
    }
    
    //block方式
    if (finishBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            finishBlock(self);
        });
    }
}

@end

/**************************************************************************************************
 
                            FQDownLoadRequest implementation
 
 **************************************************************************************************/
#define TEMP_DOWNLOAD_FILEEXT       @".FQDownload"
@interface FQDownLoadRequest ()
{
    NSOutputStream *outputstram;

    NSString        *fileFullPath;
    
    NSString        *currentBreakpointFile;
    BOOL            isBreakpointResume;
    FQULLInteger    breakpointFilesize;
    FQULLInteger    originalFileTotalSize;
}

/*
    保存文件的路径全名（路径+文件名）
    这个值来自三种情况：
    1.直接请求的URL中提取。
    2.从URL响应的302中的location中提取
    3.从响应头消息的content-disiposition中提取
 */
@property (nonatomic,retain) NSString        *fileFullPath;
/*
    本次请求的断点文件，不带路径
 */
@property (nonatomic,retain) NSString        *currentBreakpointFile;
/*
    本次请求是否需要断点续传
 */
@property (nonatomic,assign) BOOL            isBreakpointResume;
/*
    本次请求读取的断点文件大小
 */
@property (nonatomic,assign) FQULLInteger    breakpointFilesize;
/*
    断点下载时，当返回206时进行提取原始文件的总大小用于计算进度
 */
@property (nonatomic,assign) FQULLInteger    originalFileTotalSize;

@end

#pragma mark - FQDownLoadRequest class implementation
@implementation FQDownLoadRequest
@synthesize folderpath;
@synthesize supportBreakpointsResume;
@synthesize fileFullPath;
@synthesize useCustomSaveFileName;
@synthesize currentBreakpointFile;
@synthesize isBreakpointResume;
@synthesize breakpointFilesize;
@synthesize originalFileTotalSize;

#pragma mark - 初始化
+ (FQDownLoadRequest *)downloadWithURL:(NSString *)url
{
    NSURL *nurl = [NSURL URLWithString:url];
    return [[[self alloc]initWithURL:nurl]autorelease];
}

- (id)initWithURL:(NSURL *)url
{
    self = [super initWithURL:url];
    if (self) {
        [self setRequestMethod:requestUseGet];
        self.isBreakpointResume = NO;
        self.originalFileTotalSize = 0;
        self.breakpointFilesize = 0;
    }
    return self;
}

- (void)closeAndFreeOutPutStream
{
    if (outputstram)
    {
        [outputstram close];
        [outputstram release];
        outputstram = nil;
    }
}

- (void)dealloc
{
    [self closeAndFreeOutPutStream];
    [useCustomSaveFileName release];
    [fileFullPath release];
    [currentBreakpointFile release];
    [super dealloc];
}

#pragma mark - 路径处理函数
/*
    获取保存的名件名
    如果返回的头域中没有说明，则需要在请求的URL中提取
 */
- (NSString *)getSaveFileNameByURL:(NSURL *)requrl
{
    NSString *filename = [requrl lastPathComponent];
    //其它场影需要考虑补充
    return filename;
}

//当重新设定路径名时，先删除无用的文件，再建
- (void)cleanFileFullPathWhenReset:(NSString *)newPathFile
{
    //有使用断点文件
    if (self.currentBreakpointFile.length > 0)
    {
        self.fileFullPath = [self.folderpath stringByAppendingPathComponent:self.currentBreakpointFile];
        return;
    }
    
    //先清空可能从URL中提取到的杂质文件名
    [[NSFileManager defaultManager] removeItemAtPath:self.fileFullPath error:nil];
    
    //如果用户定义，则使用用户定义的
    if (self.useCustomSaveFileName)
    {
        NSString *pathfile = [self.folderpath stringByAppendingPathComponent:self.useCustomSaveFileName];
        self.fileFullPath = [pathfile stringByAppendingString:TEMP_DOWNLOAD_FILEEXT];
    }
    else
    {
        self.fileFullPath = newPathFile;
    }
}
//检测当前下载路径是否OK,不OK创建
- (BOOL)checkAndCreateDir;
{
    if (self.folderpath.length == 0)
    {
        FQWebComponentErrorLog(@"FQDownload Error : please to settings save folderpath.");
        return NO;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL isDir = FALSE;
    BOOL isDirExist = [fileManager fileExistsAtPath:self.folderpath
                                        isDirectory:&isDir];
    
    
    if(!(isDirExist && isDir))
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:self.folderpath
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:nil];
        if(!bCreateDir)
        {
            
            FQWebComponentErrorLog(@"FQDownloadRequest Error : create download folder path failed. path at : %@",self.folderpath);
        }
        
        return bCreateDir;
    }
    
    return isDirExist && isDir;
}

// 创建存储的全路径文件名
- (NSString *)makeStoreFileFullPathByURL:(NSURL *)url
{
    NSString *fileName = [self getSaveFileNameByURL:url];
    NSString *filepath = [self.folderpath stringByAppendingPathComponent:fileName];
    return [filepath stringByAppendingString:TEMP_DOWNLOAD_FILEEXT];
}

#pragma mark - setter

//设置存储路径
- (void)setDownloadStorePath:(NSString *)folderPath
{
    [folderpath release];
    folderpath = nil;
    folderpath = [folderPath retain];
}

- (void)setReDownloadFile:(NSString *)redownloadfile useResume:(BOOL)resume
{
    if (redownloadfile.length == 0) {
        FQWebComponentErrorLog(@"FQDownload Error : download file set error.");
        return;
    }
    
    if ([redownloadfile hasSuffix:TEMP_DOWNLOAD_FILEEXT])
    {
        self.currentBreakpointFile = redownloadfile;
    }
    else
    {
        self.currentBreakpointFile = [redownloadfile stringByAppendingString:TEMP_DOWNLOAD_FILEEXT];
    }
    
    self.isBreakpointResume = resume;
}



- (void)go
{
    //创建下载保存路径
    BOOL ok = [self checkAndCreateDir];
    
    if (!ok) {
        return;
    }
    
    //1.直接请求的URL中提取。
    NSString *pathfile = [self makeStoreFileFullPathByURL:self.reqUrl];
    [self cleanFileFullPathWhenReset:pathfile];


    //检测断点数据
    if (self.isBreakpointResume)
    {
        [self checkBreakPointsData];
    }
    
    [super go];
}

/*
    这里使用者必段注意的一个地方，当有多个断点文件时，如果使用setReDownloadFile设置了一个断点文件，
    但这个断点文件与此时请求的URL所下的文件不是同一文件时就可能把原来的断点文件给毁坏了。
    这里并没有对文件进行校验所以调用者需要小心。
 */
- (BOOL)checkBreakPointsData
{
    BOOL ok = [[NSFileManager defaultManager] fileExistsAtPath:self.fileFullPath];
    if (ok)
    {
        //得到当前断点文件已下载数据的大小
		NSError *err = nil;
		self.breakpointFilesize = [[[NSFileManager defaultManager]
                                           attributesOfItemAtPath:self.fileFullPath
                                                            error:&err]
                                          fileSize];
		if (err)
        {
			FQWebComponentErrorLog(@"FQDownload Error : %@",[NSString stringWithFormat:@"Failed to get attributes for file at path '%@'",self.fileFullPath]);
            return NO;
		}
        
        //清加断点续传请求
        [self.requestHeader setRequestHeader:http_Range value:[NSString stringWithFormat:@"bytes=%llu-",self.breakpointFilesize]];
    }
    else
    {   //不存在该断点文件，则忽略此文件
        self.currentBreakpointFile = nil;
        self.isBreakpointResume = NO;
    }
    
    return YES;
}

#pragma mark - 回调
- (void)doWillRedirectUrl:(NSURL *)redirectUrl
{
    //重定向时先清了原来的流变量
    [self closeAndFreeOutPutStream];
    //重新获取要保存文件的文件名
    //2.从URL响应的302中的location中提取（多重重定向也不担心，最终都是在loaction中带有）
    //这时会自动复盖情况1的文件路径名
    NSString *pathfile = [self makeStoreFileFullPathByURL:redirectUrl];
    [self cleanFileFullPathWhenReset:pathfile];
    
    [super doWillRedirectUrl:redirectUrl];
}

- (void)cleanMemoryWhileReSendRequest
{
    [super cleanMemoryWhileReSendRequest];
}

- (void)responseReadHeaderFinish
{
    //206时表示断点续传，重新组织百分比提取原文件的总大小
    if (self.responseHeader.statusCode == 206)
    {
        NSString *rangvalue = self.responseHeader.contentRange;
        NSRange rg = [rangvalue rangeOfString:@"/"];
        if (rg.location != NSNotFound)
        {
            NSString *totalstring = [rangvalue substringFromIndex:NSMaxRange(rg)];
            self.OriginalFileTotalSize = [totalstring intValue];
        }
    }
    //如果用户指定了文件名，则不再提取加快执行效率，省得再走一次提取流程
    //别外如果此次是断点续传说明文件名也存在了，就没有再提取的必要了
    if (self.useCustomSaveFileName || self.isBreakpointResume)
    {
        return;
    }
    
    //开始提取文件名
    NSString *disposition = self.responseHeader.contentDisposition;
    NSString *filename = nil;
    if (disposition)
    {
        NSRange range = [disposition rangeOfString:@"filename="];
        //找到文件名
        if (range.location != NSNotFound)
        {
            filename = [disposition substringFromIndex:NSMaxRange(range)];
            //有可能filename两边带引号
            filename = [filename stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        }
    }
    
    //找到文件名
    if (filename)
    {
        //这里需要对文件名进行解码，有可能是urlencode也有可能是base64,可能是iso标准，也可能是filename*=
        //慢慢补上吧
        //3.从响应头消息的content-disiposition中提取 会忽略1，2情况
        NSString *filepath = [self.folderpath stringByAppendingPathComponent:filename];
        filepath = [filepath stringByAppendingString:TEMP_DOWNLOAD_FILEEXT];
        [self cleanFileFullPathWhenReset:filepath];
    }
}

//写的是原始数据
- (void)receviceData:(const void *)bufferBytes length:(NSUInteger)length
{
    if (!outputstram)
    {
        outputstram = [[NSOutputStream alloc] initToFileAtPath:self.fileFullPath
                                                        append:YES];
        [outputstram open];
    }
    
    //写到文件
    [outputstram write:bufferBytes maxLength:length];
}

//进度精度处理
- (void)receviceProgress:(FQULLInteger)totalsize withReviced:(FQULLInteger)recevicesize
{
    if ([self.delegate respondsToSelector:@selector(downloadProgress:withTotalSize:withRecvicedSize:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (self.responseHeader.statusCode == 206)
            {
                [self.delegate downloadProgress:self
                                  withTotalSize:self.originalFileTotalSize
                               withRecvicedSize:self.breakpointFilesize + recevicesize];
            }
            else
            {
                [self.delegate downloadProgress:self
                                  withTotalSize:totalsize
                               withRecvicedSize:recevicesize];
            }
        });
    }
    
    //block 方式回调
    if (self.reqBlockManager && self.reqBlockManager.downLoadProgressBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.responseHeader.statusCode == 206)
            {
                self.reqBlockManager.downLoadProgressBlock(self,self.originalFileTotalSize,self.breakpointFilesize + recevicesize);
            }
            else
            {
                self.reqBlockManager.downLoadProgressBlock(self,totalsize,recevicesize);
            }
        });
    }
}

- (void)requestCanceled
{
    //用户取消时，则需要关闭流
    [self closeAndFreeOutPutStream];
    
    [super requestCanceled];
}

- (void)requestFailed
{
    //失败时也需要关闭流
    [self closeAndFreeOutPutStream];
    
    [super requestFailed];
}

- (void)requestFinish
{
    // 下载完成了，判断是否有压缩编码的，需要解压
    //目标文件路径
    NSString *suffix = TEMP_DOWNLOAD_FILEEXT;
    NSInteger idx = (self.fileFullPath.length - suffix.length);
    NSString *destFilePath = [self.fileFullPath substringToIndex:idx];
    
    if (self.responseHeader.isResponseCompressed)
    {
        
        [FQWebEngineZlibX deCompressDataFromFile:self.fileFullPath
                                          toFile:destFilePath
                                           error:nil];
    }
    else
    {
        //重命名
        [[NSFileManager defaultManager] moveItemAtPath:self.fileFullPath
                                                toPath:destFilePath error:nil];
    }
    //最后通知用户下载完成了
    [super requestFinish];
}

@end

/**************************************************************************************************
 
                                   FQUploadRequest 实现
 
 **************************************************************************************************/
@implementation FQUploadRequest

+ (FQUploadRequest *)uploadWithUrl:(NSString *)url
{
    NSURL *nurl = [NSURL URLWithString:url];
    return [[[self alloc]initWithURL:nurl]autorelease];
}

- (id)initWithURL:(NSURL *)url
{
    self = [super initWithURL:url];
    if (self) {
        [self setRequestMethod:requestUsePost];//默认为Post
    }
    return self;
}


- (void)setUploadFile:(NSString *)filepath
{
    [self setPostBodyFromFile:filepath];
}

- (void)setuploadFormData:(FormDataPackage *)formdata
{
    NSData *postdata = nil;
    switch (formdata.postBodyType) {
        case postformMultipartData: //Mime
        {
            postdata = [formdata buildMultipartFormDataPostBody];
        }
            break;
        case postformURLEncoded:
        {
            postdata = [formdata buildURLEncodedPostBody];
        }
            break;
        default:
            FQWebComponentWarnLog(@"FQUpload Warining : current version post type unsupport.");
            break;
    }
    
    //注意只有在build后才会有这个值
    NSString *ctype = formdata.contentTypeValue;
    
    if (ctype)
    {
        [self.requestHeader setRequestHeader:http_Content_Type value:ctype];
    }
    
    if (postdata)
    {
        [self setPostData:(NSMutableData*)postdata];
    }
}

- (void)sendProgress:(FQULLInteger)totalsize withSended:(FQULLInteger)sendsize
{
    if ([self.delegate respondsToSelector:@selector(uploadProgress:withTotalSize:withUploadsize:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadProgress:self withTotalSize:totalsize withUploadsize:sendsize];
        });
    }
    
    //block
    if (self.reqBlockManager && self.reqBlockManager.uploadProgressBlock)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.reqBlockManager.uploadProgressBlock(self,totalsize,sendsize);
        });
    }
}

@end;

/**************************************************************************************************
 
                            mulit form part MIME分段部分
 
 **************************************************************************************************/

#pragma mark - MimePart class implementation
@implementation MimePart
@synthesize bodystring;
@synthesize bodyFileData;

- (id)init
{
    self = [super init];
    if (self) {
        headers = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (void)dealloc
{
    [bodystring release];
    [bodyFileData release];
    [headers release];
    [super dealloc];
}

- (void)setHeaders:(NSMutableDictionary *)hders
{
    [headers release];
    headers = nil;
    headers = [hders retain];
}

- (void)addMimeHeader:(NSString *)name withValue:(id<NSObject>)value
{
    [headers setObject:value forKey:name];
}

- (id)getHeaderValueByName:(NSString *)name
{
    return [headers objectForKey:name];
}

- (NSDictionary *)allHeaders
{
    return headers;
}

- (NSString *)description
{
    NSString *datastring = [[[NSString alloc] initWithData:self.bodyFileData
                                                  encoding:NSUTF8StringEncoding]
                            autorelease];
    if (!datastring && self.bodyFileData.length > 0) {
        datastring = [NSString stringWithFormat:@"size : %lu description : %@",
                      (unsigned long)self.bodyFileData.length
                      ,@"(has data)"];//因为self.bodyFileData.description太大了，所以省略输出
    }
    else
    {
        datastring = nil;
    }
    
    return [NSString stringWithFormat:@"{MimePart description : MimeHeaders %@; bodystring = %@ ; bodyFileData = %@}",
            headers,self.bodystring, datastring];
}

- (id)copyWithZone:(NSZone *)zone
{
    MimePart *copy  = [[self class]copyWithZone:zone];
    copy.bodystring = self.bodystring;
    copy.bodyFileData = [[self.bodyFileData mutableCopy]autorelease];
    NSMutableDictionary *cp = [[self->headers mutableCopy]autorelease];
    [copy setHeaders:cp];
    return copy;
}

@end

/***************************************************************************************************
 
                                FormDataPackage  class implemention
 
***************************************************************************************************/

#define postkey     @"key"
#define postvalue   @"value"

@interface FormDataPackage()
{
    NSMutableArray          *bodyData;
    NSMutableArray          *mimeparts;
    NSMutableString         *priviews;
}

@property (nonatomic,retain) NSMutableArray   *bodyData;
@property (nonatomic,retain) NSMutableArray   *mimeparts;
@property (nonatomic,retain) NSMutableString  *priviews;

+ (NSString *)getEncodingNameByCodingkey:(NSStringEncoding)cdkey;

- (NSString*)encodeURL:(NSString *)string encoding:(NSStringEncoding)coding;
- (NSString*)decodeURL:(NSString *)encodeurlstring encoding:(NSStringEncoding)coding;

@end


#pragma mark - FormDataPackage class implementation
@implementation FormDataPackage
@synthesize bodyStringEncoding;
@synthesize postBodyType;
@synthesize contentTypeValue;
@synthesize bodyData;
@synthesize mimeparts;
@synthesize priviews;
@synthesize needMakePreviewstaring;

+ (NSString *)getEncodingNameByCodingkey:(NSStringEncoding)cdkey
{
    NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(
                        CFStringConvertNSStringEncodingToEncoding(cdkey));
    return charset;
}

// for ios 使用
#if TARGET_OS_IPHONE
+ (NSString *)mimeTypeForFileAtPath:(NSString *)path
{
	if (![[[[NSFileManager alloc] init] autorelease] fileExistsAtPath:path]) {
		return nil;
	}
	//use mobileCoreServices.framework
	CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)[path pathExtension], NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
	if (!MIMEType)
    {
		return @"application/octet-stream";
	}
    return [NSMakeCollectable(MIMEType) autorelease];
}
#endif

+ (NSMutableData *)fileCovertToStringStream:(NSString *)filepath
{
    NSMutableData *filedata = [NSMutableData data];
    
    NSInputStream *stream = [[[NSInputStream alloc] initWithFileAtPath:filepath] autorelease];
	[stream open];
	NSUInteger bytesRead = 0;
	while ([stream hasBytesAvailable])
    {
		unsigned char buffer[1024*256];
		bytesRead = [stream read:buffer maxLength:sizeof(buffer)];
        
		if (bytesRead == 0)
        {
			break;
		}

        [filedata appendData:[NSData dataWithBytes:buffer length:bytesRead]];

	}
	[stream close];
    
    return filedata.length > 0 ? filedata : nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        //设置默认值
        [self setBodyStringEncoding:NSUTF8StringEncoding];
        [self setPostBodyType:postformURLEncoded];
        needMakePreviewstaring = NO;
    }
    return self;
}

- (void)dealloc
{
    [contentTypeValue release];
    [mimeparts release];
    [bodyData release];
    [priviews release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    FormDataPackage *copy       = [[self class]copyWithZone:zone];
    copy.bodyStringEncoding     = self.bodyStringEncoding;
    copy.postBodyType           = self.postBodyType;
    copy.needMakePreviewstaring = self.needMakePreviewstaring;
    copy.bodyData               = [[self.bodyData mutableCopy]autorelease];
    copy.mimeparts              = [[self.mimeparts mutableCopy]autorelease];
    copy.priviews               = self.priviews;
    return copy;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{FormDataPackage description : \npostBodyType = %d\n\
contentTypeValue = %@\nmimeparts = %@\nbodyData = %@}"
            ,postBodyType,contentTypeValue,mimeparts,self.bodyData];
}

/*
    如:
    NSString *ed = [a encodeURL:@"http://haoxiang.org/2010/10/url编码和字符转义/" encoding:NSUTF8StringEncoding];
    NSLog(@"printf : %@",ed);
    NSString *decoded = [a decodeURL:ed encoding:NSUTF8StringEncoding];
    NSLog(@"printf : A = %@",decoded);
 */
- (NSString*)encodeURL:(NSString *)string encoding:(NSStringEncoding)coding
{
    NSString *newString = [NSMakeCollectable(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                          (CFStringRef)string,NULL,CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"),
                          CFStringConvertNSStringEncodingToEncoding(coding)))
                           autorelease];
    
	return newString ? newString : @"";
}

- (NSString*)decodeURL:(NSString *)encodeurlstring encoding:(NSStringEncoding)coding
{
    NSString *decodestring = [NSMakeCollectable(CFURLCreateStringByReplacingPercentEscapesUsingEncoding
                                        (kCFAllocatorDefault, (CFStringRef)encodeurlstring, CFSTR("")
                                         ,CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)
                                         ))
                              autorelease];
    
    return decodestring ? decodestring : @"";
}

//在使用时才创建减少内存申请的开销
- (void)createbodyWhenfirstUsebody
{
    if (!self.bodyData)
    {
        self.bodyData = [NSMutableArray array];
    }
}

- (void)createMultipartsWhenfirstUsebody
{
    if (!self.mimeparts)
    {
        self.mimeparts = [NSMutableArray array];
    }
}

// 添加一个值到body
- (void)addPostValue:(id <NSObject>)value forKey:(NSString *)key
{
    if (value && key)
    {
        [self createbodyWhenfirstUsebody];
        
        NSMutableDictionary *keyValuePair = [NSMutableDictionary dictionaryWithCapacity:2];
        [keyValuePair setValue:key forKey:postkey];
        [keyValuePair setValue:[value description] forKey:postvalue];
        
        [self.bodyData addObject:keyValuePair];
    }
}

// 设置一个值到body,如果body原来的变量值存在，则被替换为新的值
- (void)setPostValue:(id <NSObject>)value forKey:(NSString *)key
{
    if (value && key)
    {
        [self createbodyWhenfirstUsebody];
        
        for (NSDictionary *item in self.bodyData)
        {
            if ([[item objectForKey:postkey] isEqualToString:key])
            {
                [item setValue:value forKey:postvalue];
            }
        }
    }
}

- (void)setContentTypeValue:(NSString *)value
{
    [contentTypeValue release];
    contentTypeValue = nil;
    contentTypeValue = [value retain];
}

- (void)addMultiPart:(MimePart *)part
{
    [self createMultipartsWhenfirstUsebody];
    
    [self.mimeparts addObject:part];
}

- (NSData *)buildURLEncodedPostBody
{
    //重置预览数据为空
    [self cleanPreview];
    
    NSString *charset = [[self class]getEncodingNameByCodingkey:self.bodyStringEncoding];
    NSString *contenttypevalue = [NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@",charset];
    //设置Content-Type的值
    [self setContentTypeValue:contenttypevalue];
    
    NSString *datastring = nil;
    for (NSDictionary *item in bodyData)
    {
        NSString *key = [self encodeURL:[item objectForKey:postkey] encoding:self.bodyStringEncoding];
        NSString *value = [self encodeURL:[item objectForKey:postvalue] encoding:self.bodyStringEncoding];
        
        datastring = [NSString stringWithFormat:@"%@=%@&",
                          key,
                          value];
    }
    //去除最后一个&符号
    if (datastring) {
        datastring = [datastring substringToIndex:[datastring length] - 1];
    }
    
    [self appenStringToPreview:datastring];
    NSData *retData = [datastring dataUsingEncoding:self.bodyStringEncoding];
    return retData;
}

- (void)cleanPreview
{
    self.priviews = nil;
}

- (void)appenStringToPreview:(NSString *)previewstring
{
    if (needMakePreviewstaring)
    {
        if (!priviews) {
            self.priviews = [NSMutableString string];
        }
        
        if (previewstring)
        {
            [self.priviews appendString:previewstring];
        }
    }
}

- (NSData *)buildMultipartFormDataPostBody
{
    //重置预览数据为空
    [self cleanPreview];
    
    if ([self.mimeparts count] > 0)
    {
        //构造分段分隔线
        CFUUIDRef uuid = CFUUIDCreate(nil);
        NSString *uuidString = [(NSString*)CFUUIDCreateString(nil, uuid) autorelease];
        CFRelease(uuid);
        uuidString = [uuidString substringToIndex:16];
        uuidString = [uuidString stringByReplacingOccurrencesOfString:@"-" withString:@""];
        NSString *stringBoundary = [NSString stringWithFormat:@"FqWebEngineFormBoundary-%@",uuidString];
        
        //添加首行分隔
        NSString *startBoundary = [NSString stringWithFormat:@"--%@\r\n",stringBoundary];
        //中间部分段落分隔
        NSString *partItemBoundary = [NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary];
        //结束分隔
        NSString *endBoundary = [NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary];
        
        //构造头域说明
        NSString *charset = [[self class]getEncodingNameByCodingkey:self.bodyStringEncoding];
        NSString *contenttypevalue = [NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@", charset, stringBoundary];
        //设置Content-Type的值
        [self setContentTypeValue:contenttypevalue];
        
        
        NSMutableData *data = [NSMutableData data];
        
        //添加首行分隔
        [data appendData:[startBoundary dataUsingEncoding:self.bodyStringEncoding]];
        
        //添加到预览用
        [self appenStringToPreview:startBoundary];
        
        NSInteger idx = 0;
        for (MimePart *item in self.mimeparts)
        {
            NSDictionary *header = item.allHeaders;
            for (NSString *key in [header allKeys])
            {
                NSString *name = key;
                NSString *value = [header objectForKey:name];
                
                NSString *headerstring = [NSString stringWithFormat:@"%@ : %@\r\n",name,value];
                
                [data appendData:[headerstring dataUsingEncoding:self.bodyStringEncoding]];
                
                //添加到预览用
                [self appenStringToPreview:headerstring];
            }
            //段头与内容之间有一个空行
            NSString *spaceline = @"\r\n";
            [data appendData:[spaceline dataUsingEncoding:self.bodyStringEncoding]];
            
            //添加到预览用
            [self appenStringToPreview:spaceline];
            
            //添加段落的body部分
            NSString *pbody = item.bodystring;
            if (pbody)
            {
                [data appendData:[pbody dataUsingEncoding:self.bodyStringEncoding]];
                
                //添加到预览用
                [self appenStringToPreview:pbody];
            }
            else if (item.bodyFileData.length > 0)
            {
                [data appendData:item.bodyFileData];
                
                //添加到预览用
                [self appenStringToPreview:[NSString stringWithFormat:@"(has data size = %lu)",(unsigned long)item.bodyFileData.length]];
            }
            
            ++idx;
            if (idx != [self.mimeparts count])
            {
                //添加一个分隔符
                [data appendData:[partItemBoundary dataUsingEncoding:self.bodyStringEncoding]];
                //添加到预览用
                [self appenStringToPreview:partItemBoundary];
            }
        }
        
        //添加结束行
        [data appendData:[endBoundary dataUsingEncoding:self.bodyStringEncoding]];
        //添加到预览用
        [self appenStringToPreview:endBoundary];
        
        return data;
    }
    
    return nil;
}


- (NSString *)previewBodyStringOfFormData
{
    return self.priviews;
}

@end
