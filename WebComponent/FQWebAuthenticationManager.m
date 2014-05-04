//
//  FQWebAuthenticationManager.m
//  FQFrameWork
//
//  Created by fengsh on 13-2-27.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//
//  Copyright (c) 2014年 fengsh998@163.com
//  blog:http://blog.csdn.net/fengsh998
//

#import "FQWebAuthenticationManager.h"

NSString *FQWebAuthenticationUsername           = @"Username";
NSString *FQWebAuthenticationPassword           = @"Password";

@implementation FQWebCredentials
@synthesize username;
@synthesize password;
@synthesize domain;
@synthesize realm;
@synthesize host;
@synthesize port;
@synthesize protocol;
@synthesize reqAuthentication;

- (id)init
{
    self = [super init];
    if (self) {
        reqAuthentication = nil;
    }
    return self;
}

- (void)setReqAuthentication:(CFHTTPAuthenticationRef)authentication
{
    if (reqAuthentication) {
        CFRelease(reqAuthentication);
        reqAuthentication = nil;
    }
    
    reqAuthentication = (CFHTTPAuthenticationRef)CFRetain(authentication);
}

- (void)dealloc
{
    [username release];
    [password release];
    [domain release];
    [realm release];
    [host release];
    [protocol release];

    if (reqAuthentication) {
        CFRelease(reqAuthentication);
        reqAuthentication = nil;
    }
    
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    FQWebCredentials *copy      = [[self class]copyWithZone:zone];
    copy.username               = self.username;
    copy.password               = self.password;
    copy.domain                 = self.domain;
    copy.realm                  = self.realm;
    copy.host                   = self.host;
    copy.port                   = self.port;
    copy.protocol               = self.protocol;
    copy.reqAuthentication      = self.reqAuthentication;
    return copy;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{username : %@ , password : %@ , domain : %@ , realm : %@ ,\
host : %@ , port : %ld , protocol : %@ ,reqauthentication : %@}",username,password,domain,realm,host,
            (long)port,protocol,reqAuthentication];
}

- (BOOL)isEqual:(id)object
{
    FQWebCredentials *other = object;
    return [self.username isEqual:other.username] && [self.password isEqual:other.password] &&
    (self.port == other.port) && [self.realm isEqual:other.realm] && [self.domain isEqual:other.domain]
    && [self.host isEqual: other.host] && [self.protocol isEqual:other.protocol];
}

@end

@interface FQWebAuthenticationManager()
{
    
}

@end

static FQWebAuthenticationManager *instance = nil;
@implementation FQWebAuthenticationManager


/**
 *	@说明	存储证书
 *
 *	@参数 	credentials 	需要存储的证书
 *	@参数 	host            请求URL中的host
 *	@参数 	port            请求URL中的Port
 *	@参数 	protocol        请求协议如:"http", "ftp", "https"
 *	@参数 	realm           从质询请求www-Authentication中提取出的realm
 */
+ (void)saveCredentials:(NSURLCredential *)credentials forHost:(NSString *)host port:(int)port
               protocol:(NSString *)protocol realm:(NSString *)realm

{
	NSURLProtectionSpace *protectionSpace = [[[NSURLProtectionSpace alloc]
                                              initWithHost:host
                                              port:port
                                              protocol:protocol
                                              realm:realm
                                              authenticationMethod:NSURLAuthenticationMethodDefault]
                                             autorelease];
    
