import 'package:wawa_vansales/data/models/return_product/product_return_model.dart';
import 'package:wawa_vansales/data/repositories/product_repository.dart';

class ProductReturnSearchRepository {
  final ProductRepository _productRepository;

  ProductReturnSearchRepository({required ProductRepository productRepository}) : _productRepository = productRepository;

  // ค้นหาสินค้ารับคืน โดยใช้ ProductRepository ที่มีอยู่แล้ว
  Future<List<ProductReturnModel>> getProductsReturn({
    required String search,
    required String custCode,
  }) async {
    try {
      // เรียกใช้ getProductsReturn จาก ProductRepository
      final products = await _productRepository.getProductsReturn(search: search, custCode: custCode);

      // แปลง ProductModel เป็น ProductReturnModel
      return products
          .map((product) => ProductReturnModel(
                itemCode: product.itemCode,
                itemName: product.itemName,
                barcode: product.barcode,
                price: product.price,
                unitCode: product.unitCode,
                standValue: product.standValue,
                divideValue: product.divideValue,
                ratio: product.ratio,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }
}
