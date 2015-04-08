# IGInterfaceDataTable

[![Version](http://img.shields.io/cocoapods/v/IGInterfaceDataTable.svg)](http://cocoapods.org/?q=IGInterfaceDataTable)
[![Platform](http://img.shields.io/cocoapods/p/IGInterfaceDataTable.svg)]()
[![License](http://img.shields.io/cocoapods/l/IGInterfaceDataTable.svg)](https://github.com/Instagram/IGInterfaceDataTable/blob/master/LICENSE)
<!--[![Build Status](https://travis-ci.org/Instagram/IGInterfaceDataTable.svg)](https://travis-ci.org/Instagram/IGInterfaceDataTable)-->

IGInterfaceDataTable is a category on [WKInterfaceTable](https://developer.apple.com/library/prerelease/ios/documentation/WatchKit/Reference/WKInterfaceTable_class/index.html) that makes configuring tables with multi-dimensional data easier. Instead of flattening your data structures into an array, configure your watch tables using a data source pattern similar to `UITableViewDataSource`.

Use IGInterfaceDataTable to build beautiful Apple Watch apps with complex data structures, just like in the [Instagram Apple Watch](http://www.apple.com/watch/app-store-apps/#instagram) app.

![IGInterfaceDataTable](https://github.com/Instagram/IGInterfaceDataTable/blob/master/images/example.jpg)

## Installation

You can quickly install IGInterfaceDataTable using [CocoaPods](http://cocoapods.org). Add the following to your Podfile:

```ruby
pod 'IGInterfaceDataTable'
```

If you would rather install the framework manually, simply copy the `WKInterfaceTable+IGInterfaceDataTable.h` and `WKInterfaceTable+IGInterfaceDataTable.m` files into your project's WatchKit Extension target.

Import the framework header, or create an [Objective-C bridging header](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html) if you're using Swift.

```objective-c
#import <IGInterfaceDataTable/IGInterfaceDataTable.h>
```

## Getting Started

In order to start using IGInterfaceDataTable, you simply need to conform an object to `IGInterfaceTableDataSource` and set it as your table's `ig_dataSource`.

The simplest place to setup your table and data source is in `-[WKInterfaceController awakeWithContext:]`:

```objective-c
- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];

  self.table.ig_dataSource = self;
  [self.table reloadData];
}
```

There are only two required methods that you need to implement to start displaying data. The first returns the number of rows for a section.

```objective-c
- (NSInteger)numberOfRowsInTable:(WKInterfaceTable *)table section:(NSInteger)section {
    return self.items.count;
}
```

**Note:** If you don't implement `numberOfSectionsInTable:`, the data source defaults to just a single section.

The other required method returns the **identifier** of a row controller configured in your WatchKit storyboard.

```objective-c
- (NSString *)table:(WKInterfaceTable *)table rowIdentifierAtIndexPath:(NSIndexPath *)indexPath {
    return @"RowIdentifier";
}
```

Beyond the required methods, you can also provide identifiers for the [header](https://github.com/Instagram/IGInterfaceDataTable/blob/master/IGInterfaceDataTable/WKInterfaceTable%2BIGInterfaceDataTable.h#L51), [footer](https://github.com/Instagram/IGInterfaceDataTable/blob/master/IGInterfaceDataTable/WKInterfaceTable%2BIGInterfaceDataTable.h#L58), and even [section headers](https://github.com/Instagram/IGInterfaceDataTable/blob/master/IGInterfaceDataTable/WKInterfaceTable%2BIGInterfaceDataTable.h#L97). Check out the header documentation to see everything you can do!

## Customizing Rows

IGInterfaceDataSource provides convenience methods to update your row controllers whenever you reload or add data to your WKInterfaceTable.

The following method will pass the data source a row controller for a row in the table. You're then free to configure the row, such as setting text labels or adding images.

```objective-c
- (void)table:(WKInterfaceTable *)table 
        configureRowController:(NSObject *)rowController 
        forIndexPath:(NSIndexPath *)indexPath {
    MyController *controller = (MyController *)rowController;
    [controller.textLabel setText:@"Hello!"];
}
```

There are configure methods for headers, footers, and sections as well.

## Handling Selection

On top of making it easier to display your data, IGInterfaceDataTable also makes responding to tap events much simpler so you don't need to map a row index back to a section or piece of data.

You must call `enableTableSelectCallbacks` on your controller subclass, which swizzles the original `table:didSelectRowAtIndex:` method but still calls the original implementation.

There are four methods that you can override to respond to selection events:

```objective-c
- (void)table:(WKInterfaceTable *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)table:(WKInterfaceTable *)table didSelectSection:(NSInteger)section;
- (void)tableDidSelectHeader:(WKInterfaceTable *)table;
- (void)tableDidSelectFooter:(WKInterfaceTable *)table;
```

## Convenience

IGInterfaceDataSource also provides methods to make bridging between `WKInterfaceTable` and your data structures more seamless.

You can easily map from a table row index to a section or index path. Make sure to check for `NSNotFound` or `nil`!

```objective-c
NSInteger section = [table sectionFromRowIndex:rowIndex];
NSIndexPath *indexPath = [table indexPathFromRowIndex:rowIndex];
```

Or, you can scroll straight to a section without having to lookup the row index of your data:

```objective-c
[table scrollToSection:section];
```

## Testing

Since `WKInterfaceTable` objects must be initialized from storyboards, and there is no mechanism yet to create a WatchKit storyboard in code, we cannot use Xcode unit tests yet.

For now, tests are run manually by executing the **ApplicationTests** WatchKit extension and ensuring that none of the asserts are fired.

## Contributing

See the [CONTRIBUTING](https://github.com/Instagram/IGInterfaceDataTable/blob/master/CONTRIBUTING.md) file for how to help out.

## License

IGInterfaceDataTable is BSD-licensed. We also provide an additional patent grant.
