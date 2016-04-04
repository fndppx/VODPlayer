//
//  LeGPUMediaPlayer.h
//  KYAVplayer
//
//  Created by keyan on 16/3/10.
//  Copyright © 2016年 keyan. All rights reserved.
//

#import "LeMediaPlayer.h"
#import "LeStreamPlayerDelegate.h"
@interface LeGPUMediaPlayer : LeMediaPlayer
- (id) initWithContentPath:(NSString *) path needVideoDecode:(BOOL)needVideo needAudioDecode:(BOOL)needAudio;
- (void)prepareToPlay;
- (void)play;
- (void)stop;
- (void)pause;
- (void)resume;
- (void)seekToPosition:(float) position;
- (void)seekToPositionWithtolerance:(float)position;
- (float)currentPosition;
- (float)bufferDuration;
- (float)bufferPercent;
- (BOOL)setAudioVolume:(float)volume;
- (float)audioVolume;

@property (nonatomic, readonly) UIView *presentMovieView;
@property (nonatomic, weak) id<LeStreamPlayerDelegate> delegate;
@property (nonatomic, readonly) GGPlayIDType playerID;
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) float videoActualWidth;
@property (nonatomic, readonly) float videoActualHeight;
@property (nonatomic, readonly) GGStreamInfo_Cocoa *streamInfo;

@end
