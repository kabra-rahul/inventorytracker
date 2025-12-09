//firestore_constants.dart
class FirestoreConstants {
  // Collections
  static const String companyCollection = 'companies';
  static const String userMapCollection = 'user_mapping';
  static const String categoryCollection = 'categories';
  static const String hsnCollection = 'hsn_codes';
  static const String unitCollection = 'units';
  static const String warehouseCollection = 'warehouses';
  static const String supplierCollection = 'suppliers';
  static const String clientCollection = 'clients';
  static const String productCollection = 'products';
  static const String transactionCollection = 'transactions';
  static const String userCollection = 'users';
  static const String undoneTransactionCollection = 'undone_transactions';
  static const String stockCollection = 'stocks';
  static const String batchCollection = 'batches';
  static const String contactMessageCollection = 'contact_messages';
  static const String paymentCollection = 'payments';

  // Fields common to many documents (Category, Unit, Warehouse,Product, User)
  static const String nameField = 'name';

  // Fields common to many documents (Category, HSN ,Unit, Warehouse, Supplier, Client, Product, User)
  static const String activeField = 'active';

  // HSN collection Field
  static const String codeField = 'code';

  // Unit collection Field
  static const String symbolField = 'symbol';

  // Warehouse collection Field
  static const String locationField = 'location';

  // Company,Client and Supplier Collection Fields
  static const String companyNameField = 'comapnyName';
  static const String companyGstField = 'gst';
  static const String companyAddressField = 'address';

  // Company collection Fields
  static const String companyPlanField = 'plan';
  static const String companyCreatedOnField = 'createdOn';
  static const String companyCreatedByField = 'createdBy';
  static const String companyPlanExpiryField = 'planExpiry';

// Product collection Fields
  static const String productCategoryIdField = 'categoryId';
  static const String productHsnIdField = 'hsnId';
  static const String productUnitIdField = 'unitId';
  static const String productLowStockAlertField = 'lowStockAlert';


  // User and contact_messages Collection Fields
  static const String userNameField = 'userName';
  static const String userMobileField = 'mobile';
  static const String userEmailField = 'email';

  // User Collection Fields
  static const String userRoleField = 'role';
  static const String userWarehousIdsField = 'warehouseIds';
  static const String userCreatedOnField = 'createdOn';

  // User Mapping Collection Fields
  static const String userIdField = 'userId';
  static const String companyIdField = 'companyId';

  // contact_messages Collection Fields
  static const String messageField = 'message';
  static const String messageDateField = 'messageSentOn';

  //Transaction and Undo Transaction Collection Data
  static const String transactionTypeField = 'type'; // 'inward' or 'outward'
  static const String transactionProductIdField = 'productId';
  static const String transactionWarehouseIdField = 'warehouseId';
  static const String transactionStockIdField = 'stockId'; // Reference to a stock document
  static const String transactionClientIdField = 'clientId';
  static const String transactionSupplierIdField = 'supplierId';
  static const String transactionBatchAffectedField = 'batchAffected';
  static const String transactionBatchIdField = 'batchId';// Likely a batch ID or reference
  static const String transactionTotalQuantityField = 'totalQuantity';
  static const String transactionPricePerUnitField = 'pricePerUnit';
  static const String transactionDateField = 'date';
  static const String transactionDoneByField = 'performedBy';
  static const String undoTransactionDateField = 'undoneDate';
  static const String undoTransactionDoneByField = 'undonePerformedBy';
  static const String undoTransactionReasonField = 'undoneReason';

// Batch Collection Data
  static const String batchSupplierIdField = 'supplierId';
  static const String batchNumberField = 'batchNumber';
  static const String batchQuantityField = 'quantity';
  static const String batchPricePerUnitField = 'pricePerUnit';
  static const String batchPurchaseDateField = 'purchaseDate';

  //Stock Collection data
  static const String stockProductIdField = 'productId';
  static const String stockTotalQuantityField = 'totalQuantity';

  // Payments Collection Data
  static const String paymentIdField = 'paymentId';
  static const String amountField = 'amount';
  static const String paidAtField = 'paidAt';
  static const String orderIdField = 'orderId';
  static const String orderStatusField = 'status';
  static const String paymentMethodField = 'method';
}