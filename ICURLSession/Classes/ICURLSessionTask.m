//
//  ICURLSessionTask.m
//  ICURLSession
//
//  Created by _ivanC on 26/12/2016.
//  Copyright © 2016 _ivanC. All rights reserved.
//

#import "ICURLSessionTask.h"

@interface ICURLSessionTask ()

@property (nonatomic, strong) NSMutableData *tempData;

@end

@implementation ICURLSessionTask

- (void)appendReceivedData:(NSData *)data
{
    if (self.tempData == nil)
    {
        self.tempData = [NSMutableData data];
    }
    
    [self.tempData appendData:data];
}

- (void)didFinishReceivedData
{
    self.data = self.tempData;
    self.tempData = nil;
}

@end
