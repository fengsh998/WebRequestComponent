//
//  FQWebAuthenticationManager.h
//  FQFrameWork
//
//  Created by fengsh on 13-2-27.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//
//  Copyright (c) 2014年 fengsh998@163.com
//  blog:http://blog.csdn.net/fengsh998
//
//               认证管理

#import <Foundation/Foundation.h>

typedef enum {
    amNone,
    amBasic,
    amDigest,
    amNTLM,
    amOAuth20                   //http://blog.csdn.net/hereweare2009/article/details/3968582
}AuthenticationMethod;

extern NSString *FQWebAuthenticationUsername;
extern NSString *FQWebAuthenticationPassword;

@interface FQWebCredentials : NSObject
{
    NSString           *username;
    NSString           *password;
    NSString           *domain;
    NSString           *realm;
    NSString           *host;
    NSInteger          port;
    NSString           *protocol;
    CFHTTPAuthenticationRef reqAuthentication;
}

@property (nonatomic,retain) NSString           *username;
@property (nonatomic,retain) NSString           *password;
@property (nonatomic,retain) NSString           *domain;
@property (nonatomic,retain) NSString           *realm;
@property (nonatomic,retain) NSString           *host;
@property (nonatomic,assign) NSInteger          port;
@property (nonatomic,retain) NSString           *protocol;
@property (nonatomic,assign) CFHTTPAuthenticationRef reqAuthentication;

- (BOOL)isEqual:(id)object;
@end

@interface FQWebAuthenticationManager : NSObject
{
@private
    NSMutableDictionary         *memoryCredential;
}


+ (FQWebAuthenticationManager *)defaultManager;

//session
- (void)storeCredentialsToSession:(FQWebCredentials *)credential;
- (void)removeCredentialsFromSession:(FQWebCredentials *)credential;
- (FQWebCredentials *)fetchCredentialsFromSessionByHost:(NSString *)host
                                                withPort:(NSInteger)port
                                           withProtocol:(NSString *)protocol;


- (void)storeProxyCredentialsToSession:(FQWebCredentials *)credential;
- (void)removeProxyCredentialsFromSession:(FQWebCredentials *)credential;
- (FQWebCredentials *)fetchProxyCredentialsFromSessionByHost:(NSString *)host
                                                    withPort:(NSInteger)port;



//key chain
- (void)storeCredentialsToKeyChain:(FQWebCredentials *)credential;
- (void)removeCredentialsFromKeyChain:(FQWebCredentials *)credential;
- (FQWebCredentials *)fetchCredentialsFromKeyChainByHost:(NSString *)host
                                                withPort:(NSInteger)port
                                            withProtocol:(NSString *)protocol
                                               withRealm:(NSString *)realm;

- (void)storeProxyCredentialsToKeyChain:(FQWebCredentials *)credential;
- (void)removeProxyCredentialsFromKeyChain:(FQWebCredentials *)credential;
- (FQWebCredentials *)fetchProxyCredentialsFromKeyChainByHost:(NSString *)host
                                                     withPort:(NSInteger)port
                                               withRealm:(NSString *)realm;

@end
