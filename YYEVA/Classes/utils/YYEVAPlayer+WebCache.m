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

- (void)playWithUrl:(NSString *)urlStr {
    [self playWithUrl:urlStr completion:nil];
}

- (void)playWithUrl:(NSString *)urlStr completion:(void (^)(BOOL))completion {
    self.currentLoadURL = urlStr;
    
    // 停止当前正在播放的动画 (可选，视需求而定)
    [self stopAnimation];
    
    // 如果 URL 为空，直接返回
    if (!urlStr || urlStr.length == 0) {
        if (completion) completion(NO);
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    // 调用 Loader 进行加载
    [[YYEVALoader sharedLoader] loadVideoWithUrl:urlStr completion:^(NSString * _Nullable filePath, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        // ⭐️ 核心校验：
        // 下载完成时，检查这个 View 的 currentURL 是否还等于当初请求的 URL。
        // 如果不相等，说明 View 在下载期间被复用给了其他数据，这个结果必须丢弃！
        if (![strongSelf.currentLoadURL isEqualToString:urlStr]) {
            // NSLog(@"[YYEVA] URL mismatch, ignore result.");
            return;
        }
        
        if (filePath && !error) {
            // 调用原生的本地播放方法
            [strongSelf play:filePath];
            if (completion) completion(YES);
        } else {
            // NSLog(@"[YYEVA] Load failed: %@", error);
            if (completion) completion(NO);
        }
    }];
}

@end
