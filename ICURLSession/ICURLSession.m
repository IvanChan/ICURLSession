//
//  ICURLSession.m
//  FoundationEx
//
//  Created by _ivanC on 26/10/2016.
//  Copyright © 2016 _ivanC. All rights reserved.
//

#import "ICURLSession.h"

@interface ICURLSession () <NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *sessionQueue;
@property (nonatomic, weak) id<NSURLSessionDelegate> sessionDelegate;

@property (nonatomic, strong) NSMutableDictionary *allTasksHash;
@property (nonatomic, strong) NSMutableDictionary *allNamespaceTasks;

@end

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
                                                     delegate:nil
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
    NSURLSessionTask *sessionTask = [self taskForURLString:URLString];
    if ([sessionTask state] == NSURLSessionTaskStateCanceling || [sessionTask state] == NSURLSessionTaskStateCompleted) {
        
        [self removeTask:sessionTask inNamespace:namespaceStr];
        [self removeTask:sessionTask forURLString:URLString];
        
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
        sessionTask = [self.session dataTaskWithRequest:request
                              completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                  
                                  [self removeTask:sessionTask inNamespace:namespaceStr];
                                  [self removeTask:sessionTask forURLString:URLString];
                                  
                                  if (error || [data length] <= 0)
                                  {
                                      if (failHandler)
                                      {
                                          if (error == nil)
                                          {
                                              error = [NSError errorWithDomain:@"NSURLSessionErrorDomain"
                                                                          code:444
                                                                      userInfo:@{NSLocalizedFailureReasonErrorKey:@"data length is 0"}];
                                          }
                                          
                                          failHandler(response, error);
                                      }
                                  }
                                  else
                                  {
                                      if (succeedHandler)
                                      {
                                          succeedHandler(response, data);
                                      }
                                  }
                              }];
        
        [self addTask:sessionTask forURLString:URLString];
        [self addTask:sessionTask inNamespace:namespaceStr];
        
        [sessionTask resume];
    }
    
    return sessionTask;
}

- (NSURLSessionTask *)startDownloadTaskWithRequest:(NSURLRequest *)request
                                       inNamespace:(NSString *)namespaceStr
                                    succeedHandler:(void (^)(NSURLResponse *response, NSURL *dataLocation))succeedHandler
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
        sessionTask = [self.session downloadTaskWithRequest:request
                                  completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                      
                                      
                                      [self removeTask:sessionTask inNamespace:namespaceStr];
                                      [self removeTask:sessionTask forURLString:URLString];
                                      
                                      if (error || !location)
                                      {
                                          if (failHandler)
                                          {
                                              if (error == nil)
                                              {
                                                  error = [NSError errorWithDomain:@"NSURLSessionErrorDomain"
                                                                              code:555
                                                                          userInfo:@{NSLocalizedFailureReasonErrorKey:@"downloaded file not exist"}];
                                              }
                                              
                                              failHandler(response, error);
                                          }
                                      }
                                      else
                                      {
                                          if (succeedHandler)
                                          {
                                              succeedHandler(response, location);
                                          }
                                      }
                                  }];
        
        [self addTask:sessionTask forURLString:URLString];
        [self addTask:sessionTask inNamespace:namespaceStr];
        
        [sessionTask resume];
    }
    
    return sessionTask;
}

- (NSURLSessionTask *)startUploadTaskWithRequest:(NSURLRequest *)request
                                        fromData:(NSData *)data
                                     inNamespace:(NSString *)namespaceStr
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
        sessionTask = [self.session uploadTaskWithRequest:request
                                         fromData:data
                                completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                    
                                    [self removeTask:sessionTask inNamespace:namespaceStr];
                                    [self removeTask:sessionTask forURLString:URLString];
                                    
                                    if (error)
                                    {
                                        if (failHandler)
                                        {
                                            failHandler(response, error);
                                        }
                                    }
                                    else
                                    {
                                        if (succeedHandler)
                                        {
                                            succeedHandler(response, data);
                                        }
                                    }
                                }];
        
        [self addTask:sessionTask forURLString:URLString];
        [self addTask:sessionTask inNamespace:namespaceStr];
        
        [sessionTask resume];
    }
    
    return sessionTask;
}

- (NSURLSessionTask *)startUploadTaskWithRequest:(NSURLRequest *)request
                                        fromFile:(NSURL *)fileURL
                                     inNamespace:(NSString *)namespaceStr
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
        sessionTask = [self.session uploadTaskWithRequest:request
                                         fromFile:fileURL
                                completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                    
                                    [self removeTask:sessionTask inNamespace:namespaceStr];
                                    [self removeTask:sessionTask forURLString:URLString];
                                    
                                    if (error)
                                    {
                                        if (failHandler)
                                        {
                                            failHandler(response, error);
                                        }
                                    }
                                    else
                                    {
                                        if (succeedHandler)
                                        {
                                            succeedHandler(response, data);
                                        }
                                    }
                                }];
        
        [self addTask:sessionTask forURLString:URLString];
        [self addTask:sessionTask inNamespace:namespaceStr];
        
        [sessionTask resume];
    }
    
    return sessionTask;
}

