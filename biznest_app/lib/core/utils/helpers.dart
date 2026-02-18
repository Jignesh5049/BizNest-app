import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Format currency in Indian Rupees
String formatCurrency(num? amount) {
  if (amount == null) return '₹0.00';
  final format = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  return format.format(amount);
}

/// Format date
String formatDate(String? date) {
  if (date == null || date.isEmpty) return '';
  final dt = DateTime.tryParse(date);
  if (dt == null) return '';
  return DateFormat('d MMM yyyy').format(dt);
}

/// Format date time
String formatDateTime(String? date) {
  if (date == null || date.isEmpty) return '';
  final dt = DateTime.tryParse(date);
  if (dt == null) return '';
  return DateFormat('d MMM yyyy, hh:mm a').format(dt);
}

/// Get status badge color and background
({Color bg, Color text}) getStatusColor(String? status) {
  switch (status?.toLowerCase()) {
    case 'pending':
      return (bg: AppColors.warningLight, text: const Color(0xFF92400E));
    case 'confirmed':
      return (bg: AppColors.infoLight, text: const Color(0xFF1E40AF));
    case 'completed':
    case 'paid':
      return (bg: AppColors.successLight, text: const Color(0xFF166534));
    case 'cancelled':
    case 'unpaid':
      return (bg: AppColors.dangerLight, text: const Color(0xFF991B1B));
    case 'partial':
      return (bg: AppColors.warningLight, text: const Color(0xFF92400E));
    default:
      return (bg: AppColors.gray100, text: AppColors.gray800);
  }
}

/// Calculate profit margin
String calculateMargin(num? costPrice, num? sellingPrice) {
  if (costPrice == null || costPrice == 0) return '100.0';
  return (((sellingPrice ?? 0) - costPrice) / costPrice * 100).toStringAsFixed(
    1,
  );
}

/// Calculate selling price from margin
double calculateSellingPrice(num costPrice, num marginPercent) {
  return costPrice * (1 + marginPercent / 100);
}

/// Get stock status
({String label, Color bg, Color text}) getStockStatus(int? stock) {
  if (stock == null || stock == 0) {
    return (
      label: 'Out of Stock',
      bg: AppColors.dangerLight,
      text: const Color(0xFF991B1B),
    );
  }
  if (stock <= 5) {
    return (
      label: 'Low Stock',
      bg: AppColors.warningLight,
      text: const Color(0xFF92400E),
    );
  }
  return (
    label: 'In Stock',
    bg: AppColors.successLight,
    text: const Color(0xFF166534),
  );
}

/// Expense categories with labels and icons
const Map<String, ({String label, IconData icon})> expenseCategories = {
  'raw_material': (label: 'Raw Material', icon: Icons.inventory_2_outlined),
  'delivery': (label: 'Delivery', icon: Icons.local_shipping_outlined),
  'marketing': (label: 'Marketing', icon: Icons.campaign_outlined),
  'utilities': (label: 'Utilities', icon: Icons.lightbulb_outlined),
  'rent': (label: 'Rent', icon: Icons.home_outlined),
  'salary': (label: 'Salary', icon: Icons.currency_rupee_outlined),
  'equipment': (label: 'Equipment', icon: Icons.settings_outlined),
  'packaging': (label: 'Packaging', icon: Icons.archive_outlined),
  'misc': (label: 'Miscellaneous', icon: Icons.list_alt_outlined),
};

/// Business categories
const List<({String value, String label})> businessCategories = [
  (value: 'retail', label: 'Retail Store'),
  (value: 'food', label: 'Food & Beverages'),
  (value: 'services', label: 'Services'),
  (value: 'handmade', label: 'Handmade & Crafts'),
  (value: 'consulting', label: 'Consulting'),
  (value: 'other', label: 'Other'),
];
