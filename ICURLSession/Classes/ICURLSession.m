//
//  ICURLSession.m
//  ICURLSession
//
//  Created by _ivanC on 26/10/2016.
//  Copyright © 2016 _ivanC. All rights reserved.
//

#import "ICURLSession.h"
#import "ICURLSession+TaskDelegate.h"
#import "ICURLSessionInternal.h"

@implementation ICURLSession

#pragma mark - Lifecycle
+ (instancetype)sharedSession
{
    static __strong ICURLSession *s_instance = nil;
    
    if (s_instance == nil)
    {
        @synchronized(self)
        {
            if (s_instance == nil)
            {
                s_instance = [ICURLSession new];
            }
        }
    }
    
    return s_instance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.sessionQueue = [[NSOperationQueue alloc] init];
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                     delegate:self
                                                delegateQueue:self.sessionQueue];
    }
    return self;
}

- (instancetype)initWithSessionDelegate:(id<NSURLSessionDelegate>)sessionDelegate
{
    if (self = [super init])
    {
        self.sessionDelegate = sessionDelegate;
        self.sessionQueue = [[NSOperationQueue alloc] init];
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                     delegate:sessionDelegate
                                                delegateQueue:self.sessionQueue];
    }
    return self;
}


- (NSMutableDictionary *)allTasksHash
{
    if (_allTasksHash == nil)
    {
        _allTasksHash = [[NSMutableDictionary alloc] initWithCapacity:7];
    }
    
    return _allTasksHash;
}

- (NSMutableDictionary *)allNamespaceTasks
{
    if (_allNamespaceTasks == nil)
    {
        _allNamespaceTasks = [[NSMutableDictionary alloc] initWithCapacity:7];
    }
    
    return _allNamespaceTasks;
}

- (NSMutableDictionary *)allTasksMap
{
    if (_allTasksMap == nil)
    {
        _allTasksMap = [[NSMutableDictionary alloc] initWithCapacity:7];
    }
    
    return _allTasksMap;
}

#pragma mark - Public
- (void)finishTasksAndInvalidate
{
    [self.session finishTasksAndInvalidate];
    self.session = nil;
    self.sessionQueue = nil;
}

#pragma mark Block-task-create
- (NSURLSessionTask *)checkIfTaskExist:(NSString *)URLString inNamespace:(NSString *)namespaceStr
{
    ICURLSessionTask *icSessionTask = [self taskForURLString:URLString];
    
    NSURLSessionTask *sessionTask = icSessionTask.task;
    if ([sessionTask state] == NSURLSessionTaskStateCanceling || [sessionTask state] == NSURLSessionTaskStateCompleted) {
        
        [self removeTask:icSessionTask inNamespace:namespaceStr];
        [self removeTask:icSessionTask forURLString:URLString];
        
        sessionTask = nil;
    }
    
    return sessionTask;
}
- (NSURLSessionTask *)startDataTaskWithRequest:(NSURLRequest *)request
                                   inNamespace:(NSString *)namespaceStr
                                succeedHandler:(void (^)(NSURLResponse *response, NSData *data))succeedHandler
                                   failHandler:(void (^)(NSURLResponse *response, NSError *error))failHandler
{
    NSString *URLString = request.URL.absoluteString;
    if ([URLString length] <= 0)
    {
        return nil;
    }
    
    __block NSURLSessionTask *sessionTask = [self checkIfTaskExist:URLString inNamespace:namespaceStr];
    if (sessionTask == nil)
    {
        sessionTask = [self.session dataTaskWithRequest:request];
        
        ICURLSessionTask *icTask = [ICURLSessionTask new];
        icTask.taskNamespace = namespaceStr;
        icTask.originalURL = URLString;
        icTask.successBlock = succeedHandler;
        icTask.failBlock = failHandler;
        icTask.task = sessionTask;

        [self addTask:icTask forURLString:URLString];
        [self addTask:icTask inNamespace:namespaceStr];
        
        [sessionTask resume];
    }
    
    return sessionTask;
}

- (NSURLSessionTask *)startDownloadTaskWithRequest:(NSURLRequest *)request
                                       inNamespace:(NSString *)namespaceStr
                                   progressHandler:(void (^)(int64_t currentBytes, int64_t totalBytes))progressHandler
                                    downloadFinishHandler:(void (^)(NSURLResponse *response, NSURL *dataLocation))downloadFinishHandler
                                       failHandler:(void (^)(NSURLResponse *response, NSError *error))failHandler

{
    NSString *URLString = request.URL.absoluteString;
    if ([URLString length] <= 0)
    {
        return nil;
    }
    
    __block NSURLSessionTask *sessionTask = [self checkIfTaskExist:URLString inNamespace:namespaceStr];
    if (sessionTask == nil)
    {
        sessionTask = [self.session downloadTaskWithRequest:request];

        ICURLSessionTask *icTask = [ICURLSessionTask new];
        icTask.taskNamespace = namespaceStr;
        icTask.originalURL = URLString;
        icTask.progressBlock = progressHandler;
        icTask.downloadFinishBlock = downloadFinishHandler;
        icTask.failBlock = failHandler;
        icTask.task = sessionTask;
        
        [self addTask:icTask forURLString:URLString];
        [self addTask:icTask inNamespace:namespaceStr];
        
        [sessionTask resume];
    }
    
    return sessionTask;
}

