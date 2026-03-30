import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biznest_core/biznest_core.dart';
import '../widgets/customer_refresh_registry.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});
  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _api = ApiService();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  List<dynamic> _addresses = [];
  List<dynamic> _tickets = [];
  bool _loading = true;
  bool _saving = false;
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    CustomerRefreshRegistry.register('/store/profile', _fetch);
    _fetch();
  }

  @override
  void dispose() {
    CustomerRefreshRegistry.unregister('/store/profile', _fetch);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _nameCtrl.text = authState.user['name'] ?? '';
        _phoneCtrl.text = authState.user['phone'] ?? '';
      }
      final addrRes = await _api.getAddresses();
      _addresses = addrRes.data is List
          ? addrRes.data
          : (addrRes.data?['addresses'] ?? []);
      try {
        final ticketRes = await _api.getSupportTickets();
        _tickets = ticketRes.data is List
            ? ticketRes.data
            : (ticketRes.data?['tickets'] ?? []);
      } catch (_) {}
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await _api.updateMe({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _saving = false);
  }

  Future<void> _addAddress() async {
    if (_streetCtrl.text.trim().isEmpty) return;
    try {
      await _api.addAddress({
        'label': _labelCtrl.text.trim().isNotEmpty
            ? _labelCtrl.text.trim()
            : 'Home',
        'street': _streetCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
      });
      _labelCtrl.clear();
      _streetCtrl.clear();
      _cityCtrl.clear();
      _stateCtrl.clear();
      _pincodeCtrl.clear();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      _fetch();
    } catch (_) {}
  }

  Future<void> _deleteAddress(String id) async {
    try {
      await _api.deleteAddress(id);
      _fetch();
    } catch (_) {}
  }

  void _showAddAddressDialog() {
    _labelCtrl.clear();
    _streetCtrl.clear();
    _cityCtrl.clear();
    _stateCtrl.clear();
    _pincodeCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Address',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _tf('Label (Home, Office...)', _labelCtrl),
              const SizedBox(height: 8),
              _tf('Street', _streetCtrl),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _tf('City', _cityCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: _tf('State', _stateCtrl)),
                ],
              ),
              const SizedBox(height: 8),
              _tf('Pincode', _pincodeCtrl),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tf(String hint, TextEditingController ctrl) => TextField(
    controller: ctrl,
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.gray200),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Profile',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 20),

          // Profile form
          _section('Profile Info', Icons.person_outline, [
            _tf('Name', _nameCtrl),
            const SizedBox(height: 10),
            _tf('Phone', _phoneCtrl),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // Addresses
          _section('My Addresses', Icons.location_on_outlined, [
            ..._addresses.map((a) {
              final addr = Map<String, dynamic>.from(a as Map);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addr['label'] ?? 'Address',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${addr['street'] ?? ''}, ${addr['city'] ?? ''}, ${addr['state'] ?? ''} ${addr['pincode'] ?? ''}'
                                .trim(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteAddress(addr['_id']),
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _showAddAddressDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Address'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary600,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // Support Tickets
          if (_tickets.isNotEmpty) ...[
            _section('My Tickets', Icons.chat_outlined, [
              ..._tickets.take(5).map((t) {
                final ticket = Map<String, dynamic>.from(t as Map);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ticket['subject'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (ticket['status'] ?? '') == 'resolved'
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ticket['status'] ?? 'open',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if ((ticket['replies'] ?? []).isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${(ticket['replies'] as List).length} replies',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ]),
            const SizedBox(height: 16),
          ],

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(AuthLogoutRequested());
                context.go('/login');
              },
              icon: Icon(Icons.logout, size: 18, color: AppColors.danger),
              label: Text('Logout', style: TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary600),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );
}
