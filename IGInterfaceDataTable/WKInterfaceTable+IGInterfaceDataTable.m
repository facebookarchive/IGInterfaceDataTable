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
@property (nonatomic, assign, readonly) NSUInteger section;
@property (nonatomic, assign, readonly) NSUInteger row;
@end

@implementation IGTableRowData

- (instancetype)initWithIdentifier:(NSString *)identifier {
  return [self initWithIdentifier:identifier section:NSNotFound row:NSNotFound];
}

- (instancetype)initWithIdentifier:(NSString *)identifier section:(NSUInteger)section {
  return [self initWithIdentifier:identifier section:section row:NSNotFound];
}

- (instancetype)initWithIdentifier:(NSString *)identifier section:(NSUInteger)section row:(NSUInteger)row {
  if (self = [super init]) {
    _identifier = identifier;
    _section = section;
    _row = row;
  }
  return self;
}

- (BOOL)isEqual:(id)object {
  if ([object isKindOfClass:IGTableRowData.class]) {
    IGTableRowData *data = (IGTableRowData *)object;
    return ((!self.identifier && !data.identifier) || [self.identifier isEqualToString:data.identifier])
    && self.section == data.section && self.row == data.row;
  } else {
    return NO;
  }
}

- (NSUInteger)hash {
  return [self.identifier hash] ^ self.section ^ self.row;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%p %@: identifier = %@; section = %zi; row = %zi>",
          self, NSStringFromClass(self.class), self.identifier, self.section, self.row];
}

@end


#pragma mark - IGInterfaceDataTable

@implementation WKInterfaceTable (IGInterfaceDataTable)

- (BOOL)isUpdating {
  NSNumber *number = objc_getAssociatedObject(self, @selector(isUpdating));
  return [number boolValue];
}