- (NSURLSessionTask *)startUploadTaskWithRequest:(NSURLRequest *)request
                                        fromData:(NSData *)data
                                     inNamespace:(NSString *)namespaceStr
                                 progressHandler:(void (^)(int64_t currentBytes, int64_t totalBytes))progressHandler
                                  succeedHandler:(void (^)(NSURLResponse *response, NSData *data))succeedHandler
                                     failHandler:(void (^)(NSURLResponse *response, NSError *error))failHandler

{
    if ([data length] <= 0)
    {
        return nil;
    }
    
    NSString *URLString = request.URL.absoluteString;
    if ([URLString length] <= 0)
    {
        return nil;
    }
    
    __block NSURLSessionTask *sessionTask = [self checkIfTaskExist:URLString inNamespace:namespaceStr];
    if (sessionTask == nil)
    {
        sessionTask = [self.session uploadTaskWithRequest:request fromData:data];

        ICURLSessionTask *icTask = [ICURLSessionTask new];
        icTask.taskNamespace = namespaceStr;
        icTask.originalURL = URLString;
        icTask.progressBlock = progressHandler;
        icTask.successBlock = succeedHandler;
        icTask.failBlock = failHandler;
        icTask.task = sessionTask;
        icTask.data = data;
        
        [self addTask:icTask forURLString:URLString];
        [self addTask:icTask inNamespace:namespaceStr];
        
        [sessionTask resume];
    }
    
    return sessionTask;
}

- (NSURLSessionTask *)startUploadTaskWithRequest:(NSURLRequest *)request
                                        fromFile:(NSURL *)fileURL
                                     inNamespace:(NSString *)namespaceStr
                                 progressHandler:(void (^)(int64_t currentBytes, int64_t totalBytes))progressHandler
                                  succeedHandler:(void (^)(NSURLResponse *response, NSData *data))succeedHandler
                                     failHandler:(void (^)(NSURLResponse *response, NSError *error))failHandler

{
    if ([fileURL.absoluteString length] <= 0)
    {
        return nil;
    }
    
    NSString *URLString = request.URL.absoluteString;
    if ([URLString length] <= 0)
    {
        return nil;
    }
    
    __block NSURLSessionTask *sessionTask = [self checkIfTaskExist:URLString inNamespace:namespaceStr];
    if (sessionTask == nil)
    {
        sessionTask = [self.session uploadTaskWithRequest:request fromFile:fileURL];

        ICURLSessionTask *icTask = [ICURLSessionTask new];
        icTask.taskNamespace = namespaceStr;
        icTask.originalURL = URLString;
        icTask.progressBlock = progressHandler;
        icTask.successBlock = succeedHandler;
        icTask.failBlock = failHandler;
        icTask.task = sessionTask;
        icTask.dataLocation = fileURL;
        
        [self addTask:icTask forURLString:URLString];
        [self addTask:icTask inNamespace:namespaceStr];
        
        
        [sessionTask resume];
    }
    
    return sessionTask;
}

//#pragma mark - Delegate-task-create
//- (NSURLSessionDataTask *)startDataTaskWithRequest:(NSURLRequest *)request inNamespace:(NSString *)namespaceStr
//{
//    NSURLSessionDataTask *sessionTask = [self.session dataTaskWithRequest:request];
//    [sessionTask resume];
//    
//    NSString *URLString = [[request URL] absoluteString];
//    
//    [self addTask:sessionTask forURLString:URLString];
//    [self addTask:sessionTask inNamespace:namespaceStr];
//    
//    return sessionTask;
//}
//
//- (NSURLSessionUploadTask *)startUploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL inNamespace:(NSString *)namespaceStr
//{
//    NSURLSessionUploadTask *sessionTask = [self.session uploadTaskWithRequest:request fromFile:fileURL];
//    [sessionTask resume];
//    
//    NSString *URLString = [[request URL] absoluteString];
//    
//    [self addTask:sessionTask forURLString:URLString];
//    [self addTask:sessionTask inNamespace:namespaceStr];
//    
//    return sessionTask;
//}
//
//- (NSURLSessionUploadTask *)startUploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData inNamespace:(NSString *)namespaceStr
//{
//    NSURLSessionUploadTask *sessionTask = [self.session uploadTaskWithRequest:request fromData:bodyData];
//    [sessionTask resume];
//    
//    NSString *URLString = [[request URL] absoluteString];
//    
//    [self addTask:sessionTask forURLString:URLString];
//    [self addTask:sessionTask inNamespace:namespaceStr];
//    
//    return sessionTask;
//}
//
//- (NSURLSessionDownloadTask *)startDownloadTaskWithRequest:(NSURLRequest *)request inNamespace:(NSString *)namespaceStr
//{
//    NSURLSessionDownloadTask *sessionTask = [self.session downloadTaskWithRequest:request];
//    [sessionTask resume];
//    
//    NSString *URLString = [[request URL] absoluteString];
//    
//    [self addTask:sessionTask forURLString:URLString];
//    [self addTask:sessionTask inNamespace:namespaceStr];
//    
//    return sessionTask;
//}

