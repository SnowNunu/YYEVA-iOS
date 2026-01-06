//
//  YYEVALoader.m
//  YYEVA
//
//  Created by Mandora on 1/6/26.
//

#import "YYEVALoader.h"
#import "NSString+YYEVAMD5.h"

@interface YYEVALoader()
@property (nonatomic, strong) NSString *cacheDirectory;
@property (nonatomic, strong) NSURLSession *session;

// 核心改进 1: 存储 URL 对应的所有回调 block 数组
// Key: URL MD5, Value: NSMutableArray<CompletionBlock>
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *callbacksDictionary;

// 核心改进 2: 下载任务映射表 (可选，用于支持取消操作)
// Key: URL MD5, Value: NSURLSessionDownloadTask
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURLSessionDownloadTask *> *downloadTasks;

@end

@implementation YYEVALoader

+ (instancetype)sharedLoader {
    static YYEVALoader *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[YYEVALoader alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // ... (路径初始化代码同上) ...
        // 初始化路径...
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        _cacheDirectory = [cachePath stringByAppendingPathComponent:@"YYEVACache"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_cacheDirectory]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:_cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config];
        
        // 初始化容器
        _callbacksDictionary = [NSMutableDictionary dictionary];
        _downloadTasks = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)loadVideoWithUrl:(NSString *)urlStr completion:(YYEVALoaderCompletionBlock)completion {
    if (!urlStr || urlStr.length == 0) {
        if (completion) completion(nil, [NSError errorWithDomain:@"YYEVALoader" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"URL为空"}]);
        return;
    }
    
    NSString *key = [urlStr yyeva_md5String];
    NSString *fileName = [NSString stringWithFormat:@"%@.mp4", key];
    NSString *filePath = [self.cacheDirectory stringByAppendingPathComponent:fileName];
    
    // 1. 查缓存
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(filePath, nil);
        });
        return;
    }
    
    // 2. 核心并发控制：使用 @synchronized 锁住字典
    @synchronized (self.callbacksDictionary) {
        
        // 获取该 URL 当前挂起的回调数组
        NSMutableArray *callbacks = self.callbacksDictionary[key];
        
        if (callbacks) {
            // [情况 A]: 任务已经在运行中
            // 只需要把新的 completion 加到数组里，不需要发新请求
            // NSLog(@"[YYEVA] Request Merged: %@", urlStr);
            if (completion) {
                [callbacks addObject:[completion copy]];
            }
            return;
        } else {
            // [情况 B]: 这是一个新任务
            // 创建数组，并把自己加进去
            callbacks = [NSMutableArray array];
            if (completion) {
                [callbacks addObject:[completion copy]];
            }
            self.callbacksDictionary[key] = callbacks;
        }
    }
    
    // 3. 发起下载
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    __weak typeof(self) weakSelf = self;
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        // 准备结果
        NSString *finalPath = nil;
        NSError *finalError = error;
        
        // 如果下载成功，移动文件
        if (!error && location) {
            NSError *moveError = nil;
            NSURL *destinationURL = [NSURL fileURLWithPath:filePath];
            
            // 安全移除旧文件
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            }
            
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:destinationURL error:&moveError];
            
            if (!moveError) {
                finalPath = filePath;
            } else {
                finalError = moveError;
            }
        }
        
        // 4. 处理回调 (在主线程分发给所有等待者)
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableArray *callbacks = nil;
            
            // 加锁读取并移除回调数组
            @synchronized (strongSelf.callbacksDictionary) {
                callbacks = strongSelf.callbacksDictionary[key];
                [strongSelf.callbacksDictionary removeObjectForKey:key];
                [strongSelf.downloadTasks removeObjectForKey:key]; // 任务结束，移除 Task
            }
            
            // 遍历执行所有回调
            for (YYEVALoaderCompletionBlock block in callbacks) {
                block(finalPath, finalError);
            }
        });
    }];
    
    // 记录 Task (可选，用于取消)
    @synchronized (self.downloadTasks) {
        self.downloadTasks[key] = task;
    }
    
    [task resume];
}

- (void)clearCache {
    [[NSFileManager defaultManager] removeItemAtPath:self.cacheDirectory error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
}

@end
