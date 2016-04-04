//
//  ViewController.m
//  KYAVplayer
//
//  Created by keyan on 16/3/10.
//  Copyright © 2016年 keyan. All rights reserved.
//

#import "ViewController.h"
#import "LeMediaPlayer.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIView *videoContentView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    
    
//    LeMediaPlayer * adMediaPlayer = [LeMediaPlayer leMediaPlayerWithPlayerType:LeMediaPlayerTypeGPUDecode path:@"http://v3.cztv.com/cztv/vod/2016/03/06/c18db809ec894a839c8e260f5c3dc1a7/h264_450k_mp4.mp4_playlist.m3u8"];
//    
//    
////    adMediaPlayer.delegate = self;
//    self.videoContentView.frame = adMediaPlayer.presentMovieView.bounds;
//
//    [self.videoContentView addSubview:adMediaPlayer.presentMovieView];
//    [adMediaPlayer prepareToPlay];
//    [adMediaPlayer play];

}
- (void)viewDidAppear:(BOOL)animated
{
    LeMediaPlayer * adMediaPlayer = [LeMediaPlayer leMediaPlayerWithPlayerType:LeMediaPlayerTypeGPUDecode path:@"http://v3.cztv.com/cztv/vod/2016/03/06/c18db809ec894a839c8e260f5c3dc1a7/h264_450k_mp4.mp4_playlist.m3u8"];
    
    
    //    adMediaPlayer.delegate = self;
    self.videoContentView.frame = adMediaPlayer.presentMovieView.bounds;
    
    [self.videoContentView addSubview:adMediaPlayer.presentMovieView];
    [adMediaPlayer prepareToPlay];
    [adMediaPlayer play];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
