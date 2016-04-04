//
//  LeMediaPlayer.h
//  KYAVplayer
//
//  Created by keyan on 16/3/10.
//  Copyright © 2016年 keyan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GGStreamInfo_Cocoa.h"
#import "LeStreamPlayerDelegate.h"
typedef NSInteger GGPlayIDType;

typedef enum {
    LeMediaPlayerTypeCPUDecode = 0,
    LeMediaPlayerTypeGPUDecode = 1,
}LeMediaPlayerType;

@interface LeMediaPlayer : NSObject
{
    __weak id<LeStreamPlayerDelegate> _delegate;
    BOOL _isPlaying;

}
+(LeMediaPlayer *) leMediaPlayerWithPlayerType:(LeMediaPlayerType) playerType path:(NSString *) playPath;

- (id) initWithContentPath:(NSString *) path needVideoDecode:(BOOL)needVideo needAudioDecode:(BOOL)needAudio;
- (void)play;
- (void)prepareToPlay;
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
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) float videoActualWidth;
@property (nonatomic, readonly) float videoActualHeight;
@property (nonatomic, readonly) GGStreamInfo_Cocoa *streamInfo;
@end
