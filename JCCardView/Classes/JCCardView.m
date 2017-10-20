//
//  JCCardView.m
//  JCCardView
//
//  Created by Cerko on 2017/9/22.
//  Copyright © 2017年 Cerko. All rights reserved.
//

#import "JCCardView.h"
#import <objc/runtime.h>
#import "Masonry.h"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)



@implementation NSMutableArray (JCQueue)

- (void)jc_enqueue:(id)obj{
    [self addObject:obj];
}
- (id)jc_dequeueFromTail{
    id obj = [self lastObject];
    if (!obj) {
        return nil;
    }
    
    [self removeObject:obj];
    return obj;
}

- (id)jc_dequeue{
    id obj = self.firstObject;
    
    if (!obj) {
        return nil;
    }
    
    [self removeObject:obj];
    return obj;
}

- (void)jc_push:(id)obj{
    [self addObject:obj];
}
- (nullable id)jc_pop{
    id obj = self.lastObject;
    if (!obj) {
        return nil;
    }
    [self removeObject:obj];
    return obj;
}

- (void)jc_enqueueToHead:(id)obj{
    [self insertObject:obj atIndex:0];
}


@end

@implementation NSObject (JCEx)

- (void)setJc_obj:(id)jc_obj{
    objc_setAssociatedObject(self, @selector(jc_obj), jc_obj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)jc_obj{
    return objc_getAssociatedObject(self, _cmd);
}

@end


@interface UIView (JCCardViewInternal)

@property (nonatomic, strong) NSString *jc_internalIdentifier;

@end

@implementation UIView (JCCardViewInternal)

- (void)setJc_internalIdentifier:(NSString *)jc_internalIdentifier{
    objc_setAssociatedObject(self, @selector(jc_internalIdentifier), jc_internalIdentifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)jc_internalIdentifier{
    return objc_getAssociatedObject(self, _cmd);
}

@end

@interface JCUndoState : NSObject

@property (nonatomic, assign) JCCardViewSwipeDirection direction;

@end

@implementation JCUndoState

@end


@interface JCCardView ()

/**
 当前显示中的所有视图
 */
@property (nonatomic, strong) NSMutableArray <__kindof UIView *> *itemViews;


#pragma mark 缓存相关
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray <__kindof UIView *> *> *reusebleItemViews;

@property (nonatomic, strong) NSMutableDictionary <NSString *, Class> *registerdItemClazz;

#pragma mark - 回退
@property (nonatomic, strong) NSMutableArray <JCUndoState *> *undoStack;//用来记录一下划走的状态

#pragma mark 手势相关
@property (nonatomic, strong, nullable) UIView *selectedView;//当前滑动中的视图

@property (nonatomic, assign) JCCardViewSwipeDirection direction;//滑动方向


@property (nonatomic, assign) CGPoint translation;//当前的移动距离

@property (nonatomic, assign) CGFloat progress;//滑动进度 0 ~ 1

@property (nonatomic, strong, nullable) UIView *tempHandlingView;//当前触发了移除条件正要移除的视图


@end

@implementation JCCardView


- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup{
    _scaleOffset = 0.05;
    _translationYOffset = 15;
    _maxDetectiveDistance = 100.f;
    _maxRadius = DEGREES_TO_RADIANS(5);
    _translationForRemovingItem = CGPointMake(400, 100);
    _animationDuration = 0.25;
    UIPanGestureRecognizer *ges = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGes:)];
    [self addGestureRecognizer:ges];
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGes:)];
    [self addGestureRecognizer:tapGes];
}

- (void)onTapGes:(UITapGestureRecognizer *)ges{
    if (!self.itemViews.count) {
        return;
    }
    
    if (self.cardItemDidClickBlock) {
        self.cardItemDidClickBlock(self, self.itemViews.firstObject, self.currentShowingItemIdx);
    }
    
}

