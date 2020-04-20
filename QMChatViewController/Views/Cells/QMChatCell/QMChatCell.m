//
//  QMChatCell.m
//  QMChatViewController
//
//  Created by Andrey Ivanov on 14.05.15.
//  Copyright (c) 2015 QuickBlox Team. All rights reserved.
//

#import "QMChatCell.h"
#import "QMChatCellLayoutAttributes.h"
#import "TTTAttributedLabel.h"
#import "QMImageView.h"
#import "QMChatResources.h"

@interface TTTAttributedLabel(PrivateAPI)
- (TTTAttributedLabelLink *)linkAtPoint:(CGPoint)point;
@end

static NSMutableSet *_qmChatCellMenuActions = nil;



@interface QMChatCell() <QMImageViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet QMChatContainerView *containerView;
@property (weak, nonatomic) IBOutlet UIView *messageContainer;

@property (weak, nonatomic) IBOutlet QMImageView *avatarView;
@property (weak, nonatomic) IBOutlet UIImageView *ImageMsgDelivery;

@property (weak, nonatomic) IBOutlet TTTAttributedLabel *textView;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *topLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *bottomLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *destructLabel;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerWidthConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageContainerTopInsetConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageContainerLeftInsetConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageContainerBottomInsetConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageContainerRightInsetConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarContainerViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarContainerViewHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *destructLabelHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewBottomLabelVerticalSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topLabelTextViewVerticalSpaceConstraint;

@property (weak, nonatomic, readwrite) UITapGestureRecognizer *tapGestureRecognizer;



@end

@implementation QMChatCell




//MARK: - Class methods
+ (void)initialize {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _qmChatCellMenuActions = [NSMutableSet new];
    });
    
}

+ (void)registerForReuseInView:(id)dataView {
    
    NSString *cellIdentifier = [self cellReuseIdentifier];
    NSParameterAssert(cellIdentifier);
    
    UINib *nib = [self nib];
    NSParameterAssert(nib);
    
    
    if ([dataView isKindOfClass:[UITableView class]]) {
        
        [(UITableView *)dataView registerNib:nib forCellReuseIdentifier:cellIdentifier];
    }
    else if ([dataView isKindOfClass:[UICollectionView class]]) {
        
        [(UICollectionView *)dataView registerNib:nib forCellWithReuseIdentifier:cellIdentifier];
    }
    else {
        NSAssert(NO, @"Trying to register cell for unsupported dataView");
    }
}

+ (UINib *)nib {
    
    
    return [QMChatResources nibWithNibName:NSStringFromClass([self class])];
}

+ (NSString *)cellReuseIdentifier {
    
    return NSStringFromClass([self class]);
}

+ (void)registerMenuAction:(SEL)action {
    
    [_qmChatCellMenuActions addObject:NSStringFromSelector(action)];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.avatarView.delegate = self;
    self.contentView.opaque = YES;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    _messageContainerTopInsetConstraint.constant = 0;
    _messageContainerLeftInsetConstraint.constant = 0;
    _messageContainerBottomInsetConstraint.constant = 0;
    _messageContainerRightInsetConstraint.constant = 0;
    
    _avatarContainerViewWidthConstraint.constant = 0;
    _avatarContainerViewHeightConstraint.constant = 0;
    
    _topLabelHeightConstraint.constant = 0;
    _bottomLabelHeightConstraint.constant = 0;
    _destructLabelHeightConstraint.constant = 0;
    
    _topLabelTextViewVerticalSpaceConstraint.constant = 0;
    _textViewBottomLabelVerticalSpaceConstraint.constant = 0;
    
#if Q_DEBUG_COLORS == 0
    self.backgroundColor = [UIColor clearColor];
    self.messageContainer.backgroundColor = [UIColor clearColor];
    self.topLabel.backgroundColor = [UIColor clearColor];
    self.textView.backgroundColor = [UIColor clearColor];
    self.bottomLabel.backgroundColor = [UIColor clearColor];
    self.containerView.backgroundColor = [UIColor clearColor];
    self.avatarView.backgroundColor = [UIColor clearColor];
    
#endif

    [self.layer setDrawsAsynchronously:YES];
    
    self.avatarView.imageViewType = QMImageViewTypeCircle;
    
    UITapGestureRecognizer *tap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tap.delegate = self;
    [self addGestureRecognizer:tap];
    self.tapGestureRecognizer = tap;
    
    _arrMutableTime = [[NSMutableArray alloc] init];
    _arrMutableMsgid = [[NSMutableArray alloc] init];
}

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    return layoutAttributes;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    
    QMChatCellLayoutAttributes *customAttributes = (id)layoutAttributes;
    
    [self updateConstraint:self.avatarContainerViewHeightConstraint
              withConstant:customAttributes.avatarSize.height];
    
    [self updateConstraint:self.avatarContainerViewWidthConstraint
              withConstant:customAttributes.avatarSize.width];
    
    [self updateConstraint:self.topLabelHeightConstraint
              withConstant:customAttributes.topLabelHeight];
    
    [self updateConstraint:self.bottomLabelHeightConstraint
              withConstant:customAttributes.bottomLabelHeight];
    
    [self updateConstraint:self.destructLabelHeightConstraint
           withConstant:customAttributes.destructLabelHeight];
    
   [self updateConstraint:self.messageContainerTopInsetConstraint
              withConstant:customAttributes.containerInsets.top];
    
    [self updateConstraint:self.messageContainerLeftInsetConstraint
              withConstant:customAttributes.containerInsets.left];
    
    [self updateConstraint:self.messageContainerBottomInsetConstraint
              withConstant:customAttributes.containerInsets.bottom];
    
    [self updateConstraint:self.messageContainerRightInsetConstraint
              withConstant:customAttributes.containerInsets.right];
    
    [self updateConstraint:self.topLabelTextViewVerticalSpaceConstraint
              withConstant:customAttributes.spaceBetweenTopLabelAndTextView];
    
    [self updateConstraint:self.textViewBottomLabelVerticalSpaceConstraint
              withConstant:customAttributes.spaceBetweenTextViewAndBottomLabel];
    
    [self updateConstraint:self.containerWidthConstraint
              withConstant:customAttributes.containerSize.width];
    
    
    [self layoutIfNeeded];
}

