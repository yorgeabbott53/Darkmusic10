#import "../Headers.h"

@interface PUCollectionView : UICollectionView
@end

@hook PUCollectionView

- (void)reloadData
{
       %orig;
       self.BackgroundColor = TableViewBakcgroundColor;
 }
 
 %end
