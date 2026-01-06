//
//  YYEVAPlayer+WebCache.h
//  YYEVA
//
//  Created by Mandora on 1/6/26.
//

#import "YYEVAPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface YYEVAPlayer (WebCache)

/// 播放网络视频 (默认无限循环: repeatCount = 0)
- (void)playWithUrl:(NSString *)urlStr;

/// 播放网络视频 + 完成回调 (默认无限循环)
- (void)playWithUrl:(NSString *)urlStr completion:(void (^ _Nullable)(BOOL isSuccess))completion;

/**
 播放网络视频 + 指定次数
 
 @param urlStr 视频地址
 @param repeatCount 播放次数 (0 表示无限循环，1 表示播放一次)
 */
- (void)playWithUrl:(NSString *)urlStr repeatCount:(NSInteger)repeatCount;

/**
 播放网络视频 + 指定次数 + 完成回调 (全能方法)
 
 @param urlStr 视频地址
 @param repeatCount 播放次数 (0 表示无限循环)
 @param completion 播放开始后的回调
 */
- (void)playWithUrl:(NSString *)urlStr repeatCount:(NSInteger)repeatCount completion:(void (^ _Nullable)(BOOL isSuccess))completion;

@end

NS_ASSUME_NONNULL_END
