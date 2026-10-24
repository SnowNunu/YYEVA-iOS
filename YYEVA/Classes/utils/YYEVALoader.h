//
//  YYEVALoader.h
//  YYEVA
//
//  Created by Mandora on 1/6/26.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^YYEVALoaderCompletionBlock)(NSString * _Nullable filePath, NSError * _Nullable error);
typedef void(^YYEVALoaderImageCompletionBlock)(UIImage * _Nullable image, NSString * _Nullable filePath, NSError * _Nullable error);

@interface YYEVALoader : NSObject

+ (instancetype)sharedLoader;

/**
 加载视频（查缓存或下载）
 
 @param urlStr 在线视频URL
 @param completion 回调本地路径
 */
- (void)loadVideoWithUrl:(NSString *)urlStr completion:(YYEVALoaderCompletionBlock)completion;

/**
 加载在线图片（优先读取本地磁盘缓存，无缓存则异步下载并缓存）
 
 @param urlStr 在线图片URL
 @param completion 回调 UIImage、本地路径与错误
 */
- (void)loadImageWithUrl:(NSString *)urlStr completion:(YYEVALoaderImageCompletionBlock)completion;

/**
 获取本地已缓存的图片（若未缓存则返回 nil）
 */
- (nullable UIImage *)cachedImageForUrl:(NSString *)urlStr;

/** 清理缓存 */
- (void)clearCache;

@end

NS_ASSUME_NONNULL_END
