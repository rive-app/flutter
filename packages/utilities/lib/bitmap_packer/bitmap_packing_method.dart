/// Different modes the bitmap packer can run in to optimize placement.
enum BitmapPackingMethod {
  shortSide,
  longSide,
  bestArea,
  bottomLeft,
  contactPoint,
}