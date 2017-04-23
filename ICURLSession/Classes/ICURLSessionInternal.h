//
//  ICURLSessionInternal.h
//  ICURLSession
//
//  Created by _ivanC on 26/12/2016.
//  Copyright © 2016 _ivanC. All rights reserved.
//

#import "ICURLSession.h"
#import "ICURLSessionTask.h"

@interface ICURLSession ()

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *sessionQueue;
@property (nonatomic, weak) id<NSURLSessionDelegate> sessionDelegate;

@property (nonatomic, strong) NSMutableDictionary *allTasksHash;
@property (nonatomic, strong) NSMutableDictionary *allNamespaceTasks;

@property (nonatomic, strong) NSMutableDictionary *allTasksMap;


- (ICURLSessionTask *)taskForURLString:(NSString *)URLString;
- (void)removeTask:(ICURLSessionTask *)task forURLString:(NSString *)forURLString;
- (void)addTask:(ICURLSessionTask *)task forURLString:(NSString *)URLString;

- (NSArray *)tasksForNamespace:(NSString *)namespaceStr;
- (void)removeAllTasksInNamespace:(NSString *)namespaceStr;
- (void)removeTask:(ICURLSessionTask *)task inNamespace:(NSString *)namespaceStr;
- (void)addTask:(ICURLSessionTask *)task inNamespace:(NSString *)namespaceStr;

@end
