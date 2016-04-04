
//
//  LeGPUMediaPlayer.m
//  KYAVplayer
//
//  Created by keyan on 16/3/10.
//  Copyright © 2016年 keyan. All rights reserved.
//

#import "LeGPUMediaPlayer.h"

#import <AVFoundation/AVFoundation.h>
#import "LeVideoLayerExtend.h"

#define VALID_DELEGATE(SEL)          (self.delegate && [self.delegate respondsToSelector:@selector(SEL)])
#define CALL_PROC_ON_MAIN_THREAD(PROC)              \
if(![NSThread isMainThread]){                       \
dispatch_async(dispatch_get_main_queue(), ^{        \
PROC                                                \
});                                                 \
}else{                                              \
PROC                                                \
}                                                   \


// resume play after stall
static const float kMaxHighWaterMarkMilli   = 15 * 1000;
static const float kMinPlayingRate          = 0.00001f;


void *kPlayerRateDidChangeKVO         = &kPlayerRateDidChangeKVO;

@interface LeGPUMediaPlayer ()

@property (nonatomic, strong) AVPlayer *avPlayer;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) UIView *videoView;
@property (nonatomic, assign) BOOL observersAdded;
@property (nonatomic, assign) BOOL notificationObserversAdded;
@property (nonatomic, strong) GGStreamInfo_Cocoa *aStreamInfo;
@property (nonatomic, assign) float aBufferDuration;
@property (nonatomic, assign) BOOL isObserverRateChange;
@property (nonatomic, assign) float totalPlayedTimeSec;
@property (nonatomic, assign) id playbackObserver;//播放回调的注册标识

@property (nonatomic, assign)  NSInteger bufferingProgress; // 缓冲进度

- (void) loadStreamInfoWithPlayerItem:(AVPlayerItem *) playerItem;
- (void) addPlayerKVOs;
- (void) removePlayerKVOs;
- (void) addPlayerObservers;
- (void) removePlayerObservers;
- (void) addPeriodicTimeObserver;
- (void) removePeriodTimeObserver;
@end

@implementation LeGPUMediaPlayer {
    BOOL _isPrerolling;
}


#pragma mark -
#pragma mark Public Methods
- (id) initWithContentPath:(NSString *) path needVideoDecode:(BOOL)needVideo needAudioDecode:(BOOL)needAudio {
    if (self = [super init]) {
        _avPlayer = [[AVPlayer alloc] init];
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_avPlayer];
        
        
        _videoView = [[LeVideoLayerExtend alloc] initWithFrame:CGRectMake(0, 0, 320, 240)];
        _videoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        _videoView.backgroundColor = [UIColor clearColor];
        
        _observersAdded = NO;
        _notificationObserversAdded = NO;
        _isObserverRateChange = NO;
        _aStreamInfo = [[GGStreamInfo_Cocoa alloc] init];
        
        BOOL isLocalPath;
        if ([path hasPrefix:@"http"] || [path hasPrefix:@"rtmp"]) {
            isLocalPath = NO;
        }
        else {
            isLocalPath = YES;
        }
        
        path = [path stringByTrimmingCharactersInSet:[NSMutableCharacterSet whitespaceAndNewlineCharacterSet]];
        
        AVAsset *asset = [AVURLAsset URLAssetWithURL:isLocalPath ? [NSURL fileURLWithPath:path] : [NSURL URLWithString:path] options:nil];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
        self.playerItem = playerItem;
        
        
        [_avPlayer replaceCurrentItemWithPlayerItem:playerItem];
    }
    return self;
}

- (UIView *) presentMovieView {
    return _videoView;
}
- (void)dealloc{
    [self stop];
    _delegate = nil;
    [self removePlayerKVOs];
    //    [self removePeriodTimeObserver];
    [self removePlayerObservers];
    [_videoView removeFromSuperview];
    _videoView = nil;
}


- (void)play {
    [_avPlayer play];
}

- (void)prepareToPlay{
    _isPlaying = YES;
    [self addPlayerKVOs];
    [self addPlayerObservers];
    _playerLayer.frame = _videoView.layer.bounds;
    [_videoView.layer addSublayer:_playerLayer];
}

// Returns YES if prepared for playback.
//@property(nonatomic, readonly) BOOL isPreparedToPlay;

