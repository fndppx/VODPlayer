//
//  GGStreamInfo_Cocoa.h
//  KYAVplayer
//
//  Created by keyan on 16/3/10.
//  Copyright © 2016年 keyan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GGStreamInfo_Cocoa : NSObject

@property (nonatomic, assign) NSInteger videoWidth;
@property (nonatomic, assign) NSInteger videoHeight;
@property (nonatomic, assign) NSInteger fps;
@property (nonatomic, assign) NSInteger duration;

@property (nonatomic, assign) NSInteger audioSampleRate;
@property (nonatomic, assign) NSInteger audioChannelsNumber;
@property (nonatomic, assign) NSInteger audioBitsPerSample;
@end
