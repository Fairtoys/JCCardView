//
//  JCViewController.m
//  JCCardView
//
//  Created by 313574889@qq.com on 09/28/2017.
//  Copyright (c) 2017 313574889@qq.com. All rights reserved.
//

#import "JCViewController.h"
#import "JCCardView.h"

@interface JCViewController ()

@end

@implementation JCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.cardView.maxCardItemCount = 3;
    [self.cardView registerCardItemViewClass:[UIView class] forIdentifier:@"identifier"];
    self.cardView.cardItemGetBlock = ^__kindof UIView * _Nullable(JCCardView * _Nonnull cardView, NSInteger idx) {
        UIView *view = [cardView dequeueReuseableCardItemViewWithIdentifier:@"identifier"];
        //        uint32_t width = arc4random_uniform(100);
        //        uint32_t height = arc4random_uniform(200);
        //        view.frame = CGRectMake(10, 10, width, height);
        //        UIView *view = [[UIView alloc]  init];
        
        view.backgroundColor = [UIColor colorWithRed: arc4random_uniform(255)/ 255.f green:arc4random_uniform(255)/ 255.f blue:arc4random_uniform(255)/ 255.f alpha:1];
        view.layer.cornerRadius = 10;
        
        return view;
        
    };
    
    
    
    [self.cardView setItemPanningBlock:^(JCCardView * _Nonnull cardView, __kindof UIView * _Nonnull itemView, NSInteger idx, CGFloat progress) {
        NSLog(@"setItemPanningBlock:%f", progress);
    }];
    
    [self.cardView setCardItemDidApearBlock:^(JCCardView * _Nonnull cardView, __kindof UIView * _Nonnull itemView, NSInteger idx) {
        NSLog(@"setItemDidApearBlock:%@ , idx:%d", NSStringFromSelector(_cmd), idx);
    }];
    [self.cardView setCardItemWillDisapearBlock:^(JCCardView * _Nonnull cardView, __kindof UIView * _Nonnull itemView, NSInteger idx, JCCardViewSwipeDirection direction) {
        NSLog(@"setItemWillDisapearBlock:%@ , idx:%d", NSStringFromSelector(_cmd), idx);
    }];
    
    [self.cardView setCardItemAnimationWillBeginBlock:^(JCCardView * _Nonnull cardView, __kindof UIView * _Nonnull itemView, NSInteger idx, JCCardViewSwipeDirection direction) {
        NSLog(@"animation will begin idx:%d direction:%d",idx, direction);
    }];
    
    [self.cardView setCardItemAnimationCanBegenBlock:^BOOL(JCCardView * _Nonnull cardView, __kindof UIView * _Nonnull itemView, NSInteger idx, JCCardViewSwipeDirection direction) {
        
        return YES;
        
    }];
    
    [self.cardView setCardItemDidClickBlock:^(JCCardView * _Nonnull cardView, __kindof UIView * _Nonnull itemView, NSInteger idx) {
    }];
    
    [self.cardView fillCardItems];
    
    
}


- (IBAction)onClickDequeueBtn:(id)sender {
    [self.cardView swipeCardItemToDirection:JCCardViewSwipeDirectionRight];
}

- (IBAction)onClickSwipeLeft:(id)sender {
    [self.cardView swipeCardItemToDirection:JCCardViewSwipeDirectionLeft];
}

- (IBAction)onClickRefresh:(id)sender {
    [self.cardView refreshCardItems];
}

- (IBAction)onClickReload:(id)sender {
    [self.cardView reloadCardItems];
}

- (IBAction)onClickResumeBtn:(id)sender {
    [self.cardView resumeCardItems];
}

- (IBAction)onClickUndo:(id)sender {
    [self.cardView undo];
}

@end
