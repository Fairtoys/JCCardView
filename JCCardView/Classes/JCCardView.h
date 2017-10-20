//
//  JCCardView.h
//  JCCardView
//
//  Created by Cerko on 2017/9/22.
//  Copyright © 2017年 Cerko. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 idx为0位队头和栈底
 */
@interface NSMutableArray<ObjectType> (JCQueue)


/**
 将数据从队尾移除

 @return 数据
 */
- (nullable ObjectType)jc_dequeueFromTail;
/**
 从队头插入

 @param obj 对象
 */
- (void)jc_enqueueToHead:(id)obj;
/**
 将数据加入到最末尾
 
 @param obj 数据
 */
- (void)jc_enqueue:(ObjectType)obj;

/**
 从队头移除

 @return 数据
 */
- (nullable ObjectType)jc_dequeue;


/**
 将数据加入到最末尾

 @param obj 数据
 */
- (void)jc_push:(ObjectType)obj;

/**
 移除最后一个添加进数组的数据

 @return 最后一个数据
 */
- (nullable ObjectType)jc_pop;


@end

@interface NSObject (JCEx)

/**
 用来传任意参数
 */
@property (nonatomic, strong, nullable) id jc_obj;

@end

@class JCCardView;


typedef NS_ENUM(NSInteger, JCCardViewSwipeDirection) {
    JCCardViewSwipeDirectionLeft = -1,
    JCCardViewSwipeDirectionNone = 0,
    JCCardViewSwipeDirectionRight = 1
};

typedef __kindof UIView * _Nullable (^JCCardViewGetItemViewBlock)(JCCardView *cardView, NSInteger idx);
typedef void (^JCCardViewItemOptionBlock)(JCCardView *cardView, __kindof UIView *itemView, NSInteger idx);
typedef BOOL (^JCCardViewCanAnimationBlock)(JCCardView *cardView, __kindof UIView *itemView, NSInteger idx, JCCardViewSwipeDirection direction);
typedef void (^JCCardViewItemHandleBlock)(JCCardView *cardView, __kindof UIView *itemView, NSInteger idx, JCCardViewSwipeDirection direction);
typedef void (^JCCardViewProgressingBlock)(JCCardView *cardView, __kindof UIView *itemView, NSInteger idx, CGFloat progress);


@interface JCCardView : UIView



#pragma mark - 卡片参数
/**
 Default 0.1 卡片间的放大倍数
 */
@property (nonatomic, assign) CGFloat scaleOffset;

/**
 Default 5 两个卡片的上下间距
 */
@property (nonatomic, assign) CGFloat translationYOffset;


/**
 Default ((10) / 180.0 * M_PI) 卡片滑动时的最大角度
 */
@property (nonatomic, assign) CGFloat maxRadius;


/**
 被移除视图相对于容器视图的中心的偏移位置 Default { 400, 100 }
 */
@property (nonatomic, assign) CGPoint translationForRemovingItem;


/**
 所有的动画时长 Default 0.25
 */
@property (nonatomic, assign) CGFloat animationDuration;

/**
 超过这个距离就会发生左右移除，没超过就会恢复 Defaulut 100.f
 */
@property (nonatomic, assign) CGFloat maxDetectiveDistance;


#pragma mark - 当前状态相关

/**
 当前滑动方向
 */
@property (nonatomic, readonly) JCCardViewSwipeDirection direction;
/**
 最大的卡片显示数目
 */
@property (nonatomic, assign) NSUInteger maxCardItemCount;


/**
 已加载的数据的计数,加载一个View，自加1,你可以随便设，下一个要回调的时候就传回该索引
 */
@property (nonatomic, assign) NSInteger willLoadingItemIdx;


/**
 当前显示的视图的索引
 */
@property (nonatomic, assign) NSInteger currentShowingItemIdx;



#pragma mark - callbacks 回调
/**
 获取ItemView的回调
 */
@property (nonatomic, copy, nullable) JCCardViewGetItemViewBlock cardItemGetBlock;


/**
 当点击卡片的回调
 */
@property (nonatomic, copy, nullable) JCCardViewItemOptionBlock cardItemDidClickBlock;

/**
 ItemView即将removeFromSuper的回调
 */
@property (nonatomic, copy, nullable) JCCardViewItemHandleBlock cardItemWillDisapearBlock;


/**
 ItemView 已经显示的回调
 */
@property (nonatomic, copy, nullable) JCCardViewItemOptionBlock cardItemDidApearBlock;


/**
 正在滑动中的回调
 */
@property (nonatomic, copy, nullable) JCCardViewProgressingBlock itemPanningBlock;

/**
 松手后是否自动划走或者恢复Item
 */
@property (nonatomic, copy, nullable) JCCardViewCanAnimationBlock cardItemAnimationCanBegenBlock;

/**
 将要开始划走或者恢复动画的回调
 */
@property (nonatomic, copy, nullable) JCCardViewItemHandleBlock cardItemAnimationWillBeginBlock;

/**
 继续移除或者恢复Item
 */
- (void)continueCardItemAnimation;

#pragma mark - public Methods
/**
 将ItemView的数量填满maxCardItemCount
 */
- (void)fillCardItems;


/**
 重新加载所有的Items，并将各种计数恢复为最初状态
 */
- (void)reloadCardItems;


/**
 更新当前已显示的所有的Items，计数会减去当前显示的Item数，重新开始
 */
- (void)refreshCardItems;

/**
 移除最上面的视图

 @param direction 方向
 */
- (void)swipeCardItemToDirection:(JCCardViewSwipeDirection)direction;


/**
 从滑动的状态恢复到原始状态
 */
- (void)resumeCardItems;


/**
 撤销滑动
 */
- (void)undo;

#pragma mark -重用相关

/**
 从缓存中取出ItemView,如果有的话

 @param identifier id
 @return ItemView
 */
- (nullable __kindof UIView *)dequeueReuseableCardItemViewWithIdentifier:(NSString *)identifier;


/**
 注册ItemView的Class

 @param clazz ItemView的Class
 @param identifier ItemView的id
 */
- (void)registerCardItemViewClass:(Class)clazz forIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
