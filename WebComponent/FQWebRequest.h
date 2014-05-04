//
//  FQWebRequest.h
//  FQFrameWork
//
//  Created by fengsh on 13-2-27.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//
//  Copyright (c) 2014年 fengsh998@163.com
//  blog:http://blog.csdn.net/fengsh998
/*
 
 */

#import <Foundation/Foundation.h>
#import "FQWebEngine.h"

typedef enum {
    requestUseGet       = 0,
    requestUsePost,
    requestUsePut,
    requestUseDelete,
    requestUseHead,
    requestUseTrace,
    requestUseConnect,
    requestUseOptions
}RequestMethod;

//post 表单中常见的四种表单请求方式
typedef enum {
    postformURLEncoded,                 /*对应Content-Type: application/x-www-form-urlencoded;*/
    postformMultipartData,              /*对应Content-Type: multipart/form-data; boundary=----*/
    postformJson,                       /*对应Content-Type: application/json;
                                         当然也可以使用application/x-www-form-urlencoded;*/
    postformXML                         /*对应Content-Type: text/xml;*/
}PostFormDataType;


@protocol FQWebRequestDelegate;
@protocol FQWebRequestProgressDelegate;
@protocol FQWebRequestInGroupDelegate;


@class FormDataPackage;

@interface FQWebRequest : FQWebRequestAbstract
{
@private
    RequestMethod                           m_requestMethod;
    id<FQWebRequestDelegate>                delegate;
}
/*  cookies 持久性，当为True时，保存响应的cookies 否则不保存*/
@property (nonatomic,assign)   BOOL                         autoSaveUseCookies;
@property (nonatomic,assign)   id<FQWebRequestDelegate>                delegate;

#pragma mark - 类方法
+ (id)requestWithURL:(NSString *)url;
#pragma mark - 构造方法
- (id)initWithURL:(NSURL *)url;
#pragma mark - setter
/*
 *  设置请求的方法类型
 *
 */
- (void)setRequestMethod:(RequestMethod) requestmethod;
/*
 *  用户可自定义的tag
 *
 */
- (void)setTag:(NSInteger)itag;
/*
 *  用户可对该请求设定一个id 用于异步上下文判断处理
 *  当然也可以依靠requestID
 */
- (void)setIdentity:(NSString *)identiter;
/*
 *  设置请求是否需要并发，默认是并发，如果需要串行请求时，则设为NO
 */
- (void)setAllowComplicating:(BOOL)flag;
/*
 *  对当前的请求进行取销
 */
- (void)cancelRequest;
/*
 开始执行
 */
- (void)go;

@end

typedef FQWebRequest FQHttpRequest;

/**************************************************************************************************
 
                                多个请求一起发送，等待所有响应完成后才响应结果
 
                                            多个请求作为一组应答
 **************************************************************************************************/

@interface FQWebGroupRequest : FQWebRequestAbstractList
{
    id<FQWebRequestInGroupDelegate>                delegate;
}
@property (nonatomic,assign)   id<FQWebRequestInGroupDelegate>                delegate;
/**
 *	@说明	添加请求到组中
 *
 *	@参数 	request 	待发送的请求
 */
- (void)addRequest:(FQWebRequest *)request;

/**
 *	@说明	清空添加的请求
 */
- (void)cleanAllsRequest;

/**
 *	@说明	请求开始
 */
- (void)start;

/**
 *	@说明	取消所有请求
 */
- (void)cancel;

@end

/**************************************************************************************************
 
                                    下载文件请求
 
 1.遗留bug,当下载响应是mime时在content-desipositon中提取的名件名，需要做一些适配，但目前未适配。
 
 **************************************************************************************************/
@interface FQDownLoadRequest : FQWebRequest
{
    NSString                                *folderpath;
    BOOL                                    supportBreakpointsResume;
    NSString                                *useCustomSaveFileName;
}

@property (nonatomic,readonly) NSString                                 *folderpath;
/*
 *      复盖父类的delegate
 */
@property (nonatomic,assign)   id<FQWebRequestDelegate,
                                FQWebRequestProgressDelegate>           delegate;
/*
 *      设置是否支持断点续传，默认为YES
 */
@property (nonatomic,assign)   BOOL                                     supportBreakpointsResume;

/*  
 *      useCustomSaveFileName:不带路径的文件名称
 *      用户在下载时，设定了保存的名件名，一旦这个设定，应用将不会再自动识别提取文件名
 *      如果没有设定，则会自动根据URL或响应进行提取出下载的文件名。
 */
@property (nonatomic,retain)   NSString                                 *useCustomSaveFileName;


+ (FQDownLoadRequest *)downloadWithURL:(NSString *)url;
/*
 *      设置下载存放路径
 */
- (void)setDownloadStorePath:(NSString *)folderPath;

/*
 *      专为断点续传设置。
 *      redownloadfile:已下载部份的文件
 *      resume : 设为True时则进行断点续传,false时，则重新从头开始下载。
 */
