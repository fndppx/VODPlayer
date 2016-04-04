//
//  LeMediaPlayer.m
//  KYAVplayer
//
//  Created by keyan on 16/3/10.
//  Copyright © 2016年 keyan. All rights reserved.
//

#import "LeMediaPlayer.h"
#import "LeGPUMediaPlayer.h"
#
@implementation LeMediaPlayer
+(LeMediaPlayer *) leMediaPlayerWithPlayerType:(LeMediaPlayerType) playerType path:(NSString *) playPath {
    if (playerType == LeMediaPlayerTypeCPUDecode) {
        //        return [[GGStreamingPlayer_Cocoa alloc] initWithContentPath:playPath needVideoDecode: YES needAudioDecode:YES];
    }
    else {
        return [[LeGPUMediaPlayer alloc] initWithContentPath:playPath
                                             needVideoDecode:YES
                                             needAudioDecode:YES];
    }
    return nil;
}

@end
