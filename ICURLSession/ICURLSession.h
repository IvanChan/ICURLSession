//
//  ICURLSession.h
//  FoundationEx
//
//  Created by _ivanC on 26/10/2016.
//  Copyright © 2016 _ivanC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ICURLSession : NSObject

+ (instancetype)sharedSession;

- (instancetype)initWithSessionDelegate:(id<NSURLSessionDelegate>)sessionDelegate;

// Use block to callback
- (NSURLSessionTask *)startDataTaskWithRequest:(NSURLRequest *)request
                                   inNamespace:(NSString *)namespaceStr
                                succeedHandler:(void (^)(NSURLResponse *response, NSData *data))succeedHandler
                                   failHandler:(void (^)(NSURLResponse *response, NSError *error))failHandler;

- (NSURLSessionTask *)startDownloadTaskWithRequest:(NSURLRequest *)request
                                       inNamespace:(NSString *)namespaceStr
                                    succeedHandler:(void (^)(NSURLResponse *response, NSURL *dataLocation))succeedHandler
                                       failHandler:(void (^)(NSURLResponse *response, NSError *error))failHandler;

- (NSURLSessionTask *)startUploadTaskWithRequest:(NSURLRequest *)request
                                        fromData:(NSData *)data
                                     inNamespace:(NSString *)namespaceStr
                                  succeedHandler:(void (^)(NSURLResponse *response, NSData *data))succeedHandler
                                     failHandler:(void (^)(NSURLResponse *response, NSError *error))failHandler;

- (NSURLSessionTask *)startUploadTaskWithRequest:(NSURLRequest *)request
                                        fromFile:(NSURL *)fileURL
                                     inNamespace:(NSString *)namespaceStr
                                  succeedHandler:(void (^)(NSURLResponse *response, NSData *data))succeedHandler
                                     failHandler:(void (^)(NSURLResponse *response, NSError *error))failHandler;

// Use delegate to callback
// Normally you have to create your own NSURLSession object to set delegate
- (NSURLSessionDataTask *)startDataTaskWithRequest:(NSURLRequest *)request inNamespace:(NSString *)namespaceStr;

- (NSURLSessionUploadTask *)startUploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL inNamespace:(NSString *)namespaceStr;
- (NSURLSessionUploadTask *)startUploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData inNamespace:(NSString *)namespaceStr;

- (NSURLSessionDownloadTask *)startDownloadTaskWithRequest:(NSURLRequest *)request inNamespace:(NSString *)namespaceStr;


// Cancel methods
- (void)cancelTaskForIdentifier:(NSUInteger)identifier;
- (void)cancelTaskForURLString:(NSString *)URLString;
- (void)cancelTasksInNamespace:(NSString *)namespaceStr;

- (void)finishTasksAndInvalidate;

@end
