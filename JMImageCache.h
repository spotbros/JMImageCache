//
//  JMImageCache.h
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Jake Marsh. All rights reserved.
//

@class JMImageCache;

@protocol JMImageCacheDelegate <NSObject>

@optional
- (void) cache:(JMImageCache *)c didDownloadImage:(UIImage *)i forURL:(NSURL *)url;
- (void) cache:(JMImageCache *)c didDownloadImage:(UIImage *)i forURL:(NSURL *)url key:(NSString*)key;

@end

@interface JMImageCache : NSCache

// Global cache for easy use. Located in 'Library/Caches/JMCache'
+ (JMImageCache *) sharedCache;

// Opitionally create a different JMImageCache instance with it's own cache directory
- (id) initWithCacheDirectory:(NSString*)cacheDirectory;

- (void) imageForURL:(NSURL *)url key:(NSString *)key completionBlock:(void (^)(UIImage *image))completion;
- (void) imageForURL:(NSURL *)url completionBlock:(void (^)(UIImage *image))completion;

- (UIImage *) cachedImageForKey:(NSString *)key;
- (UIImage *) cachedImageForURL:(NSURL *)url;

- (UIImage *) imageForURL:(NSURL *)url key:(NSString*)key delegate:(id<JMImageCacheDelegate>)d;
- (UIImage *) imageForURL:(NSURL *)url delegate:(id<JMImageCacheDelegate>)d;

- (UIImage *) imageFromDiskForKey:(NSString *)key;
- (UIImage *) imageFromDiskForURL:(NSURL *)url;

- (void) setImage:(UIImage *)i forKey:(NSString *)key;
- (void) setImage:(UIImage *)i forURL:(NSURL *)url;
- (void) removeImageForKey:(NSString *)key;
- (void) removeImageForURL:(NSString *)url;

- (UIImage *) setData:(NSData *)data forKey:(NSString *)key;
- (UIImage *) setData:(NSData *)data forURL:(NSURL *)url;

- (void) writeData:(NSData *)data toPath:(NSString *)path;
- (void) performDiskWriteOperation:(NSInvocation *)invoction;

- (void) adjustCacheSizeTo:(unsigned long long)bytesSize;
- (void) adjustCacheSizeBetweenMin:(unsigned long long)minBytesSize max:(unsigned long long)maxBytesSize;

@end