- (void)updateConstraint:(NSLayoutConstraint *)constraint withConstant:(CGFloat)constant {
    
    if ((int)constraint.constant == (int)constant) {
        return;
    }
    
    //NSLog(@"ConstraintCell:%f",constant);
    constraint.constant = constant;
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    
    if ([[UIDevice currentDevice].systemVersion compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending) {
        [self layoutIfNeeded];
        self.contentView.frame = bounds;
    }
}

- (void)setSelected:(BOOL)selected {
    
    [super setSelected:selected];
    self.containerView.highlighted = selected;
}

//MARK: - Menu actions
- (BOOL)respondsToSelector:(SEL)aSelector {
    
    if ([_qmChatCellMenuActions containsObject:NSStringFromSelector(aSelector)]) {
        return YES;
    }
    
    return [super respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    
    if ([_qmChatCellMenuActions containsObject:NSStringFromSelector(anInvocation.selector)]) {
        
        __unsafe_unretained id sender;
        [anInvocation getArgument:&sender atIndex:0];
        
        if ([self.delegate respondsToSelector:@selector(chatCell:didPerformAction:withSender:)]) {
            
            [self.delegate chatCell:self didPerformAction:anInvocation.selector withSender:sender];
        }
    }
    
    else {
        [super forwardInvocation:anInvocation];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if ([_qmChatCellMenuActions containsObject:NSStringFromSelector(aSelector)]) {
        return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
    }
    
    return [super methodSignatureForSelector:aSelector];
}

//MARK: - Gesture recognizers

- (void)imageViewDidTap:(QMImageView *)imageView {
    [self.delegate chatCellDidTapAvatar:self];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)tap {

    CGPoint touchPt = [tap locationInView:self];
    UIView *touchView = [tap.view hitTest:touchPt withEvent:nil];

    if ([touchView isKindOfClass:[TTTAttributedLabel class]]) {

        TTTAttributedLabel *label = (TTTAttributedLabel *)touchView;
        CGPoint translatedPoint = [label convertPoint:touchPt fromView:tap.view];

        TTTAttributedLabelLink *labelLink = [label linkAtPoint:translatedPoint];

        if (labelLink.result.numberOfRanges > 0) {
            if ([self.delegate respondsToSelector:@selector(chatCell:didTapOnTextCheckingResult:)]) {
                [self.delegate chatCell:self didTapOnTextCheckingResult:labelLink.result];
            }
            
            return;
        }
    }
    
    if (CGRectContainsPoint(self.containerView.frame, touchPt)){
        [self.delegate chatCellDidTapContainer:self];
    }
    else if ([self.delegate respondsToSelector:@selector(chatCell:didTapAtPosition:)]){
        [self.delegate chatCell:self didTapAtPosition:touchPt];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    CGPoint touchPt = [touch locationInView:gestureRecognizer.view];
    
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]){
        
        if ([touch.view isKindOfClass:[TTTAttributedLabel class]]) {
            
            TTTAttributedLabel *label = (TTTAttributedLabel *)touch.view;
            CGPoint translatedPoint = [label convertPoint:touchPt fromView:gestureRecognizer.view];
            
            TTTAttributedLabelLink *labelLink = [label linkAtPoint:translatedPoint];
            
            if (labelLink.result.numberOfRanges > 0) {
                return NO;
            }
        }

        return CGRectContainsPoint(self.containerView.frame, touchPt);
    }

    return YES;
}

//MARK: - Layout model
+ (QMChatCellLayoutModel)layoutModel {
    
    QMChatCellLayoutModel defaultLayoutModel = {
        
        .avatarSize = CGSizeMake(30, 30),
        .containerInsets = UIEdgeInsetsMake(4, 0, 4, 5),
        .containerSize = CGSizeZero,
        .topLabelHeight = 17,
        .bottomLabelHeight = 100,   //    14,
        .destructLabelHeight = 80,
        .maxWidthMarginSpace = 20,
        .maxWidth = 0
    };
    
    return defaultLayoutModel;
}

- (void)startTimerDeleteMessage:(QBChatMessage *)message:(int )pendingTime {
    
    _intseconds = pendingTime;
    
    [_timer invalidate];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                              target:self
                                            selector:@selector(handleTimer:)
                                            userInfo:message repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    
    [_timer fire];

}



- (void)handleTimer:(NSTimer*)theTimer {
    // NSLog (@"Got the message: %@", (QBChatMessage*)[theTimer userInfo]);
    
    QBChatMessage *Msgobject = (QBChatMessage*)[theTimer userInfo];
    _intseconds--;
    
    if (_intseconds >= 0){
       /*
        NSString *strTime  = [NSString stringWithFormat:@"%li",(long)_intseconds];
        NSString * JoinStr = [_updateBottomTime stringByAppendingString:@"\n\n"];
        NSString * strdestructTime = [@"Destruct in:" stringByAppendingString:strTime];
        NSString * JoinStrTime = [JoinStr stringByAppendingString:strdestructTime];
        self.bottomLabel.text = @"";
        self.bottomLabel.text  = JoinStrTime;
        */
        
        
        // NSInteger seconds = _intseconds/1000;
        // NSInteger hours = seconds/(60*60);
        
        // (totalSeconds % 3600) / 60
        
        NSInteger  minutes = (_intseconds % 3600) / 60;
        NSInteger secondsRemain = _intseconds % 60;
        
        NSString *strMinues  = [NSString stringWithFormat:@"%li",(long)minutes];
        NSString *strSeconds  = [NSString stringWithFormat:@"%li",(long)secondsRemain];
        NSString * StrTotalTime = [strMinues stringByAppendingString:@":"];
        NSString * StrFnlTime;
        
        if (minutes != nil && minutes != 0) {
            StrFnlTime = [StrTotalTime stringByAppendingString:strSeconds];
        }else{
            StrFnlTime = strSeconds;
        }
        
        //   NSString *strTime  = [NSString stringWithFormat:@"%li",(long)_intseconds];
        
        NSString * JoinStr = [_updateBottomTime stringByAppendingString:@"\n\n"];
        
        //NSString * strdestructTime = [@"Destruct in:" stringByAppendingString:strTime];
        
        NSString * strdestructTime = [@"Destruct in:" stringByAppendingString:StrFnlTime];
        
        //NSString * strdestructTime = [@"D:" stringByAppendingString:StrFnlTime];
        
        NSString * JoinStrTime = [JoinStr stringByAppendingString:strdestructTime];
        
        self.bottomLabel.text = @"";
        
        self.bottomLabel.text  = JoinStrTime;
        
    }else{
        
        [_timer invalidate];
        _dicValue = [[NSMutableDictionary alloc] init];
        [_dicValue setObject:Msgobject  forKey:@"DeleteMsg"];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"TestNotification"
         object:nil userInfo:_dicValue];
    }
}


/*

- (void)handleTimer:(NSTimer*)theTimer {
    
   // NSLog (@"Got the message: %@", (QBChatMessage*)[theTimer userInfo]);
    
    QBChatMessage *Msgobject = (QBChatMessage*)[theTimer userInfo];
    
    _intseconds--;
    
    if (_intseconds >= 0){
        
       // NSInteger seconds = _intseconds/1000;
      // NSInteger hours = seconds/(60*60);
        
       // (totalSeconds % 3600) / 60
        
        NSInteger  minutes = (_intseconds % 3600) / 60;
        
        NSInteger secondsRemain = _intseconds % 60;
        
        
        NSString *strMinues  = [NSString stringWithFormat:@"%li",(long)minutes];
        
        NSString *strSeconds  = [NSString stringWithFormat:@"%li",(long)secondsRemain];
        
        NSString * StrTotalTime = [strMinues stringByAppendingString:@":"];
        
        NSString * StrFnlTime;
        
        
        if (minutes != nil && minutes != 0) {
            StrFnlTime = [StrTotalTime stringByAppendingString:strSeconds];
        }else{
            StrFnlTime = strSeconds;
        }
        
     //   NSString *strTime  = [NSString stringWithFormat:@"%li",(long)_intseconds];
        
        NSString * JoinStr = [_updateBottomTime stringByAppendingString:@"\n\n"];
        
        //NSString * strdestructTime = [@"Destruct in:" stringByAppendingString:strTime];
        
        NSString * strdestructTime = [@"Destruct in:" stringByAppendingString:StrFnlTime];
        
        //NSString * strdestructTime = [@"D:" stringByAppendingString:StrFnlTime];
        

        NSString * JoinStrTime = [JoinStr stringByAppendingString:strdestructTime];
        
        self.bottomLabel.text = @"";
        
        self.bottomLabel.text  = JoinStrTime;
        
    }else{
        
        [_timer invalidate];
        
        _dicValue = [[NSMutableDictionary alloc] init];
        [_dicValue setObject:Msgobject  forKey:@"DeleteMsg"];

        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"TestNotification"
         object:nil userInfo:_dicValue];
    }
    
}
 
 */


@end





