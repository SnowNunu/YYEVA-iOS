//
//  YYEVAPlayer+WebCache.h
//  YYEVA
//
//  Created by Mandora on 1/6/26.
//

#import "YYEVAPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface YYEVAPlayer (WebCache)

/**
 播放网络 YYEVA 视频
 
 @param urlStr 在线视频地址 (http/https)
 */
- (void)playWithUrl:(NSString *)urlStr;

/**
 播放网络 YYEVA 视频（带完成回调）
 
 @param urlStr 在线视频地址
 @param completion 播放开始后的回调 (isSuccess)
 */
- (void)playWithUrl:(NSString *)urlStr completion:(void (^ _Nullable)(BOOL isSuccess))completion;

@end

NS_ASSUME_NONNULL_END
