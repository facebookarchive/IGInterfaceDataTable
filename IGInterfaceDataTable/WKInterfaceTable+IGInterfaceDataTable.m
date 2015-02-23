/*
 *  Copyright (c) 2015, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "WKInterfaceTable+IGInterfaceDataTable.h"

#import <objc/runtime.h>


@interface IGTableRowData : NSObject
@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, assign, readonly) NSIndexPath *indexPath;
@end

@implementation IGTableRowData

- (instancetype)initWithIdentifier:(NSString *)identifier indexPath:(NSIndexPath *)indexPath {
  if (self = [super init]) {
    _identifier = identifier;
    _indexPath = indexPath;
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"identifier: %@, section: %zi: row: %zi",self.identifier,self.indexPath.section,self.indexPath.row];
}

@end

@implementation WKInterfaceTable (IGInterfaceDataTable)

// lazy flagging for section headers
static NSInteger const kRNTableSectionHeaderIndex = NSNotFound;

- (void)reloadData {
  id<IGInterfaceTableDataSource> dataSource = self.ig_dataSource;
  if (!dataSource) {
    NSLog(@"Calling reloadData on a WKInterfaceTable without setting ig_dataSource. Did you mean to do that?");
    return;
  }

  NSMutableArray *rowSectionData = [[NSMutableArray alloc] init];

  // add a table header identifier if it exists
  if ([dataSource respondsToSelector:@selector(headerIdentifierForTable:)]) {
    NSString *tableHeaderIdentifier = [dataSource headerIdentifierForTable:self];
    if (tableHeaderIdentifier) {
      IGTableRowData *rowData = [[IGTableRowData alloc] initWithIdentifier:tableHeaderIdentifier indexPath:nil];
      [rowSectionData addObject:rowData];
    }
  }

  NSInteger sections;
  if ([dataSource respondsToSelector:@selector(numberOfSectionsInTable:)]) {
    sections = [dataSource numberOfSectionsInTable:self];
  } else {
    sections = 1;
  }

  BOOL hasSectionIdentifiers = [dataSource respondsToSelector:@selector(table:identifierForSection:)];

  for (NSInteger section = 0; section < sections; section++) {
    // add the section identifier if it exists
    if (hasSectionIdentifiers) {
      NSString *sectionRowIdentifier = [dataSource table:self identifierForSection:section];
      if (sectionRowIdentifier) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:kRNTableSectionHeaderIndex inSection:section];
        IGTableRowData *rowData = [[IGTableRowData alloc] initWithIdentifier:sectionRowIdentifier indexPath:indexPath];
        [rowSectionData addObject:rowData];
      }
    }

    NSInteger rows = [dataSource numberOfRowsInTable:self section:section];
    for (NSInteger row = 0; row < rows; row++) {
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
      NSString *rowIdentifier = [dataSource table:self rowIdentifierAtIndexPath:indexPath];
      NSAssert(rowIdentifier != nil, @"Row identifiers are required and cannot be nil");
      IGTableRowData *rowData = [[IGTableRowData alloc] initWithIdentifier:rowIdentifier indexPath:indexPath];
      [rowSectionData addObject:rowData];
    }
  }

  // capture the footer for configuring when iterating over row controllers
  IGTableRowData *footerRowData;
  if ([dataSource respondsToSelector:@selector(footerIdentifierForTable:)]) {
    NSString *footerIdentifier = [dataSource footerIdentifierForTable:self];
    if (footerIdentifier) {
      footerRowData = [[IGTableRowData alloc] initWithIdentifier:footerIdentifier indexPath:nil];
      [rowSectionData addObject:footerRowData];
    }
  }

  // flattened array of only the NSString identifiers that map to row controllers
  NSArray *identifiers = [rowSectionData valueForKeyPath:@"identifier"];
  [self setRowTypes:identifiers];

  [rowSectionData enumerateObjectsUsingBlock:^(IGTableRowData *rowData, NSUInteger idx, BOOL *stop) {
    // this is directly related to the controller set in -setRowTypes:
    NSObject *controller = [self rowControllerAtIndex:idx];
    NSIndexPath *indexPath = rowData.indexPath;

    // configure the header, footer, sections, and rows only if the data source does so
    if (!indexPath) {
      if (idx == 0 && [dataSource respondsToSelector:@selector(table:configureHeaderController:)]) {
        [dataSource table:self configureHeaderController:controller];
      } else if (rowData == footerRowData
                 && [dataSource respondsToSelector:@selector(table:configureHeaderController:)]) {
        [dataSource table:self configureFooterController:controller];
      }
    } else if (indexPath.row == kRNTableSectionHeaderIndex
               && [dataSource respondsToSelector:@selector(table:configureSectionController:forSection:)]) {
      [dataSource table:self configureSectionController:controller forSection:indexPath.section];
    } else if ([dataSource respondsToSelector:@selector(table:configureRowController:forIndexPath:)]) {
      [dataSource table:self configureRowController:controller forIndexPath:indexPath];
    }
  }];

  [self setRowSectionData:rowSectionData];
}


#pragma mark - Index Conversion

- (NSIndexPath *)_indexPathFromRowIndex:(NSInteger)rowIndex {
  // remember that this will return index paths with kRNTableSectionHeaderIndex rows for section headers
  return [[self rowSectionData][rowIndex] indexPath];
}

- (NSIndexPath *)indexPathFromRowIndex:(NSInteger)rowIndex {
  NSIndexPath *indexPath = [self _indexPathFromRowIndex:rowIndex];
  // for the public method, return nil for section rows
  if (indexPath && indexPath.row == kRNTableSectionHeaderIndex) {
    return nil;
  }
  return indexPath;
}

- (NSInteger)rowIndexFromIndexPath:(NSIndexPath *)indexPath {
  __block NSInteger rowIndex = NSNotFound;
  if (indexPath) {
    [[self rowSectionData] enumerateObjectsUsingBlock:^(IGTableRowData *rowData, NSUInteger idx, BOOL *stop) {
      NSIndexPath *rowIndexPath = rowData.indexPath;
      if ([rowIndexPath isEqual:indexPath]) {
        rowIndex = idx;
        *stop = YES;
      }
    }];
  }
  return rowIndex;
}

- (NSInteger)rowIndexFromSection:(NSInteger)section {
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:kRNTableSectionHeaderIndex inSection:section];
  return [self rowIndexFromIndexPath:indexPath];
}

- (NSInteger)sectionFromRowIndex:(NSInteger)rowIndex {
  return [[[self rowSectionData][rowIndex] indexPath] section];
}


#pragma mark - Scrolling

- (void)scrollToSection:(NSInteger)section {
  NSInteger rowIndex = [self rowIndexFromSection:section];
  if (rowIndex != NSNotFound) {
    [self scrollToRowAtIndex:rowIndex];
  } else {
    // attempt to scroll to a row in the section
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    [self scrollToRowAtIndexPath:indexPath];
  }
}

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath {
  NSInteger rowIndex = [self rowIndexFromIndexPath:indexPath];
  if (rowIndex != NSNotFound) {
    [self scrollToRowAtIndex:rowIndex];
  } else {
    NSLog(@"Attempted to scroll to non-existing controller in section %zi and row %zi",indexPath.section,indexPath.row);
  }
}


#pragma mark - Headers & Footers

- (NSObject *)headerController {
  if ([self _hasHeader]) {
    return [self rowControllerAtIndex:0];
  }
  return nil;
}

- (BOOL)_hasHeader {
  return ![self.ig_dataSource respondsToSelector:@selector(headerIdentifierForTable:)]
  || [self.ig_dataSource headerIdentifierForTable:self];
}

- (NSObject *)footerController {
  if ([self _hasFooter]) {
    return [self rowControllerAtIndex:[self rowSectionData].count - 1];
  }
  return nil;
}

- (BOOL)_hasFooter {
  return ![self.ig_dataSource respondsToSelector:@selector(footerIdentifierForTable:)]
  || [self.ig_dataSource footerIdentifierForTable:self];
}


#pragma mark - Editing

- (void)insertSections:(NSIndexSet *)sections withSectionType:(NSString *)sectionType {
  NSMutableIndexSet *rowIndexes = [[NSMutableIndexSet alloc] init];
  NSMutableArray *insertedRowData = [[NSMutableArray alloc] init];

  [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL *stop) {
    NSInteger rowIndex = [self rowIndexFromSection:section];
    if (rowIndex != NSNotFound) {
      [rowIndexes addIndex:rowIndex];
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow:kRNTableSectionHeaderIndex inSection:section];
      IGTableRowData *rowData = [[IGTableRowData alloc] initWithIdentifier:sectionType indexPath:indexPath];
      [[self rowSectionData] insertObject:rowData atIndex:rowIndex];
      [insertedRowData addObject:rowData];
    }
  }];

  [self insertRowsAtIndexes:rowIndexes withRowType:sectionType];

  if ([self.ig_dataSource respondsToSelector:@selector(table:configureSectionController:forSection:)]) {
    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
      NSObject *controller = [self rowControllerAtIndex:idx];
      IGTableRowData *rowData = insertedRowData[idx];
      [self.ig_dataSource table:self configureSectionController:controller forSection:rowData.indexPath.section];
    }];
  }
}

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths withRowType:(NSString *)rowType {
  NSMutableIndexSet *rowIndexes = [[NSMutableIndexSet alloc] init];
  NSMutableArray *insertedRowData = [[NSMutableArray alloc] init];

  [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
    NSInteger rowIndex = [self rowIndexFromIndexPath:indexPath];
    if (rowIndex != NSNotFound) {
      [rowIndexes addIndex:rowIndex];
      IGTableRowData *rowData = [[IGTableRowData alloc] initWithIdentifier:rowType indexPath:indexPath];
      [[self rowSectionData] insertObject:rowData atIndex:rowIndex];
      [insertedRowData addObject:rowData];
    }
  }];

  [self insertRowsAtIndexes:rowIndexes withRowType:rowType];

  if ([self.ig_dataSource respondsToSelector:@selector(table:configureRowController:forIndexPath:)]) {
    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
      NSObject *controller = [self rowControllerAtIndex:idx];
      IGTableRowData *rowData = insertedRowData[idx];
      [self.ig_dataSource table:self configureRowController:controller forIndexPath:rowData.indexPath];
    }];
  }
}

- (void)removeSections:(NSIndexSet *)sections {
  NSMutableIndexSet *rowIndexes = [[NSMutableIndexSet alloc] init];
  NSMutableArray *rowSectionData = [self rowSectionData];

  [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL *stop) {
    NSInteger rowIndex = [self rowIndexFromSection:section];
    if (rowIndex != NSNotFound) {
      [rowIndexes addIndex:rowIndex];

      // remove all rows in the section that is being removed
      if (rowIndex < rowSectionData.count - 1) {
        NSInteger subArrayStart = rowIndex + 1;
        NSArray *subRowData = [rowSectionData subarrayWithRange:NSMakeRange(subArrayStart, rowSectionData.count - subArrayStart)];
        [subRowData enumerateObjectsUsingBlock:^(IGTableRowData *row, NSUInteger idx, BOOL *stop2) {
          if (row.indexPath.section == section) {
            [rowIndexes addIndex:idx];
          } else {
            *stop2 = YES;
          }
        }];
      }
    }
  }];

  [self removeRowsAtIndexes:rowIndexes];
  [rowSectionData removeObjectsAtIndexes:rowIndexes];
}

- (void)removeRowsAtIndexPaths:(NSArray *)indexPaths {
  NSMutableIndexSet *rowIndexes = [[NSMutableIndexSet alloc] init];

  [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
    NSInteger rowIndex = [self rowIndexFromIndexPath:indexPath];
    if (rowIndex != NSNotFound) {
      [rowIndexes addIndex:rowIndex];
    }
  }];

  [self removeRowsAtIndexes:rowIndexes];
  [[self rowSectionData] removeObjectsAtIndexes:rowIndexes];
}


#pragma mark - Associated Objects

- (id<IGInterfaceTableDataSource>)ig_dataSource {
  return objc_getAssociatedObject(self, @selector(ig_dataSource));
}

- (void)setIg_dataSource:(id<IGInterfaceTableDataSource>)dataSource {
  objc_setAssociatedObject(self, @selector(ig_dataSource), dataSource, OBJC_ASSOCIATION_ASSIGN);
}

- (NSMutableArray *)rowSectionData {
  return objc_getAssociatedObject(self, @selector(rowSectionData));
}

- (void)setRowSectionData:(NSMutableArray *)rowSectionData {
  objc_setAssociatedObject(self, @selector(rowSectionData), rowSectionData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
