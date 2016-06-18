//
//  JMImageCache.m
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Jake Marsh. All rights reserved.
//

#import "JMImageCache.h"

#define kJMImageCacheDefaultDirectory   @"Library/Caches/JMCache"
#define kJMImageCacheDefaultPrefix      @"JMImageCache"

#define kJSImageCacheQueuePriority      DISPATCH_QUEUE_PRIORITY_DEFAULT

inline static NSString *keyForURL(NSURL *url) {
	return [url absoluteString];
}

@interface JMImageCacheFileData : NSObject

@property (strong, nonatomic) NSString *cachePath;
@property (strong, nonatomic) NSDate *creationDate;
@property (assign, nonatomic) unsigned long long fileSize;

@end

@implementation JMImageCacheFileData

@synthesize cachePath = _cachePath;
@synthesize creationDate = _creationDate;
@synthesize fileSize = _fileSize;

@end

JMImageCache *_sharedCache = nil;

@interface JMImageCache ()

@property (strong, nonatomic) NSString *imageCacheDirectory;
@property (strong, nonatomic) NSOperationQueue *diskOperationQueue;
@property (assign, nonatomic) BOOL informCost;

- (NSString *) _cachePathForKey:(NSString *)key;
- (NSArray *) _fileDatasInImageCacheDirectory:(unsigned long long *)directorySize;
- (void) _downloadAndWriteImageForURL:(NSURL *)url key:(NSString *)key completionBlock:(void (^)(UIImage *image))completion;

@end

@implementation JMImageCache

@synthesize imageCacheDirectory = _imageCacheDirectory;
@synthesize diskOperationQueue = _diskOperationQueue;
@synthesize informCost = _informCost;

+ (JMImageCache *) sharedCache {
	if(!_sharedCache) {
		_sharedCache = [[JMImageCache alloc] init];
	}

	return _sharedCache;
}

- (id) init {
    return [self initWithCacheDirectory:kJMImageCacheDefaultDirectory];
}

- (id) initWithCacheDirectory:(NSString *)cacheDirectory {
    return [self initWithCacheDirectory:cacheDirectory maxMemoryBytesSize:0];
}

- (id) initWithCacheDirectory:(NSString *)cacheDirectory maxMemoryBytesSize:(NSUInteger)bytesSize {
    self = [super init];
    if(!self) return nil;
    
    self.imageCacheDirectory = [NSHomeDirectory() stringByAppendingPathComponent:cacheDirectory];
    self.diskOperationQueue = [[NSOperationQueue alloc] init];
    self.informCost = NO;
    
    if (bytesSize > 0)
    {
        self.informCost = YES;
        [self setTotalCostLimit:bytesSize];
    }
    
    [[NSFileManager defaultManager] createDirectoryAtPath:self.imageCacheDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
	return self;    
}

- (NSString *) _cachePathForKey:(NSString *)key {
    NSString *fileName = [NSString stringWithFormat:@"%@-%lu", kJMImageCacheDefaultPrefix, (unsigned long)[key hash]];
	return [self.imageCacheDirectory stringByAppendingPathComponent:fileName];
}

- (NSArray *) _fileDatasInImageCacheDirectory:(unsigned long long *)directorySize {
    NSMutableArray *filesInCacheDirectory = [NSMutableArray arrayWithCapacity:1];
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    *directorySize = 0;
    
    NSError *error = nil;
    NSArray *contents = [fileMgr contentsOfDirectoryAtPath:self.imageCacheDirectory error:&error];
    if (!contents) return nil;
    
    for (NSString *subpath in contents)
    {
        NSString *cachePath = [self.imageCacheDirectory stringByAppendingPathComponent:subpath];
        
        
        NSDictionary *fileAttr = [fileMgr attributesOfItemAtPath:cachePath error:&error];
        if (fileAttr)
        {
            JMImageCacheFileData *fileData = [[JMImageCacheFileData alloc] init];
            fileData.cachePath = cachePath;
            fileData.creationDate = [fileAttr fileCreationDate];
            fileData.fileSize = [fileAttr fileSize];
            
            [filesInCacheDirectory addObject:fileData];
            
            *directorySize += fileData.fileSize;
        }
    }
    
    NSComparisonResult (^sortByDate)(id obj1, id obj2) = ^NSComparisonResult(id obj1, id obj2) {
        JMImageCacheFileData *fileData1 = (JMImageCacheFileData *)obj1;
        JMImageCacheFileData *fileData2 = (JMImageCacheFileData *)obj2;
        
        return [fileData1.creationDate compare:fileData2.creationDate];
    };
    
    return [filesInCacheDirectory sortedArrayUsingComparator:sortByDate];
}

- (void) _downloadAndWriteImageForURL:(NSURL *)url key:(NSString *)key completionBlock:(void (^)(UIImage *image))completion {
    if (!key && !url) return;

    if (!key) {
        key = keyForURL(url);
    }

    __weak JMImageCache *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(kJSImageCacheQueuePriority, 0), ^{
        __strong JMImageCache *strongSelf = weakSelf;
        if (!strongSelf) return;
        
        NSData *data = [NSData dataWithContentsOfURL:url];
        
        UIImage *i = [strongSelf setData:data forKey:key];
        if (i)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(completion) completion(i);
            });
        }
    });
}

