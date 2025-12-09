// Functionality/StockMovement/Model/stock_movement_model.dart
import 'package:inventorytracker/Functionality/StockMovement/Model/stock_movement_model.dart';


class StockMovementReportModel {
  final String id;
  final String warehouseId;
  final String warehouseName;
  final String productId;
  final String productName;
  final String hsnCode;
  final String unitName;
  final String type;
  final double quantity;
  final DateTime date;
  final double price;
  final String? supplierId;
  final String supplierName;
  final String? clientId;
  final String clientName;
  final String? userId; // Assuming userId is on raw model
  final String userName;


  StockMovementReportModel({
    required this.id,
    required this.warehouseId,
    required this.warehouseName,
    required this.productId,
    required this.productName,
    required this.hsnCode,
    required this.unitName,
    required this.type,
    required this.quantity,
    required this.date,
    required this.price,
    this.supplierId,
    required this.supplierName,
    this.clientId,
    required this.clientName,
    this.userId,
    required this.userName,
  });

  factory StockMovementReportModel.fromMap(
      StockMovementModel data,
      {
        required String warehouseName,
        required String productName,
        required String hsnCode,
        required String unit,
        required String supplierName,
        required String clientName,
        required String userName,
      }) {
    return StockMovementReportModel(
      id           : data.id,
      warehouseId  : data.warehouseId,
      warehouseName: warehouseName,
      productId    : data.productId,
      productName  : productName,
      hsnCode      : hsnCode,
      unitName     : unit,
      type         : data.type,
      quantity     : data.totalQuantity,
      date         : data.date,
      price        : data.pricePerUnit,
      supplierId   : data.supplierId,
      supplierName : supplierName,
      clientId     : data.clientId,
      clientName   : clientName,
      userId       : data.performedBy, // Assuming rawMovement has userId
      userName     : userName,
    );
  }
}