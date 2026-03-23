import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/helpers.dart';

class AllBusinessesScreen extends StatefulWidget {
  const AllBusinessesScreen({super.key});

  @override
  State<AllBusinessesScreen> createState() => _AllBusinessesScreenState();
}

class _AllBusinessesScreenState extends State<AllBusinessesScreen> {
  final _api = ApiService();
  List<dynamic> _businesses = [];
  bool _loading = true;
  String _search = '';
  String _category = 'all';

  String _businessCity(Map<String, dynamic> business) {
    final address = business['address'];
    if (address is Map) {
      final city = address['city'];
      if (city != null && city.toString().trim().isNotEmpty) {
        return city.toString();
      }
      final area = address['area'];
      if (area != null && area.toString().trim().isNotEmpty) {
        return area.toString();
      }
    }
    if (address is String && address.trim().isNotEmpty) return address;

    final city = business['city'];
    if (city != null && city.toString().trim().isNotEmpty) {
      return city.toString();
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final params = <String, dynamic>{};
      if (_category != 'all') params['category'] = _category;
      if (_search.isNotEmpty) params['search'] = _search;

      final res = await _api.getStoreBusinesses(params: params);
      setState(() {
        _businesses = res.data is List
            ? res.data
            : (res.data?['businesses'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + Title
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/store'),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(backgroundColor: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                'All Businesses',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search
          TextField(
            onChanged: (v) {
              _search = v;
              _fetch();
            },
            decoration: InputDecoration(
              hintText: 'Search businesses...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.gray200),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Category Chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _categoryChip('All', 'all'),
                ...businessCategories.map(
                  (c) => _categoryChip(c.label, c.value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_businesses.isEmpty)
            _emptyState()
          else
            ..._businesses.map(
              (b) => _bizCard(Map<String, dynamic>.from(b as Map)),
            ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, String value) {
    final active = _category == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _category = value;
          });
          _fetch();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary600 : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppColors.primary600 : AppColors.gray200,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? Colors.white : AppColors.gray600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bizCard(Map<String, dynamic> b) {
    final city = _businessCity(b);
    return GestureDetector(
      onTap: () => context.go('/store/business/${b['_id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary100,
              child: Text(
                (b['name'] ?? '?')[0].toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b['name'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    b['category'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
                  if (city.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.gray400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          city,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.store_outlined, size: 56, color: AppColors.gray300),
            const SizedBox(height: 12),
            Text(
              'No businesses found',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search or filters',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}
