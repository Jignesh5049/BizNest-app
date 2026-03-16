import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
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

/// Resolve image URLs for web/emulator/physical devices.
String resolveImageUrl(String? rawUrl) {
  var input = (rawUrl ?? '').trim();
  if (input.isEmpty) return '';

  // Normalize slashes from legacy/windows style paths.
  input = input.replaceAll('\\', '/');

  const serverIp = '192.168.6.16';
  final origin = kIsWeb
      ? 'http://localhost:5000'
      : (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS
            ? 'http://$serverIp:5000'
            : 'http://localhost:5000');

  final localhostOrigin = 'http://localhost:5000';
  final loopbackOrigin = 'http://127.0.0.1:5000';
  final emulatorOrigin = 'http://10.0.2.2:5000';

  // Already-displayable non-http sources.
  if (input.startsWith('data:') || input.startsWith('blob:')) return input;

  // Handle protocol-relative and bare website URLs.
  if (input.startsWith('//')) return 'https:$input';
  if (input.startsWith('www.')) return 'https://$input';

  // Handle malformed protocol variants like `http//example.com/img.jpg`.
  if (input.startsWith('http//')) {
    input = input.replaceFirst('http//', 'http://');
  } else if (input.startsWith('https//')) {
    input = input.replaceFirst('https//', 'https://');
  }

  // Handle protocol-less domain URLs like `cdn.site.com/image.jpg`.
  final looksLikeDomainPath = RegExp(
    r'^[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+([/:?].*)?$',
  ).hasMatch(input);
  if (!input.startsWith('/') &&
      !input.startsWith('uploads/') &&
      looksLikeDomainPath &&
      !input.startsWith('http://') &&
      !input.startsWith('https://')) {
    input = 'https://$input';
  }

  // Handle malformed localhost strings without scheme.
  if (input.startsWith('localhost:') ||
      input.startsWith('127.0.0.1:') ||
      input.startsWith('10.0.2.2:')) {
    input = 'http://$input';
  }

  // Legacy storage may keep just uploads path in different forms.
  if (input.startsWith('uploads/')) {
    input = '/$input';
  }

  if (input.startsWith('http://') || input.startsWith('https://')) {
    // Encode unsafe characters (spaces, etc.) in legacy URLs.
    input = Uri.encodeFull(input);

    final uri = Uri.tryParse(input);

    // If URL is invalid after parse, return as-is so caller can handle fallback UI.
    if (uri == null || uri.host.isEmpty) return input;

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      final isLocalHost =
          uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '10.0.2.2';
      if (isLocalHost) {
        return input
            .replaceFirst(localhostOrigin, origin)
            .replaceFirst(loopbackOrigin, origin)
            .replaceFirst(emulatorOrigin, origin);
      }
    }

    return input;
  }

  if (input.startsWith('/')) return '$origin$input';
  return '$origin/$input';
}

String resolveProductImageUrl(Map<String, dynamic> product) {
  final image =
      product['image'] ??
      product['imageUrl'] ??
      product['thumbnail'] ??
      product['photo'] ??
      product['productImage'] ??
      (product['media'] is Map ? product['media']['url'] : null) ??
      (product['image'] is Map ? product['image']['url'] : null);

  if (image is String && image.trim().isNotEmpty) {
    return resolveImageUrl(image);
  }

  final images = product['images'];
  if (images is List && images.isNotEmpty) {
    final first = images.first;
    if (first is String && first.trim().isNotEmpty) {
      return resolveImageUrl(first);
    }
    if (first is Map) {
      final nested =
          first['url'] ?? first['src'] ?? first['secure_url'] ?? first['image'];
      if (nested is String && nested.trim().isNotEmpty) {
        return resolveImageUrl(nested);
      }
    }
  }

  return '';
}

String resolveOrderItemImageUrl(Map<String, dynamic> item) {
  String _asUrl(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is Map) {
      final nested =
          value['url'] ?? value['src'] ?? value['secure_url'] ?? value['image'];
      if (nested is String && nested.trim().isNotEmpty) return nested;
    }
    return '';
  }

  final productMap = item['product'] is Map
      ? Map<String, dynamic>.from(item['product'])
      : (item['productId'] is Map
            ? Map<String, dynamic>.from(item['productId'])
            : null);

  final directCandidates = [
    item['image'],
    item['imageUrl'],
    item['thumbnail'],
    item['photo'],
    item['productImage'],
    item['media'] is Map ? item['media']['url'] : null,
  ];

  for (final candidate in directCandidates) {
    final url = _asUrl(candidate);
    if (url.isNotEmpty) return resolveImageUrl(url);
  }

  if (productMap != null) {
    final productUrl = resolveProductImageUrl(productMap);
    if (productUrl.isNotEmpty) return resolveImageUrl(productUrl);
  }

  final images = item['images'];
  if (images is List && images.isNotEmpty) {
    final first = images.first;
    final url = _asUrl(first);
    if (url.isNotEmpty) return resolveImageUrl(url);
  }

  return '';
}

Uint8List? decodeBase64ImageBytes(String? rawUrl) {
  final input = (rawUrl ?? '').trim();
  if (!input.startsWith('data:image')) return null;

  final commaIndex = input.indexOf(',');
  if (commaIndex == -1 || commaIndex >= input.length - 1) return null;

  try {
    return base64Decode(input.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}

ImageProvider<Object>? resolveImageProvider(String? rawUrl) {
  final bytes = decodeBase64ImageBytes(rawUrl);
  if (bytes != null && bytes.isNotEmpty) return MemoryImage(bytes);

  final url = resolveImageUrl(rawUrl);
  if (url.isEmpty || url.startsWith('data:')) return null;
  return NetworkImage(url);
}
