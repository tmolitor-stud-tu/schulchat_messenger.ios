//
//  MLBaseCell.m
//  Monal
//
//  Created by Anurodh Pokharel on 12/24/17.
//  Copyright © 2017 Monal.im. All rights reserved.
//

#import "MLBaseCell.h"
NSString *const kDelivered=@"Zugestellt";
NSString *const kRead=@"Gelesen";

@implementation MLBaseCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    BOOL backgrounds = [[NSUserDefaults standardUserDefaults] boolForKey:@"ChatBackgrounds"];
    if(backgrounds) {
        self.name.textColor=[UIColor whiteColor];
        self.date.textColor=[UIColor whiteColor];
        self.messageStatus.textColor=[UIColor whiteColor];
        self.dividerDate.textColor=[UIColor whiteColor];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


-(void) updateCellWithNewSender:(BOOL) newSender
{
    if([self.parent respondsToSelector:@selector(retry:)]) {
        [self.retry addTarget:self.parent action:@selector(retry:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    self.retry.tag= [self.messageHistoryId integerValue];
    
    if(self.deliveryFailed) {
        self.retry.hidden=NO;
    }
    else{
        self.retry.hidden=YES;
    }
    
    if(self.name) {
        if(self.name.text.length==0) {
            self.nameHeight.constant=0;
            self.bubbleTop.constant=0;
            self.dayTop.constant=0;
        } else  {
            self.nameHeight.constant= kDefaultTextHeight;
            self.bubbleTop.constant=kDefaultTextOffset;
            self.dayTop.constant=kDefaultTextOffset;
        }
    }
    
    if(self.dividerDate.text.length==0) {
        self.dividerHeight.constant=0;
        if(!self.name) {
            self.bubbleTop.constant=0;
            self.dayTop.constant=0;
        }
    } else  {
        if(!self.name) {
            self.bubbleTop.constant=kDefaultTextOffset;
            self.dayTop.constant=kDefaultTextOffset;
        }
        self.dividerHeight.constant=kDefaultTextHeight;
    }
    
    if(newSender &&  self.dividerHeight.constant==0) {
        self.dividerHeight.constant= kDefaultTextHeight/2;
    }
}

-(void)prepareForReuse{
    [super prepareForReuse];
    self.deliveryFailed=NO;
    self.outBound=NO;
}

@end
