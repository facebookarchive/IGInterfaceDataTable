/*
 *  Copyright (c) 2015, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "InterfaceController.h"

#import <IGInterfaceDataTable/IGInterfaceDataTable.h>


@interface InterfaceController () <IGInterfaceTableDataSource>

@property (weak, nonatomic) IBOutlet WKInterfaceTable *table;
@property (nonatomic, assign) BOOL showsHeader;
@property (nonatomic, assign) BOOL showsFooter;
@property (nonatomic, assign) BOOL showsSections;
@property (nonatomic, strong) NSMutableArray *sections;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];

  // Test empty table
  self.table.ig_dataSource = self;
  [self.table reloadData];
  NSAssert([self.table numberOfRows] == 0, @"Table should be empty when there are no rows, sections, headers, and footers");

  // Test table header
  self.showsHeader = YES;
  [self.table reloadData];
  NSAssert([self.table numberOfRows] == 1, @"Table did not display the header");

  // Test table footer
  self.showsFooter = YES;
  [self.table reloadData];
  NSAssert([self.table numberOfRows] == 2, @"Table did not display the footer");

  // Test table rows
  self.sections = [@[@1] mutableCopy];
  [self.table reloadData];
  NSAssert([self.table numberOfRows] == 3, @"Table did not display a row");

  // Test table section headers
  self.showsSections = YES;
  [self.table reloadData];
  NSAssert([self.table numberOfRows] == 4, @"Table did not display a section header");

  // Test complex table with header, footer, rows, and section headers
  self.sections = [@[@1, @2, @3] mutableCopy];
  [self.table reloadData];
  NSAssert([self.table numberOfRows] == 11, @"Complex data table rows are not correct");

  // Test remove rows
  [self.table removeRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]]];
  NSAssert([self.table numberOfRows] == 10, @"Removing a row did not update actually remove the row controller");

  // Test remove sections
  [self.table removeSections:[NSIndexSet indexSetWithIndex:2]];
  NSAssert([self.table numberOfRows] == 6, @"Removing a section did not update the table rows correctly");

  // Test inserting a row
  [self.table insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowType:@"Row"];
  NSAssert([self.table numberOfRows] == 7, @"Adding a row did not increase the number of row controllers");

  // Test inserting a section
  [self.table insertSections:[NSIndexSet indexSetWithIndex:2] withSectionType:@"SectionRow"];
  NSAssert([self.table numberOfRows] == 8, @"Adding a section did not increase the number of row controllers");

  // Test index path of header
  NSIndexPath *indexPath1 = [self.table indexPathFromRowIndex:0];
  NSAssert(indexPath1 == nil, @"Should not get an indexPath when there is a header");

  // Test index path of actual row
  NSIndexPath *indexPath2 = [self.table indexPathFromRowIndex:2];
  NSAssert(indexPath2.row == 0 && indexPath2.section == 0, @"Index path not correct for first real row");

  NSLog(@"If you've made it this far, the tests passed!");
}


#pragma mark - RNInterfaceTableDataSource

- (NSInteger)numberOfSectionsInTable:(WKInterfaceTable *)table {
  return self.sections.count;
}

- (NSInteger)numberOfRowsInTable:(WKInterfaceTable *)table section:(NSInteger)section {
  return [self.sections[section] integerValue];
}

- (NSString *)headerIdentifierForTable:(WKInterfaceTable *)table {
  return self.showsHeader ? @"HeaderRow" : nil;
}

- (NSString *)footerIdentifierForTable:(WKInterfaceTable *)table {
  return self.showsFooter ? @"FooterRow" : nil;
}

- (NSString *)table:(WKInterfaceTable *)table identifierForSection:(NSInteger)section {
  return self.showsSections ? @"SectionRow" : nil;
}

- (NSString *)table:(WKInterfaceTable *)table rowIdentifierAtIndexPath:(NSIndexPath *)indexPath {
  return @"Row";
}

@end