- (void)stop {
    [self removePlayerKVOs];
    [self removePlayerObservers];
    [_playerLayer removeFromSuperlayer];
    [_avPlayer pause];
    //    [_avPlayer seekToTime:CMTimeMake(0, 1)];
    _isPlaying = NO;
    if (VALID_DELEGATE(streamPlayerDidStopFinished:)) {
        CALL_PROC_ON_MAIN_THREAD([_delegate streamPlayerDidStopFinished:self];)
    }
}

- (void)pause {
    _isPrerolling = NO;
    [_avPlayer pause];
    if (VALID_DELEGATE(streamPlayerDidPauseFinished:)) {
        CALL_PROC_ON_MAIN_THREAD([_delegate streamPlayerDidPauseFinished:self];)
    }
}

- (void)resume {
    [_avPlayer play];
    if (VALID_DELEGATE(streamPlayerDidResumeFinished:)) {
        CALL_PROC_ON_MAIN_THREAD([_delegate streamPlayerDidResumeFinished:self];)
    }
}

// 带偏差的seek 播放本地文件
- (void)seekToPositionWithtolerance:(float)position {
    [_avPlayer seekToTime:CMTimeMake(position, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    if (VALID_DELEGATE(streamPlayerDidSeekFinished:)) {
        CALL_PROC_ON_MAIN_THREAD([_delegate streamPlayerDidSeekFinished:self];)
    }
}

- (void)seekToPosition:(float) position {
    [_avPlayer seekToTime:CMTimeMake(position, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    if (VALID_DELEGATE(streamPlayerDidSeekFinished:)) {
        CALL_PROC_ON_MAIN_THREAD([_delegate streamPlayerDidSeekFinished:self];)
    }
}

- (float)currentPosition {
    if (!_avPlayer.currentTime.timescale) {
        return 0;
    }
    return _avPlayer.currentTime.value / _avPlayer.currentTime.timescale;
}

- (float)bufferDuration {
    return _aBufferDuration;
}

- (float)bufferPercent {
    return 1;
}

- (BOOL)setAudioVolume:(float)volume {
    if (_avPlayer) {
        _avPlayer.volume = volume;
        return YES;
    }
    else {
        return NO;
    }
}

- (float)audioVolume {
    return _avPlayer.volume;
}

- (GGStreamInfo_Cocoa *)streamInfo {
    return _aStreamInfo;
}

#pragma mark -
#pragma mark Private Methods
- (void) loadStreamInfoWithPlayerItem:(AVPlayerItem *) playerItem {
    CMTimeValue	value = 0;
    CMTimeScale	timescale = 0;
    
    for (AVPlayerItemTrack *videoTrack in playerItem.tracks) {
        if ([videoTrack.assetTrack.mediaType isEqualToString:AVMediaTypeVideo]) {
            _aStreamInfo.videoWidth = videoTrack.assetTrack.naturalSize.width;
            _aStreamInfo.videoHeight = videoTrack.assetTrack.naturalSize.height;
            value = playerItem.asset.duration.value;
            timescale = playerItem.asset.duration.timescale;
        }
    }
    if (!timescale) {
        value = playerItem.duration.value;
        timescale = playerItem.duration.timescale;
    }
    
    if (!timescale) {
        _aStreamInfo.duration = 0;
        return;
    }
    _aStreamInfo.duration = value / timescale;
}



- (void) addPlayerKVOs {
    if (!_observersAdded) {
        [self.playerItem addObserver:self
                          forKeyPath:@"playbackBufferEmpty"
                             options:NSKeyValueObservingOptionNew
                             context:nil];
        [self.playerItem addObserver:self
                          forKeyPath:@"playbackLikelyToKeepUp"
                             options:NSKeyValueObservingOptionNew
                             context:nil];
        [self.playerItem addObserver:self
                          forKeyPath:@"status"
                             options:NSKeyValueObservingOptionNew
                             context:nil];
        [self.playerItem addObserver:self
                          forKeyPath:@"loadedTimeRanges"
                             options:NSKeyValueObservingOptionNew
                             context:nil];
        [self.playerItem addObserver:self
                          forKeyPath:@"tracks"
                             options:NSKeyValueObservingOptionNew
                             context:nil];
        
        [self.avPlayer addObserver:self
                        forKeyPath:@"rate"
                           options:NSKeyValueObservingOptionNew
                           context:kPlayerRateDidChangeKVO];
        
        _observersAdded = YES;
        [self addPeriodicTimeObserver];
    }
}

- (void) removePlayerKVOs {
    if (_observersAdded) {
        [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [self.playerItem removeObserver:self forKeyPath:@"status"];
        [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [self.playerItem removeObserver:self forKeyPath:@"tracks"];
        [self.avPlayer   removeObserver:self forKeyPath:@"rate"];
        [self removePeriodTimeObserver];
        _observersAdded = NO;
    }
}

- (void) addPlayerObservers {
    if (!_notificationObserversAdded) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onNotificationPlayVideoEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemFailedToPlayToEndTime:)
                                                     name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onNotificationStalled:)
                                                     name:AVPlayerItemPlaybackStalledNotification
                                                   object:nil];
        
        _notificationObserversAdded = YES;
    }
}

- (void) removePlayerObservers {
    if (_notificationObserversAdded) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemPlaybackStalledNotification
                                                      object:nil];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                      object:nil];
        _notificationObserversAdded = NO;
    }
}