- (void)onPanGes:(UIPanGestureRecognizer *)ges{
    
    if (UIGestureRecognizerStateBegan == ges.state) {
        self.selectedView = self.itemViews.firstObject;
        return;
    }
    
    if (!self.selectedView) {
        return;
    }
    
    if (UIGestureRecognizerStateChanged == ges.state) {
        CGPoint translation = [ges translationInView:self];
        self.direction = translation.x > 0 ? JCCardViewSwipeDirectionRight : JCCardViewSwipeDirectionLeft;
        self.translation = translation;
        //进度
        self.progress = MAX(0, MIN(1, fabs(translation.x / self.maxDetectiveDistance)));
        
        //回调
        if (self.itemPanningBlock) {
            self.itemPanningBlock(self, self.selectedView, self.currentShowingItemIdx, _progress);
        }
        
        self.selectedView.transform = CGAffineTransformMakeRotation(self.direction * self.progress * self.maxRadius);
        
        [self setNeedsUpdateConstraints];
        [self layoutIfNeeded];
        return;
    }
    
    if (UIGestureRecognizerStateEnded == ges.state) {
        
        BOOL (^clearBlock)() = ^(){
            self.translation = CGPointZero;
            self.progress = 0;
            self.tempHandlingView = self.selectedView;
            self.selectedView = nil;//这里设为nil，因为更新约束的函数中会根据此值来约束
            BOOL canBeginAnimation = YES;
            if (self.cardItemAnimationCanBegenBlock) {
                canBeginAnimation = self.cardItemAnimationCanBegenBlock(self, self.tempHandlingView, self.currentShowingItemIdx, self.direction);
            }
            
            return canBeginAnimation;
        };
        
        //判断是否需要恢复
        BOOL isNeedResumeCardItem = JCCardViewSwipeDirectionNone != self.direction && self.progress < 1;
        
        if (isNeedResumeCardItem) {
            self.direction = JCCardViewSwipeDirectionNone;
        }
        
        //清理一些值
        BOOL canAnimationBegin = clearBlock();
        if (!canAnimationBegin) {
            return;
        }
        
        if (isNeedResumeCardItem) {
            [self resumeCardItems];
        }else{
            [self swipeCardItem];
        }
        
        
        return;
    }
}

- (void)resumeCardItems{
    if (self.cardItemAnimationWillBeginBlock) {
        self.cardItemAnimationWillBeginBlock(self, self.tempHandlingView, self.currentShowingItemIdx, self.direction);
    }
    
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
    [UIView animateWithDuration:self.animationDuration animations:^{
        self.tempHandlingView.transform = CGAffineTransformIdentity;
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.tempHandlingView = nil;
    }];
}

- (void)swipeCardItemToDirection:(JCCardViewSwipeDirection)direction{
    self.direction = direction;
    [self swipeCardItem];
}

- (void)swipeCardItem{
    self.tempHandlingView = [self.itemViews jc_dequeue];
    
    if (self.cardItemAnimationWillBeginBlock) {
        self.cardItemAnimationWillBeginBlock(self, self.tempHandlingView, self.currentShowingItemIdx, self.direction);
    }
    
    if (self.cardItemWillDisapearBlock) {
        self.cardItemWillDisapearBlock(self, self.tempHandlingView, self.currentShowingItemIdx, self.direction);
    }
    
    [self.tempHandlingView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(self);
        make.center.centerOffset(CGPointMake(self.direction * self.translationForRemovingItem.x, self.translationForRemovingItem.y));
        make.size.equalTo(self);
    }];
    
    
    [self fillCardItemsWithcompletion:^{
        
        //缓存
        NSString *identifier = self.tempHandlingView.jc_internalIdentifier;
        if (identifier.length) {
            NSMutableArray <UIView *> *itemViews = self.reusebleItemViews[identifier];
            if (!itemViews) {
                itemViews = [NSMutableArray array];
                self.reusebleItemViews[identifier] = itemViews;
            }
            [itemViews jc_enqueue:self.tempHandlingView];
        }
        self.tempHandlingView.transform = CGAffineTransformIdentity;
        [self.tempHandlingView removeFromSuperview];
        
        self.tempHandlingView = nil;
        
        //当前显示的视图索引++，并回调
        self.currentShowingItemIdx ++;
        
        //入撤销栈
        JCUndoState *state = [[JCUndoState alloc] init];
        state.direction = self.direction;
        [self.undoStack jc_push:state];
        
        self.direction = JCCardViewSwipeDirectionNone;
        
    }];
}



