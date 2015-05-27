/*
 *  Copyright (c) 2015, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>


@protocol IGInterfaceTableDataSource <NSObject>

@required

/**
 * Tells the data source to return the number of rows in a given section of a table. (required)
 * @param table The table requesting the information.
 * @param section An index for a section in the table.
 * @return The number of rows in the section of the table.
 */
- (NSInteger)numberOfRowsInTable:(WKInterfaceTable *)table section:(NSInteger)section;

/**
 * Asks the data source for a row identifier for a particular location of the table. (required)
 * @param table The table requesting the information.
 * @param indexPath An index path locating a row in the table.
 * @return An identifier representing a row controller in the table.
 * @discussion You may return different identifiers based on your application's requirements. Identifiers must be
 * established in the storyboard that the table was initialized from. The identifier returned must not be nil.
 */
- (NSString *)table:(WKInterfaceTable *)table rowIdentifierAtIndexPath:(NSIndexPath *)indexPath;

@optional

/**
 * Asks the data source to return the number of sections in the table.
 * @param table The table requesting the information.
 * @return The number of sections in the table. The default is 1.
 */
- (NSInteger)numberOfSectionsInTable:(WKInterfaceTable *)table;

/**
 * Asks the data source to return the identifier for the header row.
 * @param table The table requesting the information.
 * @return The identifier for the header row. The default is nil.
 */
- (NSString *)headerIdentifierForTable:(WKInterfaceTable *)table;

/**
 * Asks the data source to return the identifier for the footer row.
 * @param table The table requesting the information.
 * @return The identifier for the footer row. The default is nil.
 */
- (NSString *)footerIdentifierForTable:(WKInterfaceTable *)table;

/**
 * Asks the data source to return the identifier for a section header.
 * @param table The table requesting the information.
 * @param section An index for a section in the table.
 * @return The identifier for the section header row. The default is nil.
 */
- (NSString *)table:(WKInterfaceTable *)table identifierForSection:(NSInteger)section;

/**
 * Asks the data source to configure a header row controller.
 * @param table The table requesting the information.
 * @param headerController The row controller created by the table.
 * @discussion The class of the headerController will correspond to the class of the row controller configured in
 * your storyboard with the identifier returned by -headerIdentifierForTable:. If -headerIdentifierForTable: is not
 * implemented, this method is never called.
 */
- (void)table:(WKInterfaceTable *)table configureHeaderController:(NSObject *)headerController;

/**
 * Asks the data source to configure a footer row controller.
 * @param table The table requesting the information.
 * @param footerController The row controller created by the table.
 * @discussion The class of the footerController will correspond to the class of the row controller configured in
 * your storyboard with the identifier returned by -footerIdentifierForTable:. If -footerIdentifierForTable: is not
 * implemented, this method is never called.
 */
- (void)table:(WKInterfaceTable *)table configureFooterController:(NSObject *)footerController;

/**
 * Asks the data source to configure a section header row controller.
 * @param table The table requesting the information.
 * @param sectionRowController The row controller created by the table.
 * @param section An index for a section in the table.
 * @discussion The class of the sectionRowController will correspond to the class of the row controller configured in
 * your storyboard with the identifier returned by -table:identifierForSection:. If -table:identifierForSection: is not
 * implemented, this method is never called.
 */
- (void)table:(WKInterfaceTable *)table configureSectionController:(NSObject *)sectionRowController forSection:(NSInteger)section;

/**
 * Asks the data source to configure a header row controller.
 * @param table The table requesting the information.
 * @param rowController The row controller created by the table.
 * @param indexPath An index path locating a row in the table.
 * @discussion The class of the rowController will correspond to the class of the row controller configured in your
 * storyboard with the identifier returned by -table:rowIdentifierAtIndexPath:.
 */
- (void)table:(WKInterfaceTable *)table configureRowController:(NSObject *)rowController forIndexPath:(NSIndexPath *)indexPath;

@end


@interface WKInterfaceTable (IGInterfaceDataTable)

@property (nonatomic, weak) id<IGInterfaceTableDataSource> ig_dataSource;

/**
 * Reload the table
 * @discussion Reloads all row controllers for the table, including rows, headers, footers, and section headers.
 */
- (void)reloadData;


/** @name Convenience */