- (void) removeAllObjects {
    [super removeAllObjects];
    
    __weak JMImageCache *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(kJSImageCacheQueuePriority, 0), ^{
        __strong JMImageCache *strongSelf = weakSelf;
        if (!strongSelf) return;
        
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSError *error = nil;
        NSArray *directoryContents = [fileMgr contentsOfDirectoryAtPath:strongSelf.imageCacheDirectory error:&error];

        if (error == nil) {
            for (NSString *path in directoryContents) {
                NSString *fullPath = [strongSelf.imageCacheDirectory stringByAppendingPathComponent:path];

                BOOL removeSuccess = [fileMgr removeItemAtPath:fullPath error:&error];
                if (!removeSuccess) {
                    //Error Occured
                }
            }
        } else {
            //Error Occured
        }
    });
}
- (void) removeObjectForKey:(id)key {
    [super removeObjectForKey:key];
    
    __weak JMImageCache *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(kJSImageCacheQueuePriority, 0), ^{
        __strong JMImageCache *strongSelf = weakSelf;
        if (!strongSelf) return;
        
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSString *cachePath = [strongSelf _cachePathForKey:key];

        NSError *error = nil;

        BOOL removeSuccess = [fileMgr removeItemAtPath:cachePath error:&error];
        if (!removeSuccess) {
            //Error Occured
        }
    });
}

#pragma mark -
#pragma mark Getter Methods

- (void) imageForURL:(NSURL *)url key:(NSString *)key completionBlock:(void (^)(UIImage *image))completion {

	UIImage *i = [self cachedImageForKey:key];

	if(i) {
		if(completion) completion(i);
	} else {
        [self _downloadAndWriteImageForURL:url key:key completionBlock:completion];
    }
}

- (void) imageForURL:(NSURL *)url completionBlock:(void (^)(UIImage *image))completion {
    [self imageForURL:url key:keyForURL(url) completionBlock:completion];
}

- (UIImage *) cachedImageForKey:(NSString *)key {
    if(!key) return nil;

	id returner = [super objectForKey:key];

	if(returner) {
        return returner;
	} else {
        NSUInteger bytes = 0;
        UIImage *i = [self imageFromDiskForKey:key bytesSize:&bytes];
        if(i) [self setImage:i forKey:key bytesSize:bytes];

        return i;
    }

    return nil;
}

- (UIImage *) cachedImageForURL:(NSURL *)url {
    NSString *key = keyForURL(url);
    return [self cachedImageForKey:key];
}

- (UIImage *) imageForURL:(NSURL *)url key:(NSString*)key delegate:(id<JMImageCacheDelegate>)d {
	if(!url) return nil;

	UIImage *i = [self cachedImageForURL:url];

	if(i) {
		return i;
	} else {
        
        __weak JMImageCache *weakSelf = self;
        [self _downloadAndWriteImageForURL:url key:key completionBlock:^(UIImage *image) {
            __strong JMImageCache *strongSelf = weakSelf;
            if (!strongSelf) return;
            
            if(d) {
                if([d respondsToSelector:@selector(cache:didDownloadImage:forURL:)]) {
                    [d cache:strongSelf didDownloadImage:image forURL:url];
                }
                if([d respondsToSelector:@selector(cache:didDownloadImage:forURL:key:)]) {
                    [d cache:strongSelf didDownloadImage:image forURL:url key:key];
                }
            }
        }];
    }

    return nil;
}

- (UIImage *) imageForURL:(NSURL *)url delegate:(id<JMImageCacheDelegate>)d {
    return [self imageForURL:url key:keyForURL(url) delegate:d];
}

