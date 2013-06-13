#import "NVStyledView.h"
#import "BFImage.h"

#define ARROW_WIDTH 12
#define ARROW_HEIGHT 8

@interface NVBackgroundView : NVStyledView
{
    NSInteger _arrowX;
}

@property (nonatomic, assign) NSInteger arrowX;
@property (nonatomic, assign) IBOutlet NVStyledView *titlebarPointImageView;
@property (strong, atomic) BFImage *backgroundImage;

@end