- (void) addPeriodicTimeObserver {
    __weak typeof(self) wSelf = self;
    __block int playingTime = 0;
    _playbackObserver = [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time)
                         {
                             //获取当前时间
                             CMTime currentTime = wSelf.avPlayer.currentItem.currentTime;
                             //转成秒数
                             CGFloat currentPlayTime = (CGFloat)currentTime.value/currentTime.timescale;
                             wSelf.totalPlayedTimeSec = currentPlayTime;
                             playingTime = (int)currentPlayTime;
                             if (VALID_DELEGATE(streamPlayer:playingTime:)) {
                                 CALL_PROC_ON_MAIN_THREAD([wSelf.delegate streamPlayer:wSelf playingTime:playingTime];)
                             }
                         }];
    
}

- (void) removePeriodTimeObserver {
    [self.avPlayer removeTimeObserver:_playbackObserver];
}

#pragma mark -
#pragma mark Notification Handler
- (void)playerItemFailedToPlayToEndTime:(NSNotification *)notification
{
    // 增加播放地址出错时的通知
    _isPlaying = NO;
    AVPlayerItem *playerItem = (AVPlayerItem *)notification.object; //代理 添加Item的判定
    if (VALID_DELEGATE(streamPlayerDidReceiveError:)
        &&self.playerItem == playerItem) {
        CALL_PROC_ON_MAIN_THREAD([_delegate streamPlayerDidReceiveError:self];)
    }
    
}


- (void) onNotificationPlayVideoEnd:(NSNotification *) notification {
    _isPlaying = NO;
    AVPlayerItem *playerItem = (AVPlayerItem *)notification.object; //代理 添加Item的判定
    if (VALID_DELEGATE(streamPlayerDidPlayFinished:)
        &&self.playerItem == playerItem) {
        CALL_PROC_ON_MAIN_THREAD([_delegate streamPlayerDidPlayFinished:self];)
    }
}

