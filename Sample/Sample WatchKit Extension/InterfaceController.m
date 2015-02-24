//
//  InterfaceController.m
//  RNInterfaceSectionTable WatchKit Extension
//
//  Created by Ryan Nystrom on 2/17/15.
//  Copyright (c) 2015 Ryan Nystrom. All rights reserved.
//

#import "InterfaceController.h"

#import <IGInterfaceDataTable/IGInterfaceDataTable.h>

#import "RowController.h"
#import "SectionRowController.h"


@interface InterfaceController () <IGInterfaceTableDataSource>

@property (weak, nonatomic) IBOutlet WKInterfaceTable *table;
@property (nonatomic, strong) NSArray *data;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];

  self.data = @[
                @{
                  @"title": @"Red",
                  @"items": @[@"Mollis", @"Tristique", @"Aenean"]
                  },
                @{
                  @"title": @"Purple",
                  @"items": @[@"Amet Etiam", @"Adipiscing", @"Fusce"]
                  },
                @{
                  @"title": @"Teal",
                  @"items": @[@"Sollicitudin", @"Inceptos", @"Dapibus Elit"]
                  }
                ];

  self.table.ig_dataSource = self;
  [self.table reloadData];
}


#pragma mark - Row Selection

// this is a WKInterfaceController method
- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
  NSIndexPath *indexPath = [table indexPathFromRowIndex:rowIndex];
  if (indexPath) {
    NSDictionary *sectionItem = self.data[indexPath.section];
    NSString *item = sectionItem[@"items"][indexPath.row];
    NSLog(@"tapped %@ in section %zi row %zi",item,indexPath.section,indexPath.row);
  }
}


#pragma mark - RNInterfaceTableDataSource

- (NSInteger)numberOfSectionsInTable:(WKInterfaceTable *)table {
  return self.data.count;
}

- (NSInteger)numberOfRowsInTable:(WKInterfaceTable *)table section:(NSInteger)section {
  return [self.data[section][@"items"] count];
}

- (NSString *)headerIdentifierForTable:(WKInterfaceTable *)table {
  return @"HeaderRow";
}

- (NSString *)footerIdentifierForTable:(WKInterfaceTable *)table {
  return @"Footer";
}

- (NSString *)table:(WKInterfaceTable *)table identifierForSection:(NSInteger)section {
  return @"SectionRow";
}

- (NSString *)table:(WKInterfaceTable *)table rowIdentifierAtIndexPath:(NSIndexPath *)indexPath {
  return @"Row";
}

- (void)table:(WKInterfaceTable *)table configureSectionController:(NSObject *)sectionRowController forSection:(NSInteger)section {
  NSDictionary *sectionItem = self.data[section];
  NSString *title = sectionItem[@"title"];
  SectionRowController *controller = (SectionRowController *)sectionRowController;
  [controller.textLabel setText:title];
  [controller.imageView setImageNamed:[title lowercaseString]];
}

- (void)table:(WKInterfaceTable *)table configureRowController:(NSObject *)rowController forIndexPath:(NSIndexPath *)indexPath {
  NSDictionary *sectionItem = self.data[indexPath.section];
  NSString *item = sectionItem[@"items"][indexPath.row];
  RowController *controller = (RowController *)rowController;
  [controller.textLabel setText:item];
}

@end