#pragma mark Cancel
- (void)cancelTaskForIdentifier:(NSUInteger)identifier
{
    @synchronized (self)
    {
        __block ICURLSessionTask *targetTask = nil;
        __block NSString *targetTaskKey = nil;
        
        [self.allTasksHash enumerateKeysAndObjectsUsingBlock:^(NSString *key, ICURLSessionTask *task, BOOL *stop) {
            
            if (task.task.taskIdentifier == identifier)
            {
                targetTask = task;
                targetTaskKey = key;
                *stop = YES;
            }
        }];
        
        if (targetTask && targetTaskKey)
        {
            [targetTask.task cancel];
            
            [self.allTasksHash removeObjectForKey:targetTaskKey];
            
            
            [self.allNamespaceTasks enumerateKeysAndObjectsUsingBlock:^(NSString *namespaceStr, NSArray  *taskArray, BOOL *dStop)
            {
                __block ICURLSessionTask *foundTask = nil;
                [taskArray enumerateObjectsUsingBlock:^(ICURLSessionTask *task, NSUInteger idx, BOOL *aStop)
                 {
                     if (task.task.taskIdentifier == identifier)
                     {
                         foundTask = task;
                         *aStop = YES;
                     }
                 }];
                
                if (foundTask)
                {
                    NSMutableArray *nTaskArray = [taskArray mutableCopy];
                    if (nTaskArray)
                    {
                        [nTaskArray removeObject:foundTask];
                        self.allNamespaceTasks[namespaceStr] = nTaskArray;
                        *dStop = YES;
                    }
                }
            }];
        }
    }
}

- (void)cancelTaskForURLString:(NSString *)URLString
{
    ICURLSessionTask *sessionTask = [self taskForURLString:URLString];
    if (sessionTask)
    {
        [self removeTask:sessionTask forURLString:URLString];

        [sessionTask.task cancel];
    }
}

- (void)cancelTasksInNamespace:(NSString *)namespaceStr
{
    [self removeAllTasksInNamespace:namespaceStr];

    NSArray *nTasks = [self tasksForNamespace:namespaceStr];
    for (ICURLSessionTask *sessionTask in nTasks)
    {
        NSString *URLString = sessionTask.originalURL;
        [self removeTask:sessionTask forURLString:URLString];

        [sessionTask.task cancel];
    }
}

#pragma mark - Private
#pragma mark Task Hash
- (ICURLSessionTask *)taskForURLString:(NSString *)URLString
{
    if ([URLString length] <= 0)
    {
        return nil;
    }
    
    @synchronized (self)
    {
        return self.allTasksHash[URLString];
    }
}

- (void)removeTask:(ICURLSessionTask *)task forURLString:(NSString *)forURLString
{
    if (task == nil || [forURLString length] <= 0)
    {
        return;
    }
    
    @synchronized (self)
    {
        [self.allTasksHash removeObjectForKey:forURLString];
    }
}

- (void)addTask:(ICURLSessionTask *)task forURLString:(NSString *)URLString
{
    if (task == nil || [URLString length] <= 0)
    {
        return;
    }
    
    @synchronized (self)
    {
        self.allTasksHash[URLString] = task;
    }
}

#pragma mark Task Namspace
- (NSArray *)tasksForNamespace:(NSString *)namespaceStr
{
    if ([namespaceStr length] <= 0)
    {
        return nil;
    }
    
    @synchronized (self)
    {
        return self.allNamespaceTasks[namespaceStr];
    }
}


- (void)removeAllTasksInNamespace:(NSString *)namespaceStr
{
    if ([namespaceStr length] <= 0)
    {
        return;
    }
    
    @synchronized (self)
    {
        [self.allNamespaceTasks removeObjectForKey:namespaceStr];
    }
}

- (void)removeTask:(ICURLSessionTask *)task inNamespace:(NSString *)namespaceStr
{
    if (task == nil || [namespaceStr length] <= 0)
    {
        return;
    }
    
    @synchronized (self)
    {
        
        NSMutableArray *nTaskArray = [self.allNamespaceTasks[namespaceStr] mutableCopy];
        if (nTaskArray)
        {
            [nTaskArray removeObject:task];
            self.allNamespaceTasks[namespaceStr] = nTaskArray;
        }
    }
}

- (void)addTask:(ICURLSessionTask *)task inNamespace:(NSString *)namespaceStr
{
    if (task == nil || [namespaceStr length] <= 0)
    {
        return;
    }
    
    @synchronized (self)
    {
        NSMutableArray *nTaskArray = [self.allNamespaceTasks[namespaceStr] mutableCopy];
        if (nTaskArray == nil)
        {
            nTaskArray = [NSMutableArray arrayWithCapacity:2];
        }
        
        [nTaskArray addObject:task];
        self.allNamespaceTasks[namespaceStr] = nTaskArray;
    }
}

@end
