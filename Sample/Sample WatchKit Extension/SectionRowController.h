//
//  SectionRowController.h
//  RNInterfaceSectionTable
//
//  Created by Ryan Nystrom on 2/18/15.
//  Copyright (c) 2015 Ryan Nystrom. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface SectionRowController : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceImage *imageView;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *textLabel;

@end
