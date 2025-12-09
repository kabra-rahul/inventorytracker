import 'package:excel/excel.dart';


final Border kAllBlackBorders = Border(
  borderStyle: BorderStyle.Medium,
  borderColorHex: ExcelColor.black
);


final CellStyle kReportHeaderStyle = CellStyle(
  backgroundColorHex: ExcelColor.grey300,
  fontColorHex: ExcelColor.black,
  bold: true,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Center,
  topBorder: kAllBlackBorders,
  bottomBorder: kAllBlackBorders,
  leftBorder: kAllBlackBorders,
  rightBorder: kAllBlackBorders,
);


final CellStyle kReportTotalStyle = CellStyle(
  backgroundColorHex: ExcelColor.grey100,
  fontColorHex: ExcelColor.black,
  bold: true,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Center,
  topBorder: kAllBlackBorders,
  bottomBorder: kAllBlackBorders,
  leftBorder: kAllBlackBorders,
  rightBorder: kAllBlackBorders,
);


final CellStyle kReportDataStyle = CellStyle(
  fontColorHex: ExcelColor.black,
  topBorder: kAllBlackBorders,
  bottomBorder: kAllBlackBorders,
  leftBorder: kAllBlackBorders,
  rightBorder: kAllBlackBorders,
);