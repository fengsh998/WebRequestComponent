//
//  FQwebEngineDefines.h
//  FQFrameWork
//
//  Created by fengsh on 13-2-27.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//
//  Copyright (c) 2014年 fengsh998@163.com
//  blog:http://blog.csdn.net/fengsh998
/*

*/

#ifndef FQFrameWork_webEngineDefines_h
#define FQFrameWork_webEngineDefines_h

#if DEBUG
#define LOGOUT      YES
#define outlevel    0   //debug or info or error or warning
#else
#define LOGOUT      NO
#define outlevel    2   //(warning or error)
#endif

#define USE_FQLOG   1

#if USE_FQLOG
#import "FQLogAPI.h"
#else
#define FQLogInfo(frmt,...)     NSLog(frmt,##__VA_ARGS__)
#define FQLogWarn(frmt,...)     NSLog(frmt,##__VA_ARGS__)
#define FQLogError(frmt,...)    NSLog(frmt,##__VA_ARGS__)
#define FQLog(frmt,...)         NSLog(frmt,##__VA_ARGS__)
#endif

#define outprint(debug,level,frmt,...) { \
    if (debug >= outlevel) \
    { \
            switch(level) \
            {\
                case 1:\
                    FQLogInfo(frmt,##__VA_ARGS__);\
                break;\
                case 2:\
                    FQLogWarn(frmt,##__VA_ARGS__);\
                break;\
                case 3:\
                    FQLogError(frmt,##__VA_ARGS__);\
                break;\
                default:\
                    FQLog(frmt,##__VA_ARGS__);\
                break;\
            }\
    }\
}

#define FQWebComponentLog(frmt,...)         outprint(LOGOUT,0,frmt,##__VA_ARGS__)
#define FQWebComponentInfoLog(frmt,...)     outprint(LOGOUT,1,frmt,##__VA_ARGS__)
#define FQWebComponentWarnLog(frmt,...)     outprint(LOGOUT,2,frmt,##__VA_ARGS__)
#define FQWebComponentErrorLog(frmt,...)    outprint(LOGOUT,3,frmt,##__VA_ARGS__)


#define http_Age                       @"Age"
#define http_Accept_Ranges             @"Accept-Ranges"
#define http_Accept                    @"Accept"
#define http_Accept_Encoding           @"Accept-Encoding"
#define http_Accept_Language           @"Accept-Language"

#define http_Connection                @"Connection"
#define http_Content_Length            @"Content-Length"
#define http_Content_Type              @"Content-Type"
#define http_Cache_Control             @"Cache-Control"
#define http_Content_Encoding          @"Content-Encoding"
#define http_Cookie                    @"Cookie"
#define http_Content_Disposition       @"Content-Disposition"  //见RFC 6266 RFC 2047
#define http_Content_Range             @"Content-Range"         //断点续传时使用 "Content-Range" = "bytes 461068-13073047/13073048";

#define http_Date                      @"Date"

#define http_Expires                   @"Expires"
#define http_ETag                      @"ETag"

#define http_Keep_Alive                @"Keep-Alive"

#define http_Location                  @"Location"
#define http_Last_Modified             @"Last-Modified"

#define http_Origin                    @"Origin"

#define http_P3P                       @"P3P"
#define http_Pragma                    @"Pragma"//http 1.0 支持 与cache-control意义一样

#define http_Referer                   @"Referer"
#define http_Range                     @"Range"

#define http_Server                    @"Server"
#define http_Set_Cookie                @"Set-Cookie"

#define http_Transfer_Encoding         @"Transfer-Encoding" //取值只有两种 chunked 分块，identity RFC 2616

#define http_User_Agent                @"User-Agent"

#define http_Vary                      @"Vary"


#define mime_content_transfer_encoding @"Content-Transfer-Encoding"



#define FQWebEngineVersion             @"1.0"


#endif