	[[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:credentials
                                                        forProtectionSpace:protectionSpace];
}

/**
 *	@说明	保存代理证书
 *
 *	@参数 	credentials 	需要存储的证书
 *	@参数 	host            代理服务器URL取的host
 *	@参数 	port            代理服务器URL的port
 *	@参数 	realm           从质询请求www-Authentication中提取出的realm
 */
+ (void)saveCredentials:(NSURLCredential *)credentials forProxy:(NSString *)host port:(int)port
                  realm:(NSString *)realm

{
	NSURLProtectionSpace *protectionSpace = [[[NSURLProtectionSpace alloc]
                                              initWithProxyHost:host
                                              port:port
                                              type:NSURLProtectionSpaceHTTPProxy
                                              realm:realm
                                              authenticationMethod:NSURLAuthenticationMethodDefault] autorelease];
    
	[[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:credentials
                                                        forProtectionSpace:protectionSpace];
}


/**
 *	@说明	通过host,port,protocol,realm提取证书
 *
 *	@参数 	host
 *	@参数 	port
 *	@参数 	protocol
 *	@参数 	realm
 *
 *	@return	证书对象 , 否则 nil 获取不到
 */
+ (NSURLCredential *)savedCredentialsForHost:(NSString *)host
                                        port:(int)port
                                    protocol:(NSString *)protocol
                                       realm:(NSString *)realm

{
	NSURLProtectionSpace *protectionSpace = [[[NSURLProtectionSpace alloc]
                                              initWithHost:host
                                              port:port
                                              protocol:protocol
                                              realm:realm
                                              authenticationMethod:NSURLAuthenticationMethodDefault]
                                             autorelease];
    
	return [[NSURLCredentialStorage sharedCredentialStorage]
            defaultCredentialForProtectionSpace:protectionSpace];
}

/**
 *	@说明	通过host,port,protocol,realm提取证书
 *
 *	@参数 	host
 *	@参数 	port
 *	@参数 	protocol
 *	@参数 	realm
 *
 *	@return	证书对象 , 否则 nil 获取不到
 */
+ (NSURLCredential *)savedCredentialsForProxy:(NSString *)host port:(int)port
                                        realm:(NSString *)realm
{
	NSURLProtectionSpace *protectionSpace = [[[NSURLProtectionSpace alloc]
                                              initWithProxyHost:host
                                              port:port
                                              type:NSURLProtectionSpaceHTTPProxy
                                              realm:realm
                                              authenticationMethod:NSURLAuthenticationMethodDefault]
                                             autorelease];
    
	return [[NSURLCredentialStorage sharedCredentialStorage]
            defaultCredentialForProtectionSpace:protectionSpace];
}

/**
 *	@说明	删除证书
 *
 *	@参数 	host
 *	@参数 	port
 *	@参数 	protocol
 *	@参数 	realm
 */
+ (void)removeCredentialsForHost:(NSString *)host port:(int)port protocol:(NSString *)protocol
                           realm:(NSString *)realm

{
	NSURLProtectionSpace *protectionSpace = [[[NSURLProtectionSpace alloc]
                                              initWithHost:host
                                              port:port
                                              protocol:protocol
                                              realm:realm
                                              authenticationMethod:NSURLAuthenticationMethodDefault]
                                             autorelease];
    
	NSURLCredential *credential = [[NSURLCredentialStorage sharedCredentialStorage]
                                   defaultCredentialForProtectionSpace:protectionSpace];
    
	if (credential)
    {
		[[NSURLCredentialStorage sharedCredentialStorage] removeCredential:credential
                                                        forProtectionSpace:protectionSpace];
	}
}

/**
 *	@说明	删除证书
 *
 *	@参数 	host
 *	@参数 	port
 *	@参数 	realm
 */
+ (void)removeCredentialsForProxy:(NSString *)host port:(int)port realm:(NSString *)realm
{
	NSURLProtectionSpace *protectionSpace = [[[NSURLProtectionSpace alloc]
                                              initWithProxyHost:host
                                              port:port
                                              type:NSURLProtectionSpaceHTTPProxy
                                              realm:realm
                                              authenticationMethod:NSURLAuthenticationMethodDefault]
                                             autorelease];
    
	NSURLCredential *credential = [[NSURLCredentialStorage sharedCredentialStorage]
                                   defaultCredentialForProtectionSpace:protectionSpace];
	if (credential)
    {
		[[NSURLCredentialStorage sharedCredentialStorage] removeCredential:credential
                                                        forProtectionSpace:protectionSpace];
	}
}


+ (FQWebAuthenticationManager *)defaultManager
{
    if (!instance)
    {
        instance = [[[self class]alloc]init];
    }
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        memoryCredential = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (void)dealloc
{
    [memoryCredential release];
    [super dealloc];
}

#pragma mark - store to session
- (void)storeCredentialsToSession:(FQWebCredentials *)credential
{
    if (credential.username && credential.password)
    {
        NSString *key = [NSString stringWithFormat:@"%@:%ld:%@",credential.host,
                         (long)credential.port,credential.protocol];

        [memoryCredential setObject:credential forKey:key];
    }
}

- (void)removeCredentialsFromSession:(FQWebCredentials *)credential
{
    NSString *key = [NSString stringWithFormat:@"%@:%ld:%@",credential.host,
                     (long)credential.port,credential.protocol];
    
    [memoryCredential removeObjectForKey:key];
}

- (FQWebCredentials *)fetchCredentialsFromSessionByHost:(NSString *)host
                                               withPort:(NSInteger)port
                                           withProtocol:(NSString *)protocol
{
    NSString *key = [NSString stringWithFormat:@"%@:%ld:%@",host,
                     (long)port,protocol];

    return [memoryCredential objectForKey:key];
}

- (void)storeProxyCredentialsToSession:(FQWebCredentials *)credential
{
    if (credential.username && credential.password)
    {
        NSString *key = [NSString stringWithFormat:@"%@:%ld:Proxy",credential.host,
                         (long)credential.port];

        [memoryCredential setObject:credential forKey:key];
    }
}

- (void)removeProxyCredentialsFromSession:(FQWebCredentials *)credential
{
    NSString *key = [NSString stringWithFormat:@"%@:%ld:Proxy",credential.host,
                     (long)credential.port];
    
    [memoryCredential removeObjectForKey:key];
}

- (FQWebCredentials *)fetchProxyCredentialsFromSessionByHost:(NSString *)host
                                                    withPort:(NSInteger)port
{
    NSString *key = [NSString stringWithFormat:@"%@:%ld:Proxy",host,
                     (long)port];
    return [memoryCredential objectForKey:key];
}



#pragma mark - store to keychain
//NSURLCredentialPersistenceNone ：要求 URL 载入系统 “在用完相应的认证信息后立刻丢弃”。
//NSURLCredentialPersistenceForSession ：要求 URL 载入系统 “在应用终止时，丢弃相应的 credential ”。
//NSURLCredentialPersistencePermanent ：要求 URL 载入系统 "将相应的认证信息存入钥匙串（keychain），以便其他应用也能使用。
- (void)storeCredentialsToKeyChain:(FQWebCredentials *)credential
{
    if (credential.username && credential.password)
    {
        NSURLCredential *authCredentials = [NSURLCredential
                                            credentialWithUser:credential.username
                                            password:credential.password
                                            persistence:NSURLCredentialPersistencePermanent];
        
        if (authCredentials)
        {
            [[self class] saveCredentials:authCredentials
                                  forHost:credential.host
                                     port:(int)credential.port
                                 protocol:credential.protocol
                                    realm:credential.realm];
        }
    }
}

- (void)removeCredentialsFromKeyChain:(FQWebCredentials *)credential
{
    [[self class] removeCredentialsForHost:credential.host
                                      port:(int)credential.port
                                  protocol:credential.protocol
                                     realm:credential.realm];
}

- (FQWebCredentials *)fetchCredentialsFromKeyChainByHost:(NSString *)host
                                                withPort:(NSInteger)port
                                            withProtocol:(NSString *)protocol
                                               withRealm:(NSString *)realm
{
    NSURLCredential *authCredentials = [[self class] savedCredentialsForHost:host
                                                                         port:(int)port
                                                                     protocol:protocol
                                                                        realm:realm];
    if (authCredentials)
    {
        FQWebCredentials *credentials = [[[FQWebCredentials alloc]init]autorelease];
        credentials.host              = host;
        credentials.port              = port;
        credentials.username          = authCredentials.user;
        credentials.password          = authCredentials.password;
        credentials.realm             = realm;
        credentials.protocol          = protocol;
        return credentials;
    }
    
    return nil;
}

- (void)storeProxyCredentialsToKeyChain:(FQWebCredentials *)credential
{
    if (credential.username && credential.password)
    {
        NSURLCredential *authCredentials = [NSURLCredential
                                            credentialWithUser:credential.username
                                            password:credential.password
                                            persistence:NSURLCredentialPersistencePermanent];
        
        if (authCredentials)
        {
            [[self class] saveCredentials:authCredentials
                                 forProxy:credential.host
                                     port:(int)credential.port
                                    realm:credential.realm];
        }
    }
}

- (void)removeProxyCredentialsFromKeyChain:(FQWebCredentials *)credential
{
    [[self class]removeCredentialsForProxy:credential.host
                                      port:(int)credential.port
                                     realm:credential.realm];
}

- (FQWebCredentials *)fetchProxyCredentialsFromKeyChainByHost:(NSString *)host
                                                     withPort:(NSInteger)port
                                                    withRealm:(NSString *)realm
{
    NSURLCredential *authCredentials = [[self class] savedCredentialsForProxy:host
                                                                         port:(int)port
                                                                        realm:realm];
    if (authCredentials)
    {
        FQWebCredentials *proxycredentials = [[[FQWebCredentials alloc]init]autorelease];
        proxycredentials.host = host;
        proxycredentials.port = port;
        proxycredentials.username = authCredentials.user;
        proxycredentials.password = authCredentials.password;
        proxycredentials.realm = realm;
        return proxycredentials;
    }
    
    return nil;
}


@end
