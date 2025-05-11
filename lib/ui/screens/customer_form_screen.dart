import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/customer/customer_bloc.dart';
import 'package:wawa_vansales/blocs/customer/customer_event.dart';
import 'package:wawa_vansales/blocs/customer/customer_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/ui/widgets/custom_button.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _isFormValid = false;
  bool _autoValidate = false;
  String _selectedArStatus = '0'; // เริ่มต้นเป็นบุคคลธรรมดา
  String _selectedPriceLevel = '0'; // เริ่มต้นเป็นราคากลาง

  @override
  void initState() {
    super.initState();
    // Initialize with a random customer code
    _codeController.text = _generateRandomCode();
  }

  // Generate a random customer code with OR- prefix
  String _generateRandomCode() {
    final random = Random();
    // Generate a random 4-digit number
    final randomNumber = (1000 + random.nextInt(9000)).toString(); // Number between 1000-9999
    return "OR-$randomNumber";
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _telephoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  // ตรวจสอบความถูกต้องของฟอร์ม
  void _validateForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // Check if required fields are not empty
      if (_codeController.text.isNotEmpty && _nameController.text.isNotEmpty) {
        setState(() {
          _isFormValid = true;
        });
      } else {
        setState(() {
          _isFormValid = false;
        });
      }
    } else {
      setState(() {
        _isFormValid = false;
      });
    }
  }

  // บันทึกข้อมูลลูกค้า
  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // ตรวจสอบว่ารหัสขึ้นต้นด้วย OR- หรือไม่
      String code = _codeController.text.trim();
      if (!code.startsWith('OR-')) {
        code = 'OR-$code';
      }

      // สร้าง CustomerModel จากข้อมูลในฟอร์ม
      final newCustomer = CustomerModel(
        code: code,
        name: _nameController.text.trim(),
        taxId: _taxIdController.text.trim(),
        address: _addressController.text.trim(),
        telephone: _telephoneController.text.trim(),
        arstatus: _selectedArStatus, // ใช้ค่าที่เลือก
        website: _websiteController.text.trim(),
        priceLevel: _selectedPriceLevel,
      );

      // เรียก event สร้างลูกค้าใหม่
      context.read<CustomerBloc>().add(CreateCustomer(newCustomer));
    } else {
      // เปิดใช้งาน auto validate
      setState(() {
        _autoValidate = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มลูกค้าใหม่'),
        actions: [
          /// save
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isFormValid ? _submitForm : null,
          ),
        ],
      ),
      body: BlocListener<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerCreating) {
            // แสดง loading
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppTheme.primaryColor,
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('กำลังบันทึกข้อมูล...'),
                  ],
                ),
                duration: Duration(seconds: 2),
              ),
            );
          } else if (state is CustomerCreated) {
            // แสดงข้อความเมื่อบันทึกสำเร็จ
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('บันทึกข้อมูลลูกค้าเรียบร้อยแล้ว'),
                backgroundColor: Colors.green,
              ),
            );
            // กลับไปหน้าก่อนหน้า
            Navigator.of(context).pop();
          } else if (state is CustomerCreateError) {
            // แสดงข้อความเมื่อเกิดข้อผิดพลาด
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เกิดข้อผิดพลาด: ${state.message}'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          onChanged: _validateForm,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // รหัสลูกค้า
                _buildTextField(
                  controller: _codeController,
                  label: 'รหัสลูกค้า',
                  hint: 'กรอกรหัสลูกค้า เช่น 0001',
                  icon: Icons.badge,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกรหัสลูกค้า';
                    }
                    String fullCode = !value.startsWith('OR-') ? 'OR-$value' : value;
                    if (fullCode.length < 5) {
                      // OR- + at least 2 characters
                      return 'รหัสลูกค้าต้องมีอย่างน้อย 2 ตัวอักษรต่อจาก OR-';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ชื่อลูกค้า
                _buildTextField(
                  controller: _nameController,
                  label: 'ชื่อลูกค้า',
                  hint: 'กรอกชื่อลูกค้า',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกชื่อลูกค้า';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // เลขประจำตัวผู้เสียภาษี
                _buildTextField(
                  controller: _taxIdController,
                  label: 'เลขประจำตัวผู้เสียภาษี',
                  hint: 'กรอกเลขประจำตัวผู้เสียภาษี (ถ้ามี)',
                  icon: Icons.confirmation_number,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(13),
                  ],
                ),
                const SizedBox(height: 16),

                // ที่อยู่
                _buildTextField(
                  controller: _addressController,
                  label: 'ที่อยู่',
                  hint: 'กรอกที่อยู่ลูกค้า',
                  icon: Icons.location_on,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // เบอร์โทรศัพท์
                _buildTextField(
                  controller: _telephoneController,
                  label: 'เบอร์โทรศัพท์',
                  hint: 'กรอกเบอร์โทรศัพท์',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // เว็บไซต์
                _buildTextField(
                  controller: _websiteController,
                  label: 'GPRS',
                  hint: 'ระบุ GPRS (ถ้ามี)',
                  icon: Icons.language,
                ),
                const SizedBox(height: 16),

                // ระดับราคา (Price Level)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Text(
                        'ระดับราคา',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
                      child: DropdownButtonFormField<String>(
                        value: _selectedPriceLevel,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          prefixIcon: Icon(Icons.price_change, color: AppTheme.primaryColor),
                        ),
                        items: const [
                          DropdownMenuItem(value: '0', child: Text('ราคากลาง')),
                          DropdownMenuItem(value: '1', child: Text('ราคาที่ 1')),
                          DropdownMenuItem(value: '2', child: Text('ราคาที่ 2')),
                          DropdownMenuItem(value: '3', child: Text('ราคาที่ 3')),
                          DropdownMenuItem(value: '4', child: Text('ราคาที่ 4')),
                          DropdownMenuItem(value: '5', child: Text('ราคาที่ 5')),
                          DropdownMenuItem(value: '6', child: Text('ราคาที่ 6')),
                          DropdownMenuItem(value: '7', child: Text('ราคาที่ 7')),
                          DropdownMenuItem(value: '8', child: Text('ราคาที่ 8')),
                          DropdownMenuItem(value: '9', child: Text('ราคาที่ 9')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPriceLevel = value!;
                          });
                        },
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                        iconSize: 30,
                        style: const TextStyle(color: Colors.black, fontSize: 16),
                        dropdownColor: Colors.white,
                        focusColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ประเภทลูกค้า (AR Status)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Text(
                        'ประเภทลูกค้า',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              title: const Text('บุคคลธรรมดา'),
                              value: '0',
                              groupValue: _selectedArStatus,
                              onChanged: (value) {
                                setState(() {
                                  _selectedArStatus = value!;
                                });
                              },
                              activeColor: AppTheme.primaryColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                            RadioListTile<String>(
                              title: const Text('นิติบุคคล (บริษัท)'),
                              value: '1',
                              groupValue: _selectedArStatus,
                              onChanged: (value) {
                                setState(() {
                                  _selectedArStatus = value!;
                                });
                              },
                              activeColor: AppTheme.primaryColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ปุ่มบันทึก
                CustomButton(
                  text: 'บันทึกข้อมูล',
                  onPressed: _isFormValid ? _submitForm : null,
                  icon: const Icon(Icons.save, color: Colors.white),
                  buttonType: ButtonType.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        prefixText: prefixText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }
}
