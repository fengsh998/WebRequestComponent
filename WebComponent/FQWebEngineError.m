//
//  FQWebEngineError.cpp
//  FQFrameWork
//
//  Created by fengsh on 13-2-27.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//
//  Copyright (c) 2014年 fengsh998@163.com
//  blog:http://blog.csdn.net/fengsh998
//

#include "FQWebEngineError.h"

NSString *FQWebErrorDomain                  = @"FQWebEngineError";

static NSString *FQWebUnKownErrorDescription           = @"FQWebEngine Error : UnKown Error.";

static NSString *FQWebURLEmptyErrorDescription         = @"FQWebEngine Error : Resquest URL is empty.";

static NSString *FQWebReadStreamErrorDescription       = @"FQWebEngine Error : Failed while reading \
stream,The operation couldn’t be completed";

static NSString *FQWebRequestTimeoutErrorDescription   = @"FQWebEngine Error : Request Time out.";

static NSString *FQWebProxySettingErrorDescription     = @"FQWebEngine Error : proxy error. ";

static NSString *FQWebNetWorkConnectErrorDescription   = @"FQWebEngine Error : current net error .";

static NSString *FQWebConnectToServerRefusedErrorDescription = @"FQWebEngine Error : Connection refused.";

static NSString *FQWebSSLConnectErrorDescription       = @"FQWebEngine Error : A connection failure \
occurred ,SSL problem (Possible causes may include a bad/expired/self-signed certificate, clock set \
to wrong date)";

static NSString *FQWebCredentialsApplyErrorDescription = @"FQWebEngine Error : apply Credential to \
current request failed. ";

static NSString *FQWebAuthenticationFailedErrorDescription = @"FQWebEngine Error : Authentication Failed . ";

@implementation FQWebError

+ (NSString *)getErrorDescriptionByErrType:(FQRequestErrorType)err
{
    switch (err) {
        case FQWebUrlEmptyError:
            return FQWebURLEmptyErrorDescription;
            break;
        case FQWebReadDataStreamError:
            return FQWebReadStreamErrorDescription;
            break;
        case FQWebRequestTimeoutError:
            return FQWebRequestTimeoutErrorDescription;
            break;
        case FQWebProxySettingError:
            return FQWebProxySettingErrorDescription;
            break;
        case FQWebNetWorkConnectError:
            return FQWebNetWorkConnectErrorDescription;
            break;
        case FQWebConnectToServerRefusedError:
            return FQWebConnectToServerRefusedErrorDescription;
            break;
        case FQWebSSLConnectError:
            return FQWebSSLConnectErrorDescription;
            break;
        case FQWebCredentialsApplyError:
            return FQWebCredentialsApplyErrorDescription;
            break;
        case FQWebAuthenticationFailedError:
            return FQWebAuthenticationFailedErrorDescription;
            break;
        default:
            break;
    }
    return FQWebUnKownErrorDescription;
}

+ (NSError *)makeFQWebEngineErrorWith:(FQRequestErrorType)errtype
{
    NSString *errMsg = [self getErrorDescriptionByErrType:errtype];
    return [NSError errorWithDomain:FQWebErrorDomain
                               code:errtype
                           userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                     errMsg,NSLocalizedDescriptionKey,nil]];
}

+ (NSError *)makeFQWebEngineErrorWith:(FQRequestErrorType)errtype andReason:(NSString *)reason
{
    NSString *errMsg = [self getErrorDescriptionByErrType:errtype];
    if (reason)
    {
        errMsg = [errMsg stringByAppendingString:reason];
    }
    
    return [NSError errorWithDomain:FQWebErrorDomain
                               code:errtype
                           userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                     errMsg,NSLocalizedDescriptionKey,nil]];
}

@end