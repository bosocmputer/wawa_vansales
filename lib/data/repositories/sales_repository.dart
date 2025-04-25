import 'package:logger/logger.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/product_model.dart';
import 'package:wawa_vansales/data/models/sales_transaction_model.dart';

class SalesRepository {
  final Logger _logger = Logger();

  // In-memory storage for transactions (simulating a database)
  final List<SalesTransactionModel> _transactions = [];

  // Get current draft transaction or create a new one
  Future<SalesTransactionModel> getCurrentDraftTransaction() async {
    try {
      _logger.i('Getting current draft transaction');

      // Check if there is an existing draft
      final draftIndex = _transactions.indexWhere((t) => t.status == 'draft');

      if (draftIndex >= 0) {
        return _transactions[draftIndex];
      } else {
        // Create a new draft transaction
        final newDraft = SalesTransactionModel.createDraft();
        _transactions.add(newDraft);
        return newDraft;
      }
    } catch (e) {
      _logger.e('Error getting draft transaction: $e');
      // Return a new draft if error occurs
      final newDraft = SalesTransactionModel.createDraft();
      _transactions.add(newDraft);
      return newDraft;
    }
  }

  // Save transaction (complete the sale)
  Future<bool> saveTransaction(SalesTransactionModel transaction) async {
    try {
      _logger.i('Saving transaction: ${transaction.docNo}');

      // Update status to completed
      transaction.status = 'completed';

      // Find transaction in list and update it
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index >= 0) {
        _transactions[index] = transaction;
      } else {
        _transactions.add(transaction);
      }

      return true;
    } catch (e) {
      _logger.e('Error saving transaction: $e');
      return false;
    }
  }

  // Cancel transaction
  Future<bool> cancelTransaction(String transactionId) async {
    try {
      _logger.i('Cancelling transaction: $transactionId');

      // Find transaction and update status
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index >= 0) {
        _transactions[index].status = 'canceled';
        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Error cancelling transaction: $e');
      return false;
    }
  }

  // Add item to transaction
  Future<SalesTransactionModel> addItemToTransaction(String transactionId, ProductModel product, double quantity) async {
    try {
      _logger.i('Adding item to transaction: ${product.itemCode}, quantity: $quantity');

      // Find transaction
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index >= 0) {
        _transactions[index].addItem(product, quantity);
        return _transactions[index];
      }

      throw Exception('Transaction not found');
    } catch (e) {
      _logger.e('Error adding item to transaction: $e');
      rethrow;
    }
  }

  // Remove item from transaction
  Future<SalesTransactionModel> removeItemFromTransaction(String transactionId, String productCode) async {
    try {
      _logger.i('Removing item from transaction: $productCode');

      // Find transaction
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index >= 0) {
        _transactions[index].removeItem(productCode);
        return _transactions[index];
      }

      throw Exception('Transaction not found');
    } catch (e) {
      _logger.e('Error removing item from transaction: $e');
      rethrow;
    }
  }

  // Update item quantity
  Future<SalesTransactionModel> updateItemQuantity(String transactionId, String productCode, double quantity) async {
    try {
      _logger.i('Updating item quantity: $productCode, quantity: $quantity');

      // Find transaction
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index >= 0) {
        _transactions[index].updateItemQuantity(productCode, quantity);
        return _transactions[index];
      }

      throw Exception('Transaction not found');
    } catch (e) {
      _logger.e('Error updating item quantity: $e');
      rethrow;
    }
  }

  // Set customer for transaction
  Future<SalesTransactionModel> setTransactionCustomer(String transactionId, CustomerModel customer) async {
    try {
      _logger.i('Setting customer for transaction: ${customer.code}');

      // Find transaction
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index >= 0) {
        _transactions[index].customer = customer;
        return _transactions[index];
      }

      throw Exception('Transaction not found');
    } catch (e) {
      _logger.e('Error setting customer for transaction: $e');
      rethrow;
    }
  }

  // Set payment type
  Future<SalesTransactionModel> setPaymentType(String transactionId, PaymentType paymentType) async {
    try {
      _logger.i('Setting payment type: ${paymentType.name}');

      // Find transaction
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index >= 0) {
        _transactions[index].paymentType = paymentType;
        return _transactions[index];
      }

      throw Exception('Transaction not found');
    } catch (e) {
      _logger.e('Error setting payment type: $e');
      rethrow;
    }
  }

  // Apply discount to transaction
  Future<SalesTransactionModel> applyDiscount(String transactionId, double discount) async {
    try {
      _logger.i('Applying discount: $discount');

      // Find transaction
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index >= 0) {
        _transactions[index].discount = discount;
        _transactions[index].calculateAmounts();
        return _transactions[index];
      }

      throw Exception('Transaction not found');
    } catch (e) {
      _logger.e('Error applying discount: $e');
      rethrow;
    }
  }

  // Get transaction history
  Future<List<SalesTransactionModel>> getTransactionHistory() async {
    try {
      _logger.i('Getting transaction history');

      // Return only completed transactions
      return _transactions.where((t) => t.status == 'completed').toList();
    } catch (e) {
      _logger.e('Error getting transaction history: $e');
      return [];
    }
  }
}