#pragma mark - Delegate-task-create
- (NSURLSessionDataTask *)startDataTaskWithRequest:(NSURLRequest *)request inNamespace:(NSString *)namespaceStr
{
    NSURLSessionDataTask *sessionTask = [self.session dataTaskWithRequest:request];
    [sessionTask resume];
    
    NSString *URLString = [[request URL] absoluteString];
    
    [self addTask:sessionTask forURLString:URLString];
    [self addTask:sessionTask inNamespace:namespaceStr];
    
    return sessionTask;
}

- (NSURLSessionUploadTask *)startUploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL inNamespace:(NSString *)namespaceStr
{
    NSURLSessionUploadTask *sessionTask = [self.session uploadTaskWithRequest:request fromFile:fileURL];
    [sessionTask resume];
    
    NSString *URLString = [[request URL] absoluteString];
    
    [self addTask:sessionTask forURLString:URLString];
    [self addTask:sessionTask inNamespace:namespaceStr];
    
    return sessionTask;
}

- (NSURLSessionUploadTask *)startUploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData inNamespace:(NSString *)namespaceStr
{
    NSURLSessionUploadTask *sessionTask = [self.session uploadTaskWithRequest:request fromData:bodyData];
    [sessionTask resume];
    
    NSString *URLString = [[request URL] absoluteString];
    
    [self addTask:sessionTask forURLString:URLString];
    [self addTask:sessionTask inNamespace:namespaceStr];
    
    return sessionTask;
}

- (NSURLSessionDownloadTask *)startDownloadTaskWithRequest:(NSURLRequest *)request inNamespace:(NSString *)namespaceStr
{
    NSURLSessionDownloadTask *sessionTask = [self.session downloadTaskWithRequest:request];
    [sessionTask resume];
    
    NSString *URLString = [[request URL] absoluteString];
    
    [self addTask:sessionTask forURLString:URLString];
    [self addTask:sessionTask inNamespace:namespaceStr];
    
    return sessionTask;
}

#pragma mark Cancel
- (void)cancelTaskForIdentifier:(NSUInteger)identifier
{
    @synchronized (self)
    {
        __block NSURLSessionTask *targetTask = nil;
        __block NSString *targetTaskKey = nil;
        
        [self.allTasksHash enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSURLSessionTask *task, BOOL *stop) {
            
            if (task.taskIdentifier == identifier)
            {
                targetTask = task;
                targetTaskKey = key;
                *stop = YES;
            }
        }];
        
        if (targetTask && targetTaskKey)
        {
            [targetTask cancel];
            
            [self.allTasksHash removeObjectForKey:targetTaskKey];
            
            
            [self.allNamespaceTasks enumerateKeysAndObjectsUsingBlock:^(NSString *namespaceStr, NSArray  *taskArray, BOOL *dStop)
            {
                __block NSURLSessionTask *foundTask = nil;
                [taskArray enumerateObjectsUsingBlock:^(NSURLSessionTask *task, NSUInteger idx, BOOL *aStop)
                 {
                     if (task.taskIdentifier == identifier)
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
    NSURLSessionTask *sessionTask = [self taskForURLString:URLString];
    if (sessionTask)
    {
        [sessionTask cancel];
        
        [self removeTask:sessionTask forURLString:URLString];
    }
}

- (void)cancelTasksInNamespace:(NSString *)namespaceStr
{
    NSArray *nTasks = [self tasksForNamespace:namespaceStr];
    for (NSURLSessionTask *sessionTask in nTasks)
    {
        [sessionTask cancel];
        
        NSString *URLString = sessionTask.originalRequest.URL.absoluteString;
        [self removeTask:sessionTask forURLString:URLString];
    }
    
    [self removeAllTasksInNamespace:namespaceStr];
}

#pragma mark - Private
#pragma mark Task Hash
- (NSURLSessionTask *)taskForURLString:(NSString *)URLString
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

- (void)removeTask:(NSURLSessionTask *)task forURLString:(NSString *)forURLString
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

- (void)addTask:(NSURLSessionTask *)task forURLString:(NSString *)URLString
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

- (void)removeTask:(NSURLSessionTask *)task inNamespace:(NSString *)namespaceStr
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

- (void)addTask:(NSURLSessionTask *)task inNamespace:(NSString *)namespaceStr
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