- (void) onNotificationStalled:(NSNotification *) notification {
    AVPlayerItem *playerItem = (AVPlayerItem *)notification.object;
    if (VALID_DELEGATE(streamPlayerWillBeginBufferring:)
        &&self.playerItem ==playerItem) {
        CALL_PROC_ON_MAIN_THREAD([self.delegate streamPlayerWillBeginBufferring:self];)
    }
}
#pragma mark -
#pragma mark KVO Handler
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (object == _playerItem && [keyPath isEqualToString:@"playbackLikelyToKeepUp"] && _playerItem.playbackLikelyToKeepUp) {
        _isObserverRateChange = YES;
        //NSLog(@"--------------- play status is %@ --------------- \n", keyPath);
        if (VALID_DELEGATE(streamPlayerDidFinishBufferring:)) {
            CALL_PROC_ON_MAIN_THREAD([self.delegate streamPlayerDidFinishBufferring:self];)
        }
    }
    else if (object == _playerItem && [keyPath isEqualToString:@"status"])
    {
        if (_avPlayer.status == AVPlayerItemStatusReadyToPlay && !_playerItem.error)
        {
            if (VALID_DELEGATE(streamPlayerDidFinishedInit:))
            {
                CALL_PROC_ON_MAIN_THREAD([self.delegate streamPlayerDidFinishedInit:self];)
            }
        }
        else if (_avPlayer.status == AVPlayerItemStatusFailed || _playerItem.error) {
            _isPlaying = NO;
            if (VALID_DELEGATE(streamPlayerDidReceiveError:)) {
                CALL_PROC_ON_MAIN_THREAD([self.delegate streamPlayerDidReceiveError:self];)
            }
        }
        else {
            NSLog(@"AVPlayerItemStatusUnknown");
        }
    }
    else if (object == _playerItem && [keyPath isEqualToString:@"tracks"]) {
        [self loadStreamInfoWithPlayerItem:_playerItem];
        if (VALID_DELEGATE(streamPlayerDidGotMediaInfo:)) {
            CALL_PROC_ON_MAIN_THREAD([self.delegate streamPlayerDidGotMediaInfo:self];)
        }
    }
    else if (object == _playerItem && [keyPath isEqualToString:@"playbackBufferEmpty"]) {
        BOOL isPlaybackBufferEmpty = _playerItem.isPlaybackBufferEmpty;
        if (isPlaybackBufferEmpty)
            _isPrerolling = YES;
        //        NSLog(@"playbackBufferEmpty");
        //        NSLog(@"--------------- play status is %@ --------------- \n", keyPath);
        //        if (VALID_DELEGATE(streamPlayerWillBeginBufferring:)) {
        //            CALL_PROC_ON_MAIN_THREAD([self.delegate streamPlayerWillBeginBufferring:self];)
        //        }
        //        NSLog(@"playbackBufferEmpty");
    }
    else if (object == _playerItem && [keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray *loadedTimeRanges = [[self.avPlayer currentItem] loadedTimeRanges];
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float totalBufferingSec = durationSeconds+startSeconds;
        _aBufferDuration = durationSeconds;
        //        NSLog(@"%@起始缓冲时间:%f,缓冲时间长:%f,已经播放的时长:%f",self,startSeconds,durationSeconds+startSeconds,_totalPlayedTimeSec);
        if ((_totalPlayedTimeSec < totalBufferingSec) && (_totalPlayedTimeSec > startSeconds))
        {
            //            NSLog(@"视频播放流畅");
            if (VALID_DELEGATE(streamPlayerResumeFluency:)) {
                CALL_PROC_ON_MAIN_THREAD([self.delegate streamPlayerResumeFluency:self];)
            }
        }
        else
        {
            //            NSLog(@"视频播放卡顿");
            if (VALID_DELEGATE(streamPlayerDidStall:)) {
                CALL_PROC_ON_MAIN_THREAD([self.delegate streamPlayerDidStall:self];)
            }
        }
    }
    
    //
    if (context == kPlayerRateDidChangeKVO) {
        if (_avPlayer.rate == 0.0) {
            //            NSLog(@"_avPlayer.rate为0");
            if (VALID_DELEGATE(streamPlayerRateIsLowLevel:)) {
                CALL_PROC_ON_MAIN_THREAD([self.delegate streamPlayerRateIsLowLevel:self];)
            }
            if (_isObserverRateChange) {
                if (VALID_DELEGATE(streamPlayerStatePauseWithPlayer:)) {
                    CALL_PROC_ON_MAIN_THREAD([self.delegate streamPlayerStatePauseWithPlayer:self];)
                }
            }
        }else{
            //             NSLog(@"_avPlayer.rate为1");
            if (VALID_DELEGATE(streamPlayerRateIsNormalLevel:)) {
                CALL_PROC_ON_MAIN_THREAD([self.delegate streamPlayerRateIsNormalLevel:self];)
            }
            if (VALID_DELEGATE(streamPlayerStatePlayingWithPlayer:)) {
                CALL_PROC_ON_MAIN_THREAD([self.delegate streamPlayerStatePlayingWithPlayer:self];)
            }
        }
    }
    
    
}


#pragma mark -
- (BOOL)isPlaying
{
    if (_avPlayer.rate >= kMinPlayingRate) {
        return YES;
    } else {
        if (_isPrerolling) {
            return YES;
        } else {
            return NO;
        }
    }
}


//- (void)didPlayableDurationUpdate
//{
//    NSTimeInterval currentPlaybackTime = self.currentPosition;
//    int playableDurationMilli    = (int)(self.bufferDuration * 1000);
//    int currentPlaybackTimeMilli = (int)(currentPlaybackTime * 1000);
//
//    int bufferedDurationMilli = playableDurationMilli - currentPlaybackTimeMilli;
//    if (bufferedDurationMilli > 0) {
//        self.bufferingProgress = bufferedDurationMilli * 100 / kMaxHighWaterMarkMilli;
//
//        if (self.bufferingProgress > 100) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                if (self.bufferingProgress > 100) {
//                    if ([self isPlaying]) {
////                        _avPlayer.rate = 1.0f;
//                    }
//                }
//            });
//        }
//        
//    }
//}


@end