/**
 * Convert an index for a flat array of row controllers to an indexPath.
 * @param rowIndex An index of a row controller in the table.
 * @return An index path for a row or nil.
 * @discussion This method will return nil for rowIndexes that correspond to anything other than a row. That means that
 * section headers, table headers, and table footers will not be accessible with this method.
 */
- (NSIndexPath *)indexPathFromRowIndex:(NSInteger)rowIndex;

/**
 * Convert an index for a flat array of row controllers to a section.
 * @param rowIndex An index of a row controller in the table.
 * @return A section for a row or NSNotFound.
 * @discussion This method only returns the section of a row or section header so checking against NSNotFound is
 * recommended.
 */
- (NSInteger)sectionFromRowIndex:(NSInteger)rowIndex;


/** @name Headers & Footers */

/**
 * Get the row controller for the table header. If @p-headerIdentifierForTable: is not implemented, this will return
 * nil.
 * @return The row controller for the header or nil.
 */
- (NSObject *)headerController;

/**
 * Get the row controller for the table footer. If @p-footerIdentifierForTable: is not implemented, this will return
 * nil.
 * @return The row controller for the footer or nil.
 */
- (NSObject *)footerController;


/** @name Scrolling */

/**
 * Scroll to the header row of a section.
 * @param section The section index to scroll to.
 * @discussion This will scroll to the top of the section header. If the section does not have a header, it will scroll
 * to the first row in the section.
 */
- (void)scrollToSection:(NSInteger)section;

/**
 * Scroll to the top of a row.
 * @param indexPath The index path of a row to scroll to.
 */
- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath;


/** @name Editing */

/**
 * Starts the updates to the table, data is not inserted normally here.
 */
- (void)beginUpdates;

/**
 * Stops the updates to the table to allow normal inserts
 */
- (void)endUpdates;

/**
 * Update a row in the table for a given index path.
 * @param indexPath The index path of the row to update
 * @discussion This will update the row at the specifed indexPath. It does it by calling the configure row and the correct index path on the delegate.
 */
- (void)updateRowWithIndexPath:(NSIndexPath *)indexPath;

/**
 * Insert new table sections.
 * @param sections A set of section indexes to insert.
 * @param sectionType The identifier for the section row controllers being inserted.
 * @discussion This will only insert section @a headers and not rows. To insert rows see
 * @p-insertRowsAtIndexPaths:withRowType:. @p-table:configureSectionController:forSection: will be called immediately.
 */
- (void)insertSections:(NSIndexSet *)sections withSectionType:(NSString *)sectionType;

/**
 * Remove a set of sections.
 * @param sections A set of section indexes to remove.
 */
- (void)removeSections:(NSIndexSet *)sections;

/**
 * Insert new table rows.
 * @param indexPaths An array of index paths where rows should be inserted.
 * @param rowType The identifier for the row controllers being inserted.
 * @discussion This will only insert @a rows and not section headers. To insert sections see
 * @p-insertSections:withSectionType:. @p-table:configureRowController:forIndexPath: will be called immediately.
 */
- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths withRowType:(NSString *)rowType;

/**
 * Remove an array of rows.
 * @param sections A set of section indexes to remove.
 * @discussion This will not remove section headers if a section is empty.
 */
- (void)removeRowsAtIndexPaths:(NSArray *)indexPaths;

@end

@interface WKInterfaceController (IGInterfaceDataTable)

/**
 * An event that is called when a row is selected.
 * @param table The table that was selected.
 * @param indexPath The index path of the row that was selected.
 * @discussion This method will be called only when rows are selected.
 */
- (void)table:(WKInterfaceTable *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

/**
 * An event that is called when a section header is selected.
 * @param table The table that was selected.
 * @param section The section of the row that was selected.
 * @discussion This method will be called only when section headers are selected.
 */
- (void)table:(WKInterfaceTable *)table didSelectSection:(NSInteger)section;

/**
 * An event that is called when the table header is selected.
 * @param table The table that was selected.
 * @discussion This method will be called only when the table header is selected.
 */
- (void)tableDidSelectHeader:(WKInterfaceTable *)table;

/**
 * An event that is called when the table footer is selected.
 * @param table The table that was selected.
 * @discussion This method will be called only when the table footer is selected.
 */
- (void)tableDidSelectFooter:(WKInterfaceTable *)table;

@end
