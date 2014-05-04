#import "NVStyledView.h"
#import "BFImage.h"

#define ARROW_WIDTH 12
#define ARROW_HEIGHT 8
#define HEADER_HEIGHT 34

@interface NVBackgroundView : NVStyledView
{
    NSInteger _arrowX;
}

@property (nonatomic, assign) NSInteger arrowX;
@property (nonatomic, assign) IBOutlet NVStyledView *titlebarPointImageView;
@property (nonatomic, strong) BFImage *backgroundImage;

@end
