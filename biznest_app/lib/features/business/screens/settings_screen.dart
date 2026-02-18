import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/helpers.dart';
import '../../auth/bloc/auth_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = ApiService();

  bool _loading = true;
  bool _saving = false;
  bool _saved = false;

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  String _category = 'retail';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _instagramCtrl.dispose();
    _facebookCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final res = await _api.getBusiness();
      final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
      if (data != null) {
        _nameCtrl.text = data['name'] ?? '';
        _descCtrl.text = data['description'] ?? '';
        _category = data['category'] ?? 'retail';
        _phoneCtrl.text = data['contact']?['phone'] ?? '';
        _emailCtrl.text = data['contact']?['email'] ?? '';
        _websiteCtrl.text = data['contact']?['website'] ?? '';
        _cityCtrl.text = data['address']?['city'] ?? '';
        _stateCtrl.text = data['address']?['state'] ?? '';
        _instagramCtrl.text = data['socialLinks']?['instagram'] ?? '';
        _facebookCtrl.text = data['socialLinks']?['facebook'] ?? '';
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saved = false;
    });
    try {
      await _api.updateBusiness({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _category,
        'contact': {
          'phone': _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'website': _websiteCtrl.text.trim(),
        },
        'address': {
          'city': _cityCtrl.text.trim(),
          'state': _stateCtrl.text.trim(),
        },
        'socialLinks': {
          'instagram': _instagramCtrl.text.trim(),
          'facebook': _facebookCtrl.text.trim(),
        },
      });
      setState(() {
        _saving = false;
        _saved = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _saved = false);
      });
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final authState = context.read<AuthBloc>().state;
    final userEmail = authState is AuthAuthenticated ? (authState.user['email'] ?? '') : '';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Settings', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.gray900)),
                      const SizedBox(height: 4),
                      Text('Manage your business profile', style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : _saved
                          ? const Icon(Icons.check, size: 20)
                          : const Icon(Icons.save, size: 20),
                  label: Text(_saving ? 'Saving...' : _saved ? 'Saved!' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _saved ? const Color(0xFF22C55E) : AppColors.primary600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Business Information
            _section(
              title: 'Business Information',
              icon: Icons.store_outlined,
              children: [
                _field('Business Name', _nameCtrl),
                const SizedBox(height: 12),
                _dropdownField('Category', _category, businessCategories.map((c) => (value: c.value, label: c.label)).toList(),
                    (v) => setState(() => _category = v)),
                const SizedBox(height: 12),
                _field('Description', _descCtrl, maxLines: 3),
              ],
            ),
            const SizedBox(height: 16),

            // Contact
            _section(
              title: 'Contact Details',
              icon: Icons.phone_outlined,
              children: [
                Row(children: [
                  Expanded(child: _field('Phone', _phoneCtrl, keyboard: TextInputType.phone)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Email', _emailCtrl, keyboard: TextInputType.emailAddress)),
                ]),
                const SizedBox(height: 12),
                _field('Website', _websiteCtrl, keyboard: TextInputType.url),
              ],
            ),
            const SizedBox(height: 16),

            // Location
            _section(
              title: 'Location',
              icon: Icons.location_on_outlined,
              children: [
                Row(children: [
                  Expanded(child: _field('City', _cityCtrl)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('State', _stateCtrl)),
                ]),
              ],
            ),
            const SizedBox(height: 16),

            // Social Links
            _section(
              title: 'Social Links',
              icon: Icons.link,
              children: [
                Row(children: [
                  Expanded(child: _field('Instagram', _instagramCtrl)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Facebook', _facebookCtrl)),
                ]),
              ],
            ),
            const SizedBox(height: 16),

            // Account
            _section(
              title: 'Account',
              icon: Icons.person_outline,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary100,
                        child: Icon(Icons.person, color: AppColors.primary600),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Business Owner',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.gray900)),
                            Text(userEmail, style: GoogleFonts.inter(fontSize: 13, color: AppColors.gray500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
                    icon: Icon(Icons.logout, size: 18, color: AppColors.danger),
                    label: Text('Logout', style: TextStyle(color: AppColors.danger)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary500),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray900)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboard, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.gray200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.gray200)),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField(String label, String value, List<({String value, String label})> items, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              items: items.map((i) => DropdownMenuItem(value: i.value, child: Text(i.label))).toList(),
              onChanged: (v) => onChanged(v!),
            ),
          ),
        ),
      ],
    );
  }
}
