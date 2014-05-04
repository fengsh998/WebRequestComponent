//
//  FQWebEngineZlibX.m
//  FQFrameWork
//
//  Created by fengsh on 13-2-27.
//  Copyright (c) 2014年 fengsh. All rights reserved.
//
//  Copyright (c) 2014年 fengsh998@163.com
//  blog:http://blog.csdn.net/fengsh998
//

#import "FQWebEngineZlibX.h"

#define DATA_CHUNK_SIZE 262144 // Deal with gzipped data in 256KB chunks
#define COMPRESSION_AMOUNT Z_DEFAULT_COMPRESSION

#define ERR_DOMAIN              @"FQCompressError"
#define ERR_DOMAIN_CODE         119

@implementation FQWebEngineZlibX

+ (NSData *)compressData:(NSData*)uncompressedData error:(NSError **)err
{
    return [FQDataCompressor compressData:uncompressedData error:err];
}

+ (BOOL)compressDataFromFile:(NSString *)sourcePath toFile:(NSString *)destinationPath error:(NSError **)err
{
    return [FQDataCompressor compressDataFromFile:sourcePath toFile:destinationPath error:err];
}

+ (NSData *)deCompressData:(NSData*)compressedData error:(NSError **)err
{
    return [FQDataDecompressor uncompressData:compressedData error:err];
}

+ (BOOL)deCompressDataFromFile:(NSString *)sourcePath toFile:(NSString *)destinationPath error:(NSError **)err
{
    return [FQDataDecompressor uncompressDataFromFile:sourcePath toFile:destinationPath error:err];
}


@end





@interface FQDataCompressor ()
+ (NSError *)deflateErrorWithCode:(int)code;
@end

@implementation FQDataCompressor

+ (id)compressor
{
	FQDataCompressor *compressor = [[[self alloc] init] autorelease];
	[compressor setupStream];
	return compressor;
}

- (void)dealloc
{
	if (streamReady) {
		[self closeStream];
	}
	[super dealloc];
}

- (NSError *)setupStream
{
	if (streamReady) {
		return nil;
	}
	// Setup the inflate stream
	zStream.zalloc = Z_NULL;
	zStream.zfree = Z_NULL;
	zStream.opaque = Z_NULL;
	zStream.avail_in = 0;
	zStream.next_in = 0;
	int status = deflateInit2(&zStream, COMPRESSION_AMOUNT, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY);
	if (status != Z_OK) {
		return [[self class] deflateErrorWithCode:status];
	}
	streamReady = YES;
	return nil;
}

- (NSError *)closeStream
{
	if (!streamReady) {
		return nil;
	}
	// Close the deflate stream
	streamReady = NO;
	int status = deflateEnd(&zStream);
	if (status != Z_OK) {
		return [[self class] deflateErrorWithCode:status];
	}
	return nil;
}

- (NSData *)compressBytes:(Bytef *)bytes length:(NSUInteger)length error:(NSError **)err shouldFinish:(BOOL)shouldFinish
{
	if (length == 0) return nil;
	
	NSUInteger halfLength = length/2;
	
	// We'll take a guess that the compressed data will fit in half the size of the original (ie the max to compress at once is half DATA_CHUNK_SIZE), if not, we'll increase it below
	NSMutableData *outputData = [NSMutableData dataWithLength:length/2];
	
	int status;
	
	zStream.next_in = bytes;
	zStream.avail_in = (unsigned int)length;
	zStream.avail_out = 0;
    
	NSInteger bytesProcessedAlready = zStream.total_out;
	while (zStream.avail_out == 0) {
		
		if (zStream.total_out-bytesProcessedAlready >= [outputData length]) {
			[outputData increaseLengthBy:halfLength];
		}
		
		zStream.next_out = (Bytef*)[outputData mutableBytes] + zStream.total_out-bytesProcessedAlready;
		zStream.avail_out = (unsigned int)([outputData length] - (zStream.total_out-bytesProcessedAlready));
		status = deflate(&zStream, shouldFinish ? Z_FINISH : Z_NO_FLUSH);
		
		if (status == Z_STREAM_END) {
			break;
		} else if (status != Z_OK) {
			if (err) {
				*err = [[self class] deflateErrorWithCode:status];
			}
			return NO;
		}
	}
    
	// Set real length
	[outputData setLength: zStream.total_out-bytesProcessedAlready];
	return outputData;
}


+ (NSData *)compressData:(NSData*)uncompressedData error:(NSError **)err
{
	NSError *theError = nil;
	NSData *outputData = [[FQDataCompressor compressor] compressBytes:(Bytef *)[uncompressedData bytes] length:[uncompressedData length] error:&theError shouldFinish:YES];
	if (theError) {
		if (err) {
			*err = theError;
		}
		return nil;
	}
	return outputData;
}