- (void)setReDownloadFile:(NSString *)redownloadfile useResume:(BOOL)resume;

@end

/**************************************************************************************************
 
                                        上传文件请求
 
        如果没有指定使用PUT方式，则默认的都是POST方式进行上传。
 **************************************************************************************************/
@class FormDataPackage;

@interface FQUploadRequest : FQWebRequest

@property (nonatomic,assign)   id<FQWebRequestDelegate,
                                FQWebRequestProgressDelegate>           delegate;

+ (FQUploadRequest *)uploadWithUrl:(NSString *)url;
/*
    一次请求只支持一个文件上传
    比如PUT大文件时用
 */
- (void)setUploadFile:(NSString *)filepath;

/*
    采用post form表单的方式，可以一次上传多个文件
    formdata : 需要注意的是postBodyType这个属性请见PostFormDataType说明
 */
- (void)setuploadFormData:(FormDataPackage *)formdata;

@end;

/**************************************************************************************************
 
                                        mulit form part MIME分段部分
 
 **************************************************************************************************/

@interface MimePart : NSObject
{
    NSString                        *bodystring;
    NSMutableData                   *bodyFileData;
@private
    NSMutableDictionary             *headers;
}

/*
    如果内容是普通字符时使用
 */
@property (nonatomic,retain) NSString        *bodystring;
/*
    如果内容是文件流时使用，当然普通字符也同样适合
 */
@property (nonatomic,retain) NSMutableData   *bodyFileData;

- (void)addMimeHeader:(NSString *)name withValue:(id<NSObject>)value;
- (id)getHeaderValueByName:(NSString *)name;
- (NSDictionary *)allHeaders;

@end

/**************************************************************************************************
 
                                        post Body 表单的数据包
 
 **************************************************************************************************/
@interface FormDataPackage : NSObject
{
    NSStringEncoding        bodyStringEncoding;
    PostFormDataType        postBodyType;
    NSString                *contentTypeValue;
    BOOL                    needMakePreviewstaring;
}

/*
    将文件转为字符串流.
    [NSMutableData dataWithContentsOfFile:];也可以
 */
+ (NSMutableData *)fileCovertToStringStream:(NSString *)filepath;
/*
    post body的内容编码方式，如果不设置，将以NSUTF8StringEncoding作为黑认方式
    对于 multiform来说这只是返映了整个mime是使用该coding,但各个部分中有可能是xml
    或内存流的形式，解码时需要根据mime各个段落中的Content-Disposition及Content-Type来决定
    详细可以看下Mime包
 */
@property (nonatomic,assign)   NSStringEncoding        bodyStringEncoding;
/*
    默认为postformURLEncoded方式,
    该属性至关重要，影响到表单的具体数据结构
 */
@property (nonatomic,assign)   PostFormDataType        postBodyType;
/*
    根据不同的PostFormDataType 构造相应的content-type:请求头域的值以供请求时使用
 */
@property (nonatomic,readonly) NSString                *contentTypeValue;

/*
    设置为True时可以进行构造表单的数据进而生成预览数据，主要在于帮助查看组建的表单数据是否
    正确。默认为FASE，因为有内存开销，所以在调试的时候可以设为True，使用时就设为False;
 */
@property (nonatomic,assign)   BOOL                    needMakePreviewstaring;

/********************************针对postformURLEncoded***************************************/
// 添加一个值到body
- (void)addPostValue:(id <NSObject>)value forKey:(NSString *)key;

// 设置一个值到body,如果body原来的变量值存在，则被替换为新的值
- (void)setPostValue:(id <NSObject>)value forKey:(NSString *)key;

- (NSData *)buildURLEncodedPostBody;
/*********************************************************************************************/

/********************************针对postformMultipartData*************************************/
//添加一段mime数据即broundary分隔的每段落
- (void)addMultiPart:(MimePart *)part;
//建立MIME数据包
- (NSData *)buildMultipartFormDataPostBody;
/*********************************************************************************************/

/*
    NSLog(@"%@",[xx previewBodyStringOfFormData]);
    此方法是否有数据输出，处决于needMakePreviewstaring 属性是否为TRUE;
    如果想查看postformURLEncoded类型的表单数据。需要进行几步
    1.postBodyType属性设为postformURLEncoded
    2.调用buildURLEncodedPostBody
    3.调用previewBodyStringOfFormData来获取预览数据
    同样如果需要查看postformMultipartData类型的数据也需要设置
    1.postBodyType属性设为postformMultipartData
    2.调用buildMultipartFormDataPostBody;
    3.调用previewBodyStringOfFormData来获取预览数据
 
    此方法只用于输出查看当前构造的表单数据是否正常。一旦调试好表单的数据结构，建议移除此方法。
    因为会点用小小的内存。
 */
- (NSString *)previewBodyStringOfFormData;

@end