- (void)continueCardItemAnimation{
    switch (self.direction) {
        case JCCardViewSwipeDirectionNone:
            [self resumeCardItems];
            break;
        case JCCardViewSwipeDirectionLeft:
            [self swipeCardItemToDirection:JCCardViewSwipeDirectionLeft];
            break;
        case JCCardViewSwipeDirectionRight:
            [self swipeCardItemToDirection:JCCardViewSwipeDirectionRight];
            break;
    }
}

- (void)reloadCardItems{
    self.willLoadingItemIdx = 0;
    self.currentShowingItemIdx = 0;
    [self.itemViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.itemViews removeAllObjects];
    [self.undoStack removeAllObjects];
    
    [self fillCardItems];
}

- (void)refreshCardItems{
    //如果当前正在显示某个视图，则调用willDisapear回调
    if (self.itemViews.count) {
        if (self.cardItemWillDisapearBlock) {
            self.cardItemWillDisapearBlock(self, self.itemViews.firstObject, self.currentShowingItemIdx, self.direction);
        }
    }
    self.willLoadingItemIdx -= self.itemViews.count;
    [self.itemViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.itemViews removeAllObjects];
    [self.undoStack removeAllObjects];
    
    [self fillCardItems];

}

- (void)fillCardItems{
    [self fillCardItemsWithcompletion:NULL];
}

- (void)fillCardItemsWithcompletion:(nullable  void (^)())completion{
    while (self.itemViews.count < _maxCardItemCount + 1) {
        if (self.cardItemGetBlock) {
            UIView *obj = self.cardItemGetBlock(self, self.willLoadingItemIdx);
            if (!obj) {
                return;
            }
            obj.frame = CGRectInset(self.bounds, _translationYOffset, _translationYOffset);
            [self insertSubview:obj atIndex:0];
            [self.itemViews jc_enqueue:obj];
            
            //加载过的数据的索引+1
            self.willLoadingItemIdx ++;
        }else
            return;
    }
    
    [self setNeedsUpdateConstraints];
    [UIView animateWithDuration:self.animationDuration animations:^{
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
        
        if (self.cardItemDidApearBlock) {
            self.cardItemDidApearBlock(self, self.itemViews.firstObject, self.currentShowingItemIdx);
        }

    }];
}

- (void)undo{
    if (self.currentShowingItemIdx <= 0) {
        return;
    }
    //最顶层的即将消失
    UIView *viewWillDisappear = self.itemViews.firstObject;
    if (viewWillDisappear) {
        if (self.cardItemWillDisapearBlock) {
            self.cardItemWillDisapearBlock(self, viewWillDisappear, self.currentShowingItemIdx, self.direction);
        }
    }

    //从屏幕外飞回视图
    self.currentShowingItemIdx--;
    
    JCUndoState *undoStae = [self.undoStack jc_pop];
    JCCardViewSwipeDirection direction = undoStae.direction;
    
    //要回显的视图，设置center，才能从屏幕外飞回来
    NSInteger idx = self.currentShowingItemIdx;
    UIView *obj = self.cardItemGetBlock(self, idx);
    obj.frame = CGRectInset(self.bounds, _translationYOffset, _translationYOffset);
    obj.center = CGPointMake(CGRectGetMidX(obj.frame) + direction * self.translationForRemovingItem.x, CGRectGetMidY(obj.frame));
    
    [self addSubview:obj];

    [self.itemViews jc_enqueueToHead:obj];

    //如果当前的显示总数大于了最大显示数目，则去掉队尾的那一个
    if (self.itemViews.count > _maxCardItemCount + 1) {
        UIView *removingObj = [self.itemViews jc_dequeueFromTail];
        [removingObj removeFromSuperview];
        self.willLoadingItemIdx --;
    }
    
    
    [self setNeedsUpdateConstraints];
    [UIView animateWithDuration:self.animationDuration animations:^{
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (self.cardItemDidApearBlock) {
            self.cardItemDidApearBlock(self, self.itemViews.firstObject, self.currentShowingItemIdx);
        }
        
    }];
    
}


