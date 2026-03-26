import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biznest_core/biznest_core.dart';

class ProfileHubScreen extends StatefulWidget {
  const ProfileHubScreen({super.key});

  @override
  State<ProfileHubScreen> createState() => _ProfileHubScreenState();
}

class _ProfileHubScreenState extends State<ProfileHubScreen> {
  final _api = ApiService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  String _category = 'retail';
  bool _loading = true;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    _websiteCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _instagramCtrl.dispose();
    _facebookCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _nameCtrl.text = authState.user['name'] ?? '';
        _emailCtrl.text = authState.user['email'] ?? '';
        _phoneCtrl.text = authState.user['phone'] ?? '';
      }

      final businessRes = await _api.getBusiness();
      final business = businessRes.data is Map
          ? Map<String, dynamic>.from(businessRes.data as Map)
          : null;
      if (business != null) {
        _nameCtrl.text = (business['name'] ?? _nameCtrl.text).toString();
        _descCtrl.text = (business['description'] ?? '').toString();
        _category = (business['category'] ?? 'retail').toString();
        _phoneCtrl.text = (business['contact']?['phone'] ?? _phoneCtrl.text)
            .toString();
        _emailCtrl.text = (business['contact']?['email'] ?? _emailCtrl.text)
            .toString();
        _websiteCtrl.text = (business['contact']?['website'] ?? '').toString();
        _cityCtrl.text = (business['address']?['city'] ?? '').toString();
        _stateCtrl.text = (business['address']?['state'] ?? '').toString();
        _instagramCtrl.text = (business['socialLinks']?['instagram'] ?? '')
            .toString();
        _facebookCtrl.text = (business['socialLinks']?['facebook'] ?? '')
            .toString();
      }
    } catch (_) {
      // Keep fields populated from auth state if API fetch fails.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
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
          'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
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

      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _saved = false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Profile',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 24),
            _section(
              title: 'Business Information',
              icon: Icons.store_outlined,
              children: [
                _profileField('Business Name', _nameCtrl),
                const SizedBox(height: 12),
                _dropdownField(
                  'Category',
                  _category,
                  businessCategories
                      .map((c) => (value: c.value, label: c.label))
                      .toList(),
                  (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 12),
                _profileField('Description', _descCtrl, maxLines: 3),
              ],
            ),
            const SizedBox(height: 16),
            _section(
              title: 'Contact Details',
              icon: Icons.phone_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _profileField(
                        'Phone',
                        _phoneCtrl,
                        keyboard: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _profileField(
                        'Email',
                        _emailCtrl,
                        keyboard: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _profileField(
                  'Website',
                  _websiteCtrl,
                  keyboard: TextInputType.url,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _section(
              title: 'Location',
              icon: Icons.location_on_outlined,
              children: [
                Row(
                  children: [
                    Expanded(child: _profileField('City', _cityCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _profileField('State', _stateCtrl)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _section(
              title: 'Social Links',
              icon: Icons.link,
              children: [
                Row(
                  children: [
                    Expanded(child: _profileField('Instagram', _instagramCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _profileField('Facebook', _facebookCtrl)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _saved
                      ? const Color(0xFF22C55E)
                      : AppColors.primary600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _saving
                      ? 'Saving...'
                      : _saved
                      ? 'Saved!'
                      : 'Save Changes',
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _profileField(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.gray200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.gray200),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField(
    String label,
    String value,
    List<({String value, String label})> items,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.gray700,
          ),
        ),
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
              items: items
                  .map(
                    (i) =>
                        DropdownMenuItem(value: i.value, child: Text(i.label)),
                  )
                  .toList(),
              onChanged: (v) => onChanged(v!),
            ),
          ),
        ),
      ],
    );
  }
}
