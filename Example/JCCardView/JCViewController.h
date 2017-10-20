//
//  JCViewController.h
//  JCCardView
//
//  Created by 313574889@qq.com on 09/28/2017.
//  Copyright (c) 2017 313574889@qq.com. All rights reserved.
//

@import UIKit;

@class JCCardView;

NS_ASSUME_NONNULL_BEGIN

@interface JCViewController : UIViewController

@property (weak, nonatomic) IBOutlet JCCardView *cardView;
- (IBAction)onClickDequeueBtn:(id)sender;
- (IBAction)onClickSwipeLeft:(id)sender;
- (IBAction)onClickRefresh:(id)sender;
- (IBAction)onClickReload:(id)sender;
- (IBAction)onClickResumeBtn:(id)sender;
- (IBAction)onClickUndo:(id)sender;


@end

NS_ASSUME_NONNULL_END