- (void)setIsUpdating:(BOOL)updating {
  NSNumber *number = [NSNumber numberWithBool:updating];
  objc_setAssociatedObject(self, @selector(isUpdating), number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray *)rowIndexesToAdd {
  return objc_getAssociatedObject(self, @selector(rowIndexesToAdd));
}

- (void)setRowIndexesToAdd:(NSMutableArray *)rowIndexesToAdd {
  objc_setAssociatedObject(self, @selector(rowIndexesToAdd), rowIndexesToAdd, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)rowTypesToAdd {
  return objc_getAssociatedObject(self, @selector(rowTypesToAdd));
}

- (void)setRowTypesToAdd:(NSMutableDictionary *)rowTypesToAdd {
  objc_setAssociatedObject(self, @selector(rowTypesToAdd), rowTypesToAdd, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)reloadData {
  NSArray *rowSectionData = [self rowSectionDataForDataSource:[self ig_dataSource]];
  [self syncRowSectionData:rowSectionData];
  [self configureRowSectionData:rowSectionData];
  [self setRowSectionData:rowSectionData];
}

- (NSArray *)rowSectionDataForDataSource:(id<IGInterfaceTableDataSource>)dataSource {
  NSAssert(dataSource != nil, @"Calling reloadData on a WKInterfaceTable without setting ig_dataSource. Did you mean to do that?");

  NSMutableArray *rowSectionData = [[NSMutableArray alloc] init];

  // add a table header identifier if it exists
  if ([dataSource respondsToSelector:@selector(headerIdentifierForTable:)]) {
    NSString *tableHeaderIdentifier = [dataSource headerIdentifierForTable:self];
    if (tableHeaderIdentifier) {
      IGTableRowData *rowData = [[IGTableRowData alloc] initWithIdentifier:tableHeaderIdentifier];
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
        IGTableRowData *rowData = [[IGTableRowData alloc] initWithIdentifier:sectionRowIdentifier section:section];
        [rowSectionData addObject:rowData];
      }
    }

    NSInteger rows = [dataSource numberOfRowsInTable:self section:section];
    for (NSInteger row = 0; row < rows; row++) {
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
      NSString *rowIdentifier = [dataSource table:self rowIdentifierAtIndexPath:indexPath];
      NSAssert(rowIdentifier != nil, @"Row identifiers are required and cannot be nil");
      IGTableRowData *rowData = [[IGTableRowData alloc] initWithIdentifier:rowIdentifier section:section row:row];
      [rowSectionData addObject:rowData];
    }
  }

  // capture the footer for configuring when iterating over row controllers
  if ([dataSource respondsToSelector:@selector(footerIdentifierForTable:)]) {
    NSString *footerIdentifier = [dataSource footerIdentifierForTable:self];
    if (footerIdentifier) {
      IGTableRowData *footerRowData = [[IGTableRowData alloc] initWithIdentifier:footerIdentifier];
      [rowSectionData addObject:footerRowData];
    }
  }

  return rowSectionData;
}

- (void)syncRowSectionData:(NSArray *)rowSectionData {
  // flattened array of only the NSString identifiers that map to row controllers
  NSArray *identifiers = [rowSectionData valueForKeyPath:@"identifier"];
  [self setRowTypes:identifiers];
}

- (void)configureRowSectionData:(NSArray *)rowSectionData {
  id<IGInterfaceTableDataSource> dataSource = self.ig_dataSource;

  [rowSectionData enumerateObjectsUsingBlock:^(IGTableRowData *rowData, NSUInteger idx, BOOL *stop) {
    // this is directly related to the controller set in -setRowTypes:
    NSObject *controller = [self rowControllerAtIndex:idx];
    NSIndexPath *indexPath = nil;
    if (rowData.section != NSNotFound) {
      indexPath = [NSIndexPath indexPathForRow:rowData.row inSection:rowData.section];
    }

    // configure the header, footer, sections, and rows only if the data source does so
    if (!indexPath) {
      if (idx == 0 && [dataSource respondsToSelector:@selector(table:configureHeaderController:)]) {
        [dataSource table:self configureHeaderController:controller];
      } else if ([dataSource respondsToSelector:@selector(table:configureFooterController:)]) {
        [dataSource table:self configureFooterController:controller];
      }
    } else if (indexPath.row == NSNotFound
               && [dataSource respondsToSelector:@selector(table:configureSectionController:forSection:)]) {
      [dataSource table:self configureSectionController:controller forSection:indexPath.section];
    } else if ([dataSource respondsToSelector:@selector(table:configureRowController:forIndexPath:)]) {
      [dataSource table:self configureRowController:controller forIndexPath:indexPath];
    }
  }];
}

- (NSArray *)smoothedRowSectionData:(NSArray *)rowSectionData {
  NSMutableArray *mRowSectionData = [[NSMutableArray alloc] initWithCapacity:rowSectionData.count];
  NSUInteger runningSection = 0, previousSection = 0, runningRow = 0, previousRow = 0;

  IGTableRowData *firstRowData = [rowSectionData firstObject];
  previousSection = firstRowData.section;
  previousRow = firstRowData.row;

  for (IGTableRowData *rowData in rowSectionData) {
    NSUInteger section = rowData.section;
    NSUInteger row = rowData.row;

    // header-header trumps all
    if (section < NSNotFound) {

      // do not increment if previous was a header-header
      if (section != previousSection && previousSection != NSNotFound) {
        // starting a new section
        runningSection++;
        runningRow = 0;
      }

      section = runningSection;

      // section-header trumps row
      if (row < NSNotFound) {
        row = runningRow;
        runningRow++;
      }
    }

    previousSection = rowData.section;
    previousRow = rowData.row;

    IGTableRowData *newRowData = [[IGTableRowData alloc] initWithIdentifier:rowData.identifier section:section row:row];
    [mRowSectionData addObject:newRowData];
  }
  return [mRowSectionData copy];
}


#pragma mark - Index Conversion

- (NSIndexPath *)_indexPathFromRowIndex:(NSInteger)rowIndex {
  IGTableRowData *rowData = [self rowSectionData][rowIndex];
  return [NSIndexPath indexPathForRow:rowData.row inSection:rowData.section];
}

- (NSIndexPath *)indexPathFromRowIndex:(NSInteger)rowIndex {
  NSIndexPath *indexPath = [self _indexPathFromRowIndex:rowIndex];
  // for the public method, return nil for section rows
  if (indexPath && indexPath.row == NSNotFound) {
    return nil;
  }
  return indexPath;
}

- (NSInteger)rowIndexFromIndexPath:(NSIndexPath *)indexPath {
  NSAssert(indexPath != nil, @"Cannot search for a nil indexPath");
  __block NSInteger rowIndex = NSNotFound;
  if (indexPath) {
    [[self rowSectionData] enumerateObjectsUsingBlock:^(IGTableRowData *rowData, NSUInteger idx, BOOL *stop) {
      if (indexPath.row == rowData.row && indexPath.section == rowData.section) {
        rowIndex = idx;
        *stop = YES;
      }
    }];
  }
  return rowIndex;
}

- (NSInteger)rowIndexFromSection:(NSInteger)section {
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:section];
  return [self rowIndexFromIndexPath:indexPath];
}

- (NSInteger)sectionFromRowIndex:(NSInteger)rowIndex {
  return [[self rowSectionData][rowIndex] section];
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

- (void)updateRowWithIndexPath:(NSIndexPath *)indexPath {
  NSInteger row = [self rowIndexFromIndexPath:indexPath];
  NSObject *controller = [self rowControllerAtIndex:row];
  [self.ig_dataSource table:self configureRowController:controller forIndexPath:indexPath];
}

- (void)insertSections:(NSIndexSet *)sections withSectionType:(NSString *)sectionType {
  NSArray *rowSectionData = [self rowSectionDataForDataSource:[self ig_dataSource]];
  [self setRowSectionData:rowSectionData];

  NSMutableIndexSet *rowIndexes = [[NSMutableIndexSet alloc] init];

  [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL *stop) {
    NSInteger rowIndex = [self rowIndexFromSection:section];
    if (rowIndex != NSNotFound) {
      [rowIndexes addIndex:rowIndex];
    }
  }];

  [self insertRowsAtIndexes:rowIndexes withRowType:sectionType];

  if ([self.ig_dataSource respondsToSelector:@selector(table:configureSectionController:forSection:)]) {
    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
      NSObject *controller = [self rowControllerAtIndex:idx];
      IGTableRowData *rowData = rowSectionData[idx];
      [self.ig_dataSource table:self configureSectionController:controller forSection:rowData.section];
    }];
  }
}

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths withRowType:(NSString *)rowType {
  if(self.isUpdating) {
    [self.rowIndexesToAdd addObjectsFromArray:indexPaths];
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
      [self.rowTypesToAdd setObject:rowType forKey:indexPath];
    }];
    return;
  }

  NSArray *rowSectionData = [self rowSectionDataForDataSource:[self ig_dataSource]];
  [self setRowSectionData:rowSectionData];

  NSMutableIndexSet *rowIndexes = [[NSMutableIndexSet alloc] init];

  [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
    NSInteger rowIndex = [self rowIndexFromIndexPath:indexPath];
    if (rowIndex != NSNotFound) {
      [rowIndexes addIndex:rowIndex];
    }
  }];

  [self insertRowsAtIndexes:rowIndexes withRowType:rowType];

  if ([self.ig_dataSource respondsToSelector:@selector(table:configureRowController:forIndexPath:)]) {
    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
      NSObject *controller = [self rowControllerAtIndex:idx];
      IGTableRowData *rowData = rowSectionData[idx];
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowData.row inSection:rowData.section];
      [self.ig_dataSource table:self configureRowController:controller forIndexPath:indexPath];
    }];
  }
}