+ (BOOL)compressDataFromFile:(NSString *)sourcePath toFile:(NSString *)destinationPath error:(NSError **)err
{
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    
	// Create an empty file at the destination path
	if (![fileManager createFileAtPath:destinationPath contents:[NSData data] attributes:nil]) {
		if (err) {
			*err = [NSError errorWithDomain:ERR_DOMAIN code:ERR_DOMAIN_CODE userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Compression of %@ failed because we were to create a file at %@",sourcePath,destinationPath],NSLocalizedDescriptionKey,nil]];
		}
		return NO;
	}
	
	// Ensure the source file exists
	if (![fileManager fileExistsAtPath:sourcePath]) {
		if (err) {
			*err = [NSError errorWithDomain:ERR_DOMAIN code:ERR_DOMAIN_CODE userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Compression of %@ failed the file does not exist",sourcePath],NSLocalizedDescriptionKey,nil]];
		}
		return NO;
	}
	
	UInt8 inputData[DATA_CHUNK_SIZE];
	NSData *outputData;
	NSInteger readLength;
	NSError *theError = nil;
	
	FQDataCompressor *compressor = [FQDataCompressor compressor];
	
	NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:sourcePath];
	[inputStream open];
	NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:destinationPath append:NO];
	[outputStream open];
	
    while ([compressor streamReady]) {
		
		// Read some data from the file
		readLength = [inputStream read:inputData maxLength:DATA_CHUNK_SIZE];
        
		// Make sure nothing went wrong
		if ([inputStream streamStatus] == NSStreamStatusError) {
			if (err) {
				*err = [NSError errorWithDomain:ERR_DOMAIN code:ERR_DOMAIN_CODE userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Compression of %@ failed because we were unable to read from the source data file",sourcePath],NSLocalizedDescriptionKey,[inputStream streamError],NSUnderlyingErrorKey,nil]];
			}
			[compressor closeStream];
			return NO;
		}
		// Have we reached the end of the input data?
		if (!readLength) {
			break;
		}
		
		// Attempt to deflate the chunk of data
		outputData = [compressor compressBytes:inputData length:readLength error:&theError shouldFinish:readLength < DATA_CHUNK_SIZE ];
		if (theError) {
			if (err) {
				*err = theError;
			}
			[compressor closeStream];
			return NO;
		}
		
		// Write the deflated data out to the destination file
		[outputStream write:(const uint8_t *)[outputData bytes] maxLength:[outputData length]];
		
		// Make sure nothing went wrong
		if ([inputStream streamStatus] == NSStreamStatusError) {
			if (err) {
				*err = [NSError errorWithDomain:ERR_DOMAIN code:ERR_DOMAIN_CODE userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Compression of %@ failed because we were unable to write to the destination data file at %@",sourcePath,destinationPath],NSLocalizedDescriptionKey,[outputStream streamError],NSUnderlyingErrorKey,nil]];
            }
			[compressor closeStream];
			return NO;
		}
		
    }
	[inputStream close];
	[outputStream close];
    
	NSError *error = [compressor closeStream];
	if (error) {
		if (err) {
			*err = error;
		}
		return NO;
	}
    
	return YES;
}

+ (NSError *)deflateErrorWithCode:(int)code
{
	return [NSError errorWithDomain:ERR_DOMAIN code:ERR_DOMAIN_CODE userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Compression of data failed with code %d",code],NSLocalizedDescriptionKey,nil]];
}

@synthesize streamReady;
@end


@interface FQDataDecompressor ()
+ (NSError *)inflateErrorWithCode:(int)code;
@end;

@implementation FQDataDecompressor

+ (id)decompressor
{
	FQDataDecompressor *decompressor = [[[self alloc] init] autorelease];
	[decompressor setupStream];
	return decompressor;
}

- (void)dealloc
{
	if (streamReady) {
		[self closeStream];
	}
	[super dealloc];
}

- (NSError *)setupStream
{
	if (streamReady) {
		return nil;
	}
	// Setup the inflate stream
	zStream.zalloc = Z_NULL;
	zStream.zfree = Z_NULL;
	zStream.opaque = Z_NULL;
	zStream.avail_in = 0;
	zStream.next_in = 0;
	int status = inflateInit2(&zStream, (15+32));
	if (status != Z_OK) {
		return [[self class] inflateErrorWithCode:status];
	}
	streamReady = YES;
	return nil;
}

- (NSError *)closeStream
{
	if (!streamReady) {
		return nil;
	}
	// Close the inflate stream
	streamReady = NO;
	int status = inflateEnd(&zStream);
	if (status != Z_OK) {
		return [[self class] inflateErrorWithCode:status];
	}
	return nil;
}

- (NSData *)uncompressBytes:(Bytef *)bytes length:(NSUInteger)length error:(NSError **)err
{
	if (length == 0) return nil;
	
	NSUInteger halfLength = length/2;
	NSMutableData *outputData = [NSMutableData dataWithLength:length+halfLength];
    
	int status;
	
	zStream.next_in = bytes;
	zStream.avail_in = (unsigned int)length;
	zStream.avail_out = 0;
	
	NSInteger bytesProcessedAlready = zStream.total_out;
	while (zStream.avail_in != 0) {
		
		if (zStream.total_out-bytesProcessedAlready >= [outputData length]) {
			[outputData increaseLengthBy:halfLength];
		}
		
		zStream.next_out = (Bytef*)[outputData mutableBytes] + zStream.total_out-bytesProcessedAlready;
		zStream.avail_out = (unsigned int)([outputData length] - (zStream.total_out-bytesProcessedAlready));
		
		status = inflate(&zStream, Z_NO_FLUSH);
		
		if (status == Z_STREAM_END) {
			break;
		} else if (status != Z_OK) {
			if (err) {
				*err = [[self class] inflateErrorWithCode:status];
			}
			return nil;
		}
	}
	
	// Set real length
	[outputData setLength: zStream.total_out-bytesProcessedAlready];
	return outputData;
}


+ (NSData *)uncompressData:(NSData*)compressedData error:(NSError **)err
{
	NSError *theError = nil;
	NSData *outputData = [[FQDataDecompressor decompressor] uncompressBytes:(Bytef *)[compressedData bytes] length:[compressedData length] error:&theError];
	if (theError) {
		if (err) {
			*err = theError;
		}
		return nil;
	}
	return outputData;
}

+ (BOOL)uncompressDataFromFile:(NSString *)sourcePath toFile:(NSString *)destinationPath error:(NSError **)err
{
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    
	// Create an empty file at the destination path
	if (![fileManager createFileAtPath:destinationPath contents:[NSData data] attributes:nil]) {
		if (err) {
			*err = [NSError errorWithDomain:ERR_DOMAIN code:ERR_DOMAIN_CODE userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Decompression of %@ failed because we were to create a file at %@",sourcePath,destinationPath],NSLocalizedDescriptionKey,nil]];
		}
		return NO;
	}
	
	// Ensure the source file exists
	if (![fileManager fileExistsAtPath:sourcePath]) {
		if (err) {
			*err = [NSError errorWithDomain:ERR_DOMAIN code:ERR_DOMAIN_CODE userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Decompression of %@ failed the file does not exist",sourcePath],NSLocalizedDescriptionKey,nil]];
		}
		return NO;
	}
	
	UInt8 inputData[DATA_CHUNK_SIZE];
	NSData *outputData;
	NSInteger readLength;
	NSError *theError = nil;
	
    
	FQDataDecompressor *decompressor = [FQDataDecompressor decompressor];
    
	NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:sourcePath];
	[inputStream open];
	NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:destinationPath append:NO];
	[outputStream open];
	
    while ([decompressor streamReady]) {
		
		// Read some data from the file
		readLength = [inputStream read:inputData maxLength:DATA_CHUNK_SIZE];
		
		// Make sure nothing went wrong
		if ([inputStream streamStatus] == NSStreamStatusError) {
			if (err) {
				*err = [NSError errorWithDomain:ERR_DOMAIN code:ERR_DOMAIN_CODE userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Decompression of %@ failed because we were unable to read from the source data file",sourcePath],NSLocalizedDescriptionKey,[inputStream streamError],NSUnderlyingErrorKey,nil]];
			}
            [decompressor closeStream];
			return NO;
		}
		// Have we reached the end of the input data?
		if (!readLength) {
			break;
		}
        
		// Attempt to inflate the chunk of data
		outputData = [decompressor uncompressBytes:inputData length:readLength error:&theError];
		if (theError) {
			if (err) {
				*err = theError;
			}
			[decompressor closeStream];
			return NO;
		}
		
		// Write the inflated data out to the destination file
		[outputStream write:(Bytef*)[outputData bytes] maxLength:[outputData length]];
		
		// Make sure nothing went wrong
		if ([inputStream streamStatus] == NSStreamStatusError) {
			if (err) {
				*err = [NSError errorWithDomain:ERR_DOMAIN code:ERR_DOMAIN_CODE userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Decompression of %@ failed because we were unable to write to the destination data file at %@",sourcePath,destinationPath],NSLocalizedDescriptionKey,[outputStream streamError],NSUnderlyingErrorKey,nil]];
            }
			[decompressor closeStream];
			return NO;
		}
		
    }
	
	[inputStream close];
	[outputStream close];
    
	NSError *error = [decompressor closeStream];
	if (error) {
		if (err) {
			*err = error;
		}
		return NO;
	}
    
	return YES;
}


+ (NSError *)inflateErrorWithCode:(int)code
{
	return [NSError errorWithDomain:ERR_DOMAIN code:ERR_DOMAIN_CODE userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Decompression of data failed with code %d",code],NSLocalizedDescriptionKey,nil]];
}

@synthesize streamReady;
@end


