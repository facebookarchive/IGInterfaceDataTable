# IGInterfaceDataTable

[![Version](http://img.shields.io/cocoapods/v/IGInterfaceDataTable.svg)](http://cocoapods.org/?q=IGInterfaceDataTable)
[![Platform](http://img.shields.io/cocoapods/p/IGInterfaceDataTable.svg)]()
[![License](http://img.shields.io/cocoapods/l/IGInterfaceDataTable.svg)](https://github.com/Instagram/IGInterfaceDataTable/blob/master/LICENSE)
[![Build Status](https://travis-ci.org/Instagram/IGInterfaceDataTable.svg)](https://travis-ci.org/Instagram/IGInterfaceDataTable)

IGInterfaceDataTable is an abstraction to make adding data and rows to [WKInterfaceTable](https://developer.apple.com/library/prerelease/ios/documentation/WatchKit/Reference/WKInterfaceTable_class/index.html) more manageable. Instead of flattening your data structures into a single-dimensional array, configure your watch tables using the data source pattern, similar to `UITableViewDataSource`.

Use IGInterfaceDataTable to build beautiful apps with complex data types, just like the [Instagram Apple Watch](http://www.apple.com/watch/app-store-apps/#instagram) app.

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

In order to start using IGInterfaceDataTable, you simply need to conform an object to `IGInterfaceTableDataSource` (defined in [WKInterfaceTable+IGInterfaceDataTable.h](https://github.com/Instagram/IGInterfaceDataTable/blob/master/IGInterfaceDataTable/WKInterfaceTable%2BIGInterfaceDataTable.h)) and set it as your table's `ig_dataSource`.

There are only two required methods that you need to implement to start displaying data. The first returns the number of rows for a section. If you don't implement `numberOfSectionsInTable:`, the data source defaults to just a single section.

```objective-c
- (NSInteger)numberOfRowsInTable:(WKInterfaceTable *)table section:(NSInteger)section;
```

The other required method returns the **identifier** of the row controller configured in your WatchKit storyboard. You must not return `nil`.

```objective-c
- (NSString *)table:(WKInterfaceTable *)table rowIdentifierAtIndexPath:(NSIndexPath *)indexPath;
```

Beyond the required methods, you can also provide identifiers for the header, footer, and even section headers.

## Customizing Rows

IGInterfaceDataSource provides convenience methods to update your row controllers whenever you reload or add data to your WKInterfaceTable.

The following method will pass the data source a row controller for a row in the table. You are then free to configure the row, such as setting text labels or adding images.

```objective-c
- (void)table:(WKInterfaceTable *)table configureRowController:(NSObject *)rowController forIndexPath:(NSIndexPath *)indexPath;
```

Check out the project header for other methods that the data source can implemement.

## Convenience

IGInterfaceDataSource also provides convenience methods to make bridging between `WKInterfaceTable` and your data structures more seemless.

For example, in order to map a row selection back to the index path of your data, you call `-[WKInterfaceTable indexPathFromRowIndex:]`

```objective-c
- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
  NSIndexPath *indexPath = [table indexPathFromRowIndex:rowIndex];
  if (indexPath) {
    // do something with the index path or data
  }
}
```

Or, you can scroll straight to a section without having to lookup the row index of your data:

```objective-c
[table scrollToSection:section];
```

## Testing

Since `WKInterfaceTable` objects must be initialized from storyboards, and there is no mechanism yet to create a WatchKit storyboard in code, we cannot use Xcode unit tests yet.

For now, tests are run manually by executing the **ApplicationTests** WatchKit extension and ensuring that none of the asserts are fired.

## Contributing

See the CONTRIBUTING file for how to help out.

## License

IGInterfaceDataTable is BSD-licensed. We also provide an additional patent grant.