- (void)beginUpdates {
  self.isUpdating = true;
  self.rowIndexesToAdd = [[NSMutableArray alloc] init];
  self.rowTypesToAdd = [[NSMutableDictionary alloc] init];
}

- (void)endUpdates {
  NSAssert(self.isUpdating, @"Calling -endUpdates without first calling -beginUpdates.");

  if(!self.isUpdating) {
    return;
  }

  [self.rowIndexesToAdd sortUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {
    NSInteger r1 = [obj1 row];
    NSInteger r2 = [obj2 row];
    if (r1 > r2) {
      return NSOrderedDescending;
    }
    if (r1 < r2) {
      return NSOrderedAscending;
    }
    return NSOrderedSame;
  }];

  self.isUpdating = false;

  [self.rowIndexesToAdd enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
    [self insertRowsAtIndexPaths:@[indexPath] withRowType:self.rowTypesToAdd[indexPath]];
  }];

  self.rowIndexesToAdd = nil;
  self.rowTypesToAdd = nil;
}

- (void)removeSections:(NSIndexSet *)sections {
  NSMutableIndexSet *rowIndexes = [[NSMutableIndexSet alloc] init];
  NSArray *originalRowSectionData = [self rowSectionData];
  NSUInteger count = originalRowSectionData.count;

  [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL *stop) {
    NSInteger rowIndex = [self rowIndexFromSection:section];
    if (rowIndex != NSNotFound) {
      [rowIndexes addIndex:rowIndex];

      // remove all rows in the section that is being removed
      if (rowIndex < originalRowSectionData.count - 1) {
        NSInteger subArrayStart = rowIndex + 1;
        NSArray *subRowData = [originalRowSectionData subarrayWithRange:NSMakeRange(subArrayStart, count - subArrayStart)];
        [subRowData enumerateObjectsUsingBlock:^(IGTableRowData *row, NSUInteger idx, BOOL *stop2) {
          if (row.section == section) {
            [rowIndexes addIndex:subArrayStart + idx];
          } else {
            *stop2 = YES;
          }
        }];
      }
    }
  }];

  [self removeRowsAtIndexes:rowIndexes];

  NSMutableArray *mRowSectionData = [[self rowSectionData] mutableCopy];
  [mRowSectionData removeObjectsAtIndexes:rowIndexes];

  [self setRowSectionData:[self smoothedRowSectionData:mRowSectionData]];
}

