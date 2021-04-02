import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

class SliverGridDelegateWithFixedCrossAxisCountAndLoading
    extends SliverGridDelegateWithFixedCrossAxisCount {
  final int itemCount;

  const SliverGridDelegateWithFixedCrossAxisCountAndLoading({
    required crossAxisCount,
    required this.itemCount,
    mainAxisSpacing = 0.0,
    crossAxisSpacing = 0.0,
    childAspectRatio = 1.0,
  }) : super(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: childAspectRatio);

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final double usableCrossAxisExtent =
        constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);
    final double childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    final double childMainAxisExtent = childCrossAxisExtent / childAspectRatio;
    return SliverGridRegularTileLayoutAndLoading(
        crossAxisCount: crossAxisCount,
        mainAxisStride: childMainAxisExtent + mainAxisSpacing,
        crossAxisStride: childCrossAxisExtent + crossAxisSpacing,
        childMainAxisExtent: childMainAxisExtent,
        childCrossAxisExtent: childCrossAxisExtent,
        reverseCrossAxis:
            axisDirectionIsReversed(constraints.crossAxisDirection),
        fullCrossAccessExtent: usableCrossAxisExtent,
        itemCount: this.itemCount);
  }
}

class SliverGridDelegateWithMaxCrossAxisExtentAndLoading
    extends SliverGridDelegateWithMaxCrossAxisExtent {
  final int itemCount;

  const SliverGridDelegateWithMaxCrossAxisExtentAndLoading({
    required maxCrossAxisExtent,
    required this.itemCount,
    mainAxisSpacing = 0.0,
    crossAxisSpacing = 0.0,
    childAspectRatio = 1.0,
  }) : super(
            maxCrossAxisExtent: maxCrossAxisExtent,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: childAspectRatio);

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final int crossAxisCount =
        (constraints.crossAxisExtent / (maxCrossAxisExtent + crossAxisSpacing))
            .ceil();
    final double usableCrossAxisExtent =
        constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);
    final double childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    final double childMainAxisExtent = childCrossAxisExtent / childAspectRatio;
    return SliverGridRegularTileLayoutAndLoading(
      itemCount: this.itemCount,
      fullCrossAccessExtent: usableCrossAxisExtent,
      crossAxisCount: crossAxisCount,
      mainAxisStride: childMainAxisExtent + mainAxisSpacing,
      crossAxisStride: childCrossAxisExtent + crossAxisSpacing,
      childMainAxisExtent: childMainAxisExtent,
      childCrossAxisExtent: childCrossAxisExtent,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }
}

class SliverGridRegularTileLayoutAndLoading
    extends SliverGridRegularTileLayout {
  final int itemCount;
  final double fullCrossAccessExtent;

  const SliverGridRegularTileLayoutAndLoading(
      {required crossAxisCount,
      required mainAxisStride,
      required crossAxisStride,
      required childMainAxisExtent,
      required childCrossAxisExtent,
      required reverseCrossAxis,
      required this.fullCrossAccessExtent,
      required this.itemCount})
      : super(
            crossAxisCount: crossAxisCount,
            mainAxisStride: mainAxisStride,
            crossAxisStride: crossAxisStride,
            childMainAxisExtent: childMainAxisExtent,
            childCrossAxisExtent: childCrossAxisExtent,
            reverseCrossAxis: reverseCrossAxis);

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    if (index == this.itemCount - 1) {
      return SliverGridGeometry(
          scrollOffset: (index ~/ this.crossAxisCount) * this.mainAxisStride,
          crossAxisOffset: 0.0,
          mainAxisExtent: this.childMainAxisExtent,
          crossAxisExtent: this.fullCrossAccessExtent);
    }

    return super.getGeometryForChildIndex(index);
  }
}
