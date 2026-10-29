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
    
    // 收集所有需要预先加载的网络图片
    NSMutableDictionary<NSString *, NSString *> *pendingImages = [NSMutableDictionary dictionary];
    if (self.imgUrlKeys.count > 0) {
        [self.imgUrlKeys enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSString class]]) {
                NSString *url = (NSString *)obj;
                if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) {
                    [pendingImages setObject:url forKey:key];
                }
            }
        }];
    }
    
    dispatch_group_t group = dispatch_group_create();
    
    __block NSString *videoFilePath = nil;
    __block NSError *videoError = nil;
    NSMutableDictionary<NSString *, UIImage *> *downloadedImages = [NSMutableDictionary dictionary];
    
    // 1. 异步加载视频
    dispatch_group_enter(group);
    [[YYEVALoader sharedLoader] loadVideoWithUrl:urlStr completion:^(NSString * _Nullable filePath, NSError * _Nullable error) {
        videoFilePath = filePath;
        videoError = error;
        dispatch_group_leave(group);
    }];
    
    // 2. 并行预加载所有网络图片，确保第一帧渲染时头像已就绪
    [pendingImages enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull imgUrl, BOOL * _Nonnull stop) {
        dispatch_group_enter(group);
        [[YYEVALoader sharedLoader] loadImageWithUrl:imgUrl completion:^(UIImage * _Nullable image, NSString * _Nullable filePath, NSError * _Nullable error) {
            if (image) {
                @synchronized (downloadedImages) {
                    downloadedImages[key] = image;
                }
            }
            dispatch_group_leave(group);
        }];
    }];
    
    // 3. 视频和图片全部准备好后统一开始播放
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        // 校验 URL 是否匹配 (防止 Cell 复用错乱)
        if (![strongSelf.currentLoadURL isEqualToString:urlStr]) {
            return;
        }
        
        // 将预加载好的图片更新到 imgUrlKeys
        [downloadedImages enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, UIImage * _Nonnull image, BOOL * _Nonnull stop) {
            if (key && image) {
                [strongSelf.imgUrlKeys setObject:image forKey:key];
            }
        }];
        
        if (videoFilePath && !videoError) {
            // 调用带 repeatCount 的原生播放方法
            [strongSelf play:videoFilePath repeatCount:repeatCount];
            if (completion) completion(YES);
        } else {
            // 下载失败
            if (completion) completion(NO);
        }
    });
}

@end
