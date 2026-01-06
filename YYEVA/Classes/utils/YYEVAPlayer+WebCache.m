//
//  YYEVAPlayer+WebCache.m
//  YYEVA
//
//  Created by Mandora on 1/6/26.
//

#import "YYEVAPlayer+WebCache.h"
#import "YYEVALoader.h"
#import <objc/runtime.h>

static char kYYEVACurrentURLKey;

@implementation YYEVAPlayer (WebCache)

#pragma mark - Properties

- (NSString *)currentLoadURL {
    return objc_getAssociatedObject(self, &kYYEVACurrentURLKey);
}

- (void)setCurrentLoadURL:(NSString *)url {
    objc_setAssociatedObject(self, &kYYEVACurrentURLKey, url, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark - Methods

// 1. 默认方法：转发给全能方法，默认 repeatCount = 0 (无限循环)
- (void)playWithUrl:(NSString *)urlStr {
    [self playWithUrl:urlStr repeatCount:0 completion:nil];
}

// 2. 带回调方法：默认 repeatCount = 0
- (void)playWithUrl:(NSString *)urlStr completion:(void (^)(BOOL))completion {
    [self playWithUrl:urlStr repeatCount:0 completion:completion];
}

// 3. 指定次数方法：不带回调
- (void)playWithUrl:(NSString *)urlStr repeatCount:(NSInteger)repeatCount {
    [self playWithUrl:urlStr repeatCount:repeatCount completion:nil];
}

// 4. ⭐️ 全能主方法
- (void)playWithUrl:(NSString *)urlStr repeatCount:(NSInteger)repeatCount completion:(void (^)(BOOL))completion {
    
    // 记录当前 URL，处理复用
    self.currentLoadURL = urlStr;
    
    // 停止旧动画
    [self stopAnimation];
    
    // 校验空 URL
    if (!urlStr || urlStr.length == 0) {
        if (completion) completion(NO);
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    // 调用 Loader 下载
    [[YYEVALoader sharedLoader] loadVideoWithUrl:urlStr completion:^(NSString * _Nullable filePath, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        // 校验 URL 是否匹配 (防止 Cell 复用错乱)
        if (![strongSelf.currentLoadURL isEqualToString:urlStr]) {
            return;
        }
        
        if (filePath && !error) {
            // ⭐️ 核心修改点：调用带 repeatCount 的原生播放方法
            [strongSelf play:filePath repeatCount:repeatCount];
            
            if (completion) completion(YES);
        } else {
            // 下载失败
            if (completion) completion(NO);
        }
    }];
}

@end
