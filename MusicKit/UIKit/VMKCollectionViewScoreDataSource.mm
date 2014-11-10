//  Copyright (c) 2014 Venture Media Labs. All rights reserved.

#import "NSIndexPath+VMKScoreAdditions.h"
#import "VMKCollectionViewScoreDataSource.h"
#import "VMKCursorView.h"
#import "VMKDirectionView.h"
#import "VMKEndingView.h"
#import "VMKLyricView.h"
#import "VMKMeasureView.h"
#import "VMKOrnamentView.h"
#import "VMKPedalView.h"
#import "VMKScoreElementContainerView.h"
#import "VMKScoreElementImageLayer.h"
#import "VMKTieView.h"
#import "VMKWedgeView.h"

#include <mxml/geometry/EndingGeometry.h>
#include <mxml/geometry/LyricGeometry.h>
#include <mxml/geometry/OrnamentsGeometry.h>
#include <mxml/geometry/PartGeometry.h>
#include <mxml/dom/Pedal.h>
#include <mxml/dom/Wedge.h>

NSString* const VMKMeasureReuseIdentifier = @"Measure";
NSString* const VMKDirectionReuseIdentifier = @"Direction";
NSString* const VMKTieReuseIdentifier = @"Tie";
NSString* const VMKCursorReuseIdentifier = @"Cursor";

using namespace mxml;


@implementation VMKCollectionViewScoreDataSource

- (instancetype)init {
    self = [super init];
    self.foregroundColor = [UIColor blackColor];
    return self;
}

- (const PartGeometry*)partGeometryForSection:(NSUInteger)section {
    NSUInteger part = [NSIndexPath partIndexForSection:section];
    const Geometry* geometry = self.scoreGeometry->geometries().at(part).get();
    return static_cast<const PartGeometry*>(geometry);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (!self.scoreGeometry)
        return 0;
    return [NSIndexPath numberOfSectionsForPartCount:self.scoreGeometry->geometries().size()];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (!self.scoreGeometry)
        return 0;

    const PartGeometry* partGeom = [self partGeometryForSection:section];
    VMKScoreElementType type = [NSIndexPath typeForSection:section];
    if (type == VMKScoreElementTypeMeasure)
        return partGeom->measureGeometries().size();
    else if (type == VMKScoreElementTypeDirection)
        return partGeom->directionGeometries().size();
    else if (type == VMKScoreElementTypeTie)
        return partGeom->tieGeometries().size();
    else if (type == VMKScoreElementTypeCursor)
        return 1;
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.type == VMKScoreElementTypeMeasure)
        return [self collectionView:collectionView cellForMeasureAtIndexPath:indexPath];
    else if (indexPath.type == VMKScoreElementTypeDirection)
        return [self collectionView:collectionView cellForDirectionAtIndexPath:indexPath];
    else if (indexPath.type == VMKScoreElementTypeTie)
        return [self collectionView:collectionView cellForTieAtIndexPath:indexPath];
    else if (indexPath.type == VMKScoreElementTypeCursor)
        return [self collectionView:collectionView cellForCursorAtIndexPath:indexPath];
    return nil;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForMeasureAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:VMKMeasureReuseIdentifier forIndexPath:indexPath];
    
    VMKMeasureView* measureView = (VMKMeasureView*)[self scoreElementView:cell];
    if (!measureView) {
        measureView = [[VMKMeasureView alloc] init];
        [cell.contentView addSubview:measureView];
    }

    const PartGeometry* partGeom = [self partGeometryForSection:indexPath.section];
    measureView.foregroundColor = self.foregroundColor;
    measureView.bookmarkedColor = self.tintColor;
    measureView.measureGeometry = partGeom->measureGeometries().at(indexPath.item);
    measureView.bookmarked = [self.bookmarks containsObject:@(indexPath.item)];

    CGRect frame = measureView.frame;
    frame.origin = CGPointZero;
    measureView.frame = frame;

    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForDirectionAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:VMKDirectionReuseIdentifier forIndexPath:indexPath];
    
    VMKScoreElementContainerView* view = [self scoreElementView:cell];
    if (view)
        [view removeFromSuperview];

    const PartGeometry* partGeom = [self partGeometryForSection:indexPath.section];
    const Geometry* geometry = partGeom->directionGeometries().at(indexPath.item);
    if (const SpanDirectionGeometry* geom = dynamic_cast<const SpanDirectionGeometry*>(geometry)) {
        if (dynamic_cast<const dom::Wedge*>(geom->startDirection().type())) {
            view = [[VMKWedgeView alloc] initWithWedgeGeometry:geom];
        } else if (dynamic_cast<const dom::Pedal*>(geom->startDirection().type())) {
            view = [[VMKPedalView alloc] initWithPedalGeometry:geom];
        }
    } else if (const DirectionGeometry* geom = dynamic_cast<const DirectionGeometry*>(geometry)) {
        view = [[VMKDirectionView alloc] initWithDirectionGeometry:geom];
    } else if (const OrnamentsGeometry* geom = dynamic_cast<const OrnamentsGeometry*>(geometry)) {
        view = [[VMKOrnamentView alloc] initWithOrnamentsGeometry:geom];
    } else if (const EndingGeometry* geom = dynamic_cast<const EndingGeometry*>(geometry)) {
        view = [[VMKEndingView alloc] initWithEndingGeometry:geom];
    } else if (const LyricGeometry* geom = dynamic_cast<const LyricGeometry*>(geometry)) {
        view = [[VMKLyricView alloc] initWithLyricGeometry:geom];
    }
    
    if (!view)
        return nil;

    [cell.contentView addSubview:view];
    view.foregroundColor = self.foregroundColor;

    CGRect frame = view.frame;
    frame.origin = CGPointZero;
    view.frame = frame;

    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForTieAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:VMKTieReuseIdentifier forIndexPath:indexPath];
    
    VMKTieView* view = (VMKTieView*)[self scoreElementView:cell];
    if (!view) {
        view = [[VMKTieView alloc] init];
        [cell.contentView addSubview:view];
    }

    view.foregroundColor = self.foregroundColor;

    const PartGeometry* partGeom = [self partGeometryForSection:indexPath.section];
    view.geometry = partGeom->tieGeometries().at(indexPath.item);

    CGRect frame = view.frame;
    frame.origin = CGPointZero;
    view.frame = frame;
    
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForCursorAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:VMKCursorReuseIdentifier forIndexPath:indexPath];

    VMKCursorView* view;
    if (cell.contentView.subviews.count == 0) {
        view = [[VMKCursorView alloc] initWithFrame:cell.contentView.bounds];
        [cell.contentView addSubview:view];
    } else {
        view = (VMKCursorView*)[cell.contentView.subviews firstObject];
    }
    view.color = self.cursorColor;
    
    return cell;
}

- (VMKScoreElementContainerView*)scoreElementView:(UICollectionViewCell*)cell {
    if (cell.contentView.subviews.count > 0) {
        return cell.contentView.subviews[0];
    }
    return nil;
}

@end