- (UIImage *) imageFromDiskForKey:(NSString *)key {
    NSUInteger bytesSize = 0;
    
    return [self imageFromDiskForKey:key bytesSize:&bytesSize];
}

- (UIImage *) imageFromDiskForKey:(NSString *)key bytesSize:(NSUInteger *)bytesSize
{
    NSData *imageData = [NSData dataWithContentsOfFile:[self _cachePathForKey:key] options:0 error:NULL];
    if (!imageData)
    {
        *bytesSize = 0;
        return nil;
    }
    
    *bytesSize = [imageData length];
	return [[UIImage alloc] initWithData:imageData];
}

- (UIImage *) imageFromDiskForURL:(NSURL *)url {
    return [self imageFromDiskForKey:keyForURL(url)];
}

#pragma mark -
#pragma mark Setter Methods

- (void) setImage:(UIImage *)i forKey:(NSString *)key bytesSize:(NSUInteger)bytesSize
{
    if (i) {
        if (self.informCost)
        {
            [super setObject:i forKey:key cost:bytesSize];
        }
        else
        {
            [super setObject:i forKey:key];
        }
    }
}

- (void) setImage:(UIImage *)i forURL:(NSURL *)url bytesSize:(NSUInteger)bytesSize
{
    [self setImage:i forKey:keyForURL(url) bytesSize:bytesSize];
}

- (void) removeImageForKey:(NSString *)key {
	[self removeObjectForKey:key];
}
- (void) removeImageForURL:(NSURL *)url {
    [self removeImageForKey:keyForURL(url)];
}
- (UIImage *) setData:(NSData *)data forKey:(NSString *)key
{
    UIImage *i = nil;
    
    if (data)
    {
        i = [UIImage imageWithData:data];
        // stop process if the method could not initialize the image from the specified data
        if (!i) return nil;
        
        if (!self.memoryOnlyCache) {
            NSString *cachePath = [self _cachePathForKey:key];
            NSInvocation *writeInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(writeData:toPath:)]];
            
            [writeInvocation setTarget:self];
            [writeInvocation setSelector:@selector(writeData:toPath:)];
            [writeInvocation setArgument:&data atIndex:2];
            [writeInvocation setArgument:&cachePath atIndex:3];
            
            [self performDiskWriteOperation:writeInvocation];
        }
        
        [self setImage:i forKey:key bytesSize:[data length]];
    }
    
    return i;
}
- (UIImage *) setData:(NSData *)data forURL:(NSURL *)url
{
    return [self setData:data forKey:keyForURL(url)];
}

#pragma mark -
#pragma mark Disk Writing Operations

- (void) writeData:(NSData*)data toPath:(NSString *)path {
	[data writeToFile:path atomically:YES];
}
- (void) performDiskWriteOperation:(NSInvocation *)invoction {
	NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithInvocation:invoction];
    
	[self.diskOperationQueue addOperation:operation];
}

#pragma mark -
#pragma mark Limit cache size

- (void) removeImagesFromMemory
{
    [super removeAllObjects];
}

- (void) adjustCacheSizeTo:(unsigned long long)bytesSize {
    [self adjustCacheSizeBetweenMin:bytesSize max:bytesSize];
}

- (void) adjustCacheSizeBetweenMin:(unsigned long long)minBytesSize max:(unsigned long long)maxBytesSize {
    if (maxBytesSize == 0) return;
    
    unsigned long long minSize = (minBytesSize > maxBytesSize ? maxBytesSize : minBytesSize);
    
    __weak JMImageCache *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(kJSImageCacheQueuePriority, 0), ^{
        __strong JMImageCache *strongSelf = weakSelf;
        if (!strongSelf) return;
        
        unsigned long long totalSize = 0;
        NSArray *fileDatasInCacheDirectory = [strongSelf _fileDatasInImageCacheDirectory:&totalSize];
        
        if (!fileDatasInCacheDirectory) return;
        
        if (totalSize < maxBytesSize) return;
        
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        for (JMImageCacheFileData *fileData in fileDatasInCacheDirectory) {
            NSError *error = nil;
            
            BOOL removeSuccess = [fileMgr removeItemAtPath:fileData.cachePath error:&error];
            if (removeSuccess) {
                totalSize -= fileData.fileSize;
            }
            
            if (totalSize <= minSize) break;
        }
    });
}

@end