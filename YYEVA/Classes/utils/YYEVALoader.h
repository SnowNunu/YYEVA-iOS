//
//  YYEVALoader.h
//  YYEVA
//
//  Created by Mandora on 1/6/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^YYEVALoaderCompletionBlock)(NSString * _Nullable filePath, NSError * _Nullable error);

@interface YYEVALoader : NSObject

+ (instancetype)sharedLoader;

/**
 加载视频（查缓存或下载）
 
 @param urlStr 在线视频URL
 @param completion 回调本地路径
 */
- (void)loadVideoWithUrl:(NSString *)urlStr completion:(YYEVALoaderCompletionBlock)completion;

/** 清理缓存 */
- (void)clearCache;

@end

NS_ASSUME_NONNULL_END
