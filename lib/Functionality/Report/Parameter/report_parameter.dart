
typedef BatchDetailsReportParams = ({
String warehouseId,
String productId
});


typedef ClientSellReportParams = ({
String? clientId,
DateTime? fromDate,
DateTime? toDate,
});


typedef SupplierSellReportParams = ({
String? supplierId,
DateTime? fromDate,
DateTime? toDate,
});


typedef TransactionReportParams = ({
DateTime fromDate, // Required
DateTime toDate,   // Required
String transactionType, // 'Both', 'Inward', 'Outward'
String? userId, // Optional
});


typedef UndoneTransactionReportParams = ({
DateTime fromDate, // Required
DateTime toDate,   // Required
String? undoneByUserId, // Optional: Filter by the user who undid the transaction
});