- (void)removeRowsAtIndexPaths:(NSArray *)indexPaths {
  NSMutableIndexSet *rowIndexes = [[NSMutableIndexSet alloc] init];

  [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
    NSInteger rowIndex = [self rowIndexFromIndexPath:indexPath];
    [rowIndexes addIndex:rowIndex];
  }];

  [self removeRowsAtIndexes:rowIndexes];

  NSMutableArray *mRowSectionData = [[self rowSectionData] mutableCopy];
  [mRowSectionData removeObjectsAtIndexes:rowIndexes];

  [self setRowSectionData:[self smoothedRowSectionData:mRowSectionData]];
}


#pragma mark - Associated Objects

- (id<IGInterfaceTableDataSource>)ig_dataSource {
  return objc_getAssociatedObject(self, @selector(ig_dataSource));
}

- (void)setIg_dataSource:(id<IGInterfaceTableDataSource>)dataSource {
  objc_setAssociatedObject(self, @selector(ig_dataSource), dataSource, OBJC_ASSOCIATION_ASSIGN);
}

- (NSArray *)rowSectionData {
  return objc_getAssociatedObject(self, @selector(rowSectionData));
}

- (void)setRowSectionData:(NSArray *)rowSectionData {
  objc_setAssociatedObject(self, @selector(rowSectionData), rowSectionData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


#pragma mark - WKInterfaceController Swizzling

@implementation WKInterfaceController (IGInterfaceDataTable)

+ (void)load {
  Class klass = self.class;
  SEL originalSelector = @selector(table:didSelectRowAtIndex:);
  SEL swizzledSelector = @selector(ig_table:didSelectRowAtIndex:);

  Method originalMethod = class_getInstanceMethod(klass, originalSelector);
  Method swizzledMethod = class_getInstanceMethod(klass, swizzledSelector);

  BOOL didAddMethod = class_addMethod(klass,
                                      originalSelector,
                                      method_getImplementation(swizzledMethod),
                                      method_getTypeEncoding(swizzledMethod));

  if (didAddMethod) {
    class_replaceMethod(klass,
                        swizzledSelector,
                        method_getImplementation(originalMethod),
                        method_getTypeEncoding(originalMethod));
  } else {
    method_exchangeImplementations(originalMethod, swizzledMethod);
  }
}

- (void)ig_table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
  [self ig_table:table didSelectRowAtIndex:rowIndex];

  NSIndexPath *indexPath = [table indexPathFromRowIndex:rowIndex];
  NSUInteger section = [table sectionFromRowIndex:rowIndex];

  if (indexPath) {
    [self table:table didSelectRowAtIndexPath:indexPath];
  } else if (section != NSNotFound) {
    [self table:table didSelectSection:section];
  } else if ([table _hasHeader] && rowIndex == 0) {
    [self tableDidSelectHeader:table];
  } else if ([table _hasFooter] && rowIndex == [table numberOfRows]) {
    [self tableDidSelectFooter:table];
  }
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // for subclassing
}

- (void)table:(WKInterfaceTable *)table didSelectSection:(NSInteger)section {
  // for subclassing
}

- (void)tableDidSelectHeader:(WKInterfaceTable *)table {
  // for subclassing
}

- (void)tableDidSelectFooter:(WKInterfaceTable *)table {
  // for subclassing
}

@end
