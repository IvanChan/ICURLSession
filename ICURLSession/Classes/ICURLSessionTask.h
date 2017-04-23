//
//  ICURLSessionTask.h
//  ICURLSession
//
//  Created by _ivanC on 26/12/2016.
//  Copyright © 2016 _ivanC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ICURLSessionTask : NSObject

@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, copy)  NSString *taskNamespace;
@property (nonatomic, copy)  NSString *originalURL;

@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSURL *dataLocation;
@property (nonatomic, strong) NSError *error;

@property (nonatomic, copy) void (^progressBlock)(int64_t currentBytes, int64_t totalBytes);
@property (nonatomic, copy) void (^downloadFinishBlock)(NSURLResponse *response, NSURL *dataLocation);
@property (nonatomic, copy) void (^successBlock)(NSURLResponse *response, NSData *data);
@property (nonatomic, copy) void (^failBlock)(NSURLResponse *response, NSError *error);

- (void)appendReceivedData:(NSData *)data;
- (void)didFinishReceivedData;

@end
