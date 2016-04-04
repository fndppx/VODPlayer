//
//  LeVideoLayerExtend.m
//  KYAVplayer
//
//  Created by keyan on 16/3/10.
//  Copyright © 2016年 keyan. All rights reserved.
//

#import "LeVideoLayerExtend.h"

@implementation LeVideoLayerExtend

- (void) setFrame:(CGRect) rect {
    [super setFrame:rect];
    
    self.layer.frame = self.bounds;
    for (CALayer *subLayer in self.layer.sublayers) {
        subLayer.frame = self.bounds;
    }
}

@end