- (void)updateConstraints{
    
    [self.itemViews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (self.selectedView == obj) {
            [obj mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.center.centerOffset(self.translation);
                make.size.equalTo(self);
            }];
        }else{
            [obj mas_remakeConstraints:^(MASConstraintMaker *make) {
                //没有选中视图，并且是最后一个，才让最后一个和倒数第二个位置相同
                NSUInteger index = idx == _maxCardItemCount && !self.selectedView ? idx - 1 : idx;//最后一个和倒数第二个的布局相同
                CGFloat mutiplied = 1 - index * _scaleOffset + self.progress * _scaleOffset;
                make.size.equalTo(self).multipliedBy(mutiplied);
                CGPoint translation = CGPointMake(0, index * _translationYOffset - self.progress * _translationYOffset);
                make.center.centerOffset(translation);
            }];
        }
    }];
    
    
    
    [super updateConstraints];
}



- (CGRect)frameAtIdx:(NSInteger)idx{
    return [self frameAtIdx:idx progress:0];
}

- (CGRect)frameAtIdx:(NSInteger)idx progress:(CGFloat)progress{
    if (0 == progress && idx == _maxCardItemCount) {
        idx--;
    }
    
    return CGRectMake(0, idx * _translationYOffset, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));

}



- (__kindof UIView *)dequeueReuseableCardItemViewWithIdentifier:(NSString *)identifier{
    
    NSAssert(identifier.length, @"identifier必须有值");
    
    NSMutableArray <__kindof UIView *> *reusebleItemViews = self.reusebleItemViews[identifier];
    if (!reusebleItemViews) {
        reusebleItemViews = [NSMutableArray array];
        self.reusebleItemViews[identifier] = reusebleItemViews;
    }
    
    UIView *itemView = [reusebleItemViews jc_dequeue];
    if (!itemView) {
        itemView = [[self.registerdItemClazz[identifier] alloc] init];
        itemView.jc_internalIdentifier = identifier;
    }
    return itemView;
}

- (void)registerCardItemViewClass:(Class)clazz forIdentifier:(NSString *)identifier{
    NSAssert(identifier.length, @"identifier必须有值");
    
    self.registerdItemClazz[identifier] = clazz;
}

- (NSMutableArray<UIView *> *)itemViews{
    if (!_itemViews) {
        _itemViews = [NSMutableArray array];
    }
    return _itemViews;
}

- (NSMutableDictionary<NSString *,Class> *)registerdItemClazz{
    if (!_registerdItemClazz) {
        _registerdItemClazz = [NSMutableDictionary dictionary];
    }
    return _registerdItemClazz;
}

- (NSMutableDictionary<NSString *,NSMutableArray<UIView *> *> *)reusebleItemViews{
    if (!_reusebleItemViews) {
        _reusebleItemViews = [NSMutableDictionary dictionary];
    }
    return _reusebleItemViews;
}

- (NSMutableArray<JCUndoState *> *)undoStack{
    if (!_undoStack) {
        _undoStack = [NSMutableArray array];
    }
    return _undoStack;
}

@end
