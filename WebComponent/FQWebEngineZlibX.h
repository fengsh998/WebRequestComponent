//
//  FQWebEngineZlibX.h
//  FQFrameWork
//
//  Created by fengsh on 13-2-27.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//
//  Copyright (c) 2014年 fengsh998@163.com
//  blog:http://blog.csdn.net/fengsh998
//
//              压缩、解压

#import <Foundation/Foundation.h>
#import <zlib.h>

@class FQDataCompressor;
@class FQDataDeCompressor;

@interface FQWebEngineZlibX : NSObject

//压缩
+ (NSData *)compressData:(NSData*)uncompressedData error:(NSError **)err;
+ (BOOL)compressDataFromFile:(NSString *)sourcePath toFile:(NSString *)destinationPath error:(NSError **)err;

//解压
+ (NSData *)deCompressData:(NSData*)compressedData error:(NSError **)err;
+ (BOOL)deCompressDataFromFile:(NSString *)sourcePath toFile:(NSString *)destinationPath error:(NSError **)err;

@end


@interface FQDataCompressor : NSObject {
	BOOL streamReady;
	z_stream zStream;
}


+ (id)compressor;

// Compress the passed chunk of data
// Passing YES for shouldFinish will finalize the deflated data - you must pass YES when you are on the last chunk of data
- (NSData *)compressBytes:(Bytef *)bytes length:(NSUInteger)length error:(NSError **)err shouldFinish:(BOOL)shouldFinish;

// Convenience method - pass it some data, and you'll get deflated data back
+ (NSData *)compressData:(NSData*)uncompressedData error:(NSError **)err;

// Convenience method - pass it a file containing the data to compress in sourcePath, and it will write deflated data to destinationPath
+ (BOOL)compressDataFromFile:(NSString *)sourcePath toFile:(NSString *)destinationPath error:(NSError **)err;

// Sets up zlib to handle the inflating. You only need to call this yourself if you aren't using the convenience constructor 'compressor'
- (NSError *)setupStream;

// Tells zlib to clean up. You need to call this if you need to cancel deflating part way through
// If deflating finishes or fails, this method will be called automatically
- (NSError *)closeStream;

@property (assign, readonly) BOOL streamReady;
@end


@interface FQDataDecompressor : NSObject {
	BOOL streamReady;
	z_stream zStream;
}

// Convenience constructor will call setupStream for you
+ (id)decompressor;

// Uncompress the passed chunk of data
- (NSData *)uncompressBytes:(Bytef *)bytes length:(NSUInteger)length error:(NSError **)err;

// Convenience method - pass it some deflated data, and you'll get inflated data back
+ (NSData *)uncompressData:(NSData*)compressedData error:(NSError **)err;

// Convenience method - pass it a file containing deflated data in sourcePath, and it will write inflated data to destinationPath
+ (BOOL)uncompressDataFromFile:(NSString *)sourcePath toFile:(NSString *)destinationPath error:(NSError **)err;

// Sets up zlib to handle the inflating. You only need to call this yourself if you aren't using the convenience constructor 'decompressor'
- (NSError *)setupStream;

// Tells zlib to clean up. You need to call this if you need to cancel inflating part way through
// If inflating finishes or fails, this method will be called automatically
- (NSError *)closeStream;

@property (assign, readonly) BOOL streamReady;
@end
