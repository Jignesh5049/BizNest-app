import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biznest_core/biznest_core.dart';

class AddCustomerScreen extends StatefulWidget {
  final Map<String, dynamic>? customer;

  const AddCustomerScreen({super.key, this.customer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _isSaving = false;

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    if (c == null) return;

    _nameCtrl.text = (c['name'] ?? '').toString();
    _phoneCtrl.text = (c['phone'] ?? '').toString();
    _emailCtrl.text = (c['email'] ?? '').toString();
    _notesCtrl.text = (c['notes'] ?? '').toString();

    final addr = c['address'] as Map?;
    if (addr != null) {
      _cityCtrl.text = (addr['city'] ?? '').toString();
      _stateCtrl.text = (addr['state'] ?? '').toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'address': {
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
      },
    };

    try {
      if (_isEdit) {
        await _api.updateCustomer(widget.customer!['_id'], data);
      } else {
        await _api.createCustomer(data);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                color: AppColors.gray700,
                tooltip: 'Back',
              ),
              const SizedBox(width: 4),
              Text(
                _isEdit ? 'Edit Customer' : 'Add New Customer',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Name
          _field(
            'Name *',
            _nameCtrl,
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),

          // Phone & Email
          Row(
            children: [
              Expanded(
                child: _field(
                  'Phone',
                  _phoneCtrl,
                  keyboard: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  'Email',
                  _emailCtrl,
                  keyboard: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // City & State
          Row(
            children: [
              Expanded(child: _field('City', _cityCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _field('State', _stateCtrl)),
            ],
          ),
          const SizedBox(height: 12),

          // Notes
          _field('Notes', _notesCtrl, maxLines: 3),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_isEdit ? 'Update Customer' : 'Create Customer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


