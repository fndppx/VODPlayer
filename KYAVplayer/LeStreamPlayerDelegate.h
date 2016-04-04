//
//  LeStreamPlayerDelegate.h
//  KYAVplayer
//
//  Created by keyan on 16/3/10.
//  Copyright © 2016年 keyan. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LeStreamPlayerDelegate <NSObject>
@optional
- (void)streamPlayerDidFinishedInit:(id)player;
- (void)streamPlayerDidGotMediaInfo:(id)player;
- (void)streamPlayerDidFinishBufferring:(id) player;
- (void)streamPlayerWillBeginBufferring:(id) player;
- (void)streamPlayerDidReceiveError:(id) player;
- (void)streamPlayerDidSeekFinished:(id) player;
- (void)streamPlayerDidPauseFinished:(id) player;
- (void)streamPlayerDidResumeFinished:(id) player;
- (void)streamPlayerDidPlayFinished:(id) player;
- (void)streamPlayerDidStopFinished:(id) player;


- (void)streamPlayerDidStall:(id) player;//开始卡顿
- (void)streamPlayerResumeFluency:(id) player;//恢复流畅

- (void)streamPlayerRateIsLowLevel:(id)player;//码率为0
- (void)streamPlayerRateIsNormalLevel:(id)player;//码率为1

- (void)streamPlayer:(id)player playingTime:(int)time;//播放时间

- (void)streamPlayerStatePlayingWithPlayer:(id)player;
- (void)streamPlayerStatePauseWithPlayer:(id)player;


- (void)streamPlayerVideoReady:(id)player;
- (void)streamPlayerVideoDataLost:(id)player;
- (void)streamPlayerAudioReady:(id)player;
- (void)streamPlayerAudioDataLost:(id)player;
- (void)streamPlayerVideoStartSuccess:(id)player;
- (void)streamPlayerVideoStartFail:(id)player;
- (void)streamPlayerVideoStartToRender:(id)player;
- (void)streamPlayerDidStopTick:(id)player;
- (void)streamPlayerNoMedia:(id)player;

@end
