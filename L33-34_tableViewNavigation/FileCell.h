//
//  FileCell.h
//  L33-34_tableViewNavigation
//
//  Created by Artsiom Dolia on 1/8/15.
//  Copyright (c) 2015 Artsiom Dolia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FileCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *fileSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *modifiedLabel;

@end
