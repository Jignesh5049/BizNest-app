import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../cubit/cart_cubit.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final cart = context.read<CartCubit>();

        if (state.items.isEmpty && state.savedForLater.isEmpty) {
          return _emptyCart(context);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shopping Cart', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.gray900)),
              Text('${state.itemCount} items', style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500)),
              const SizedBox(height: 16),

              // Cart Items
              ...state.items.map((item) => _cartItemCard(context, cart, item)),

              // Summary
              if (state.items.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gray100),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal', style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray600)),
                          Text(formatCurrency(state.total), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray900)),
                          Text(formatCurrency(state.total), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary600)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/store/checkout'),
                          icon: const Icon(Icons.shopping_bag, size: 18),
                          label: const Text('Proceed to Checkout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Saved for Later
              if (state.savedForLater.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Saved for Later (${state.savedForLater.length})',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                const SizedBox(height: 12),
                ...state.savedForLater.map((item) => _savedItemCard(context, cart, item)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _cartItemCard(BuildContext context, CartCubit cart, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
              child: item.image != null
                  ? Image.network(item.image!, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: AppColors.gray100, child: Icon(Icons.image, color: AppColors.gray300)))
                  : Container(color: AppColors.gray100, child: Icon(Icons.image, color: AppColors.gray300)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(formatCurrency(item.price), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Quantity controls
                    Container(
                      decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        IconButton(
                          onPressed: () => cart.updateQuantity(item.productId, item.quantity - 1),
                          icon: const Icon(Icons.remove, size: 16),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                        Text('${item.quantity}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        IconButton(
                          onPressed: () => cart.updateQuantity(item.productId, item.quantity + 1),
                          icon: const Icon(Icons.add, size: 16),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                      ]),
                    ),
                    const Spacer(),
                    // Save for later
                    IconButton(
                      onPressed: () => cart.saveForLater(item.productId),
                      icon: const Icon(Icons.bookmark_border, size: 20),
                      tooltip: 'Save for later',
                      color: AppColors.gray500,
                    ),
                    // Remove
                    IconButton(
                      onPressed: () => cart.removeFromCart(item.productId),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Remove',
                      color: AppColors.danger,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _savedItemCard(BuildContext context, CartCubit cart, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: item.image != null
                  ? Image.network(item.image!, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: AppColors.gray100, child: Icon(Icons.image, size: 24, color: AppColors.gray300)))
                  : Container(color: AppColors.gray100, child: Icon(Icons.image, size: 24, color: AppColors.gray300)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                Text(formatCurrency(item.price), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary600)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => cart.moveToCart(item.productId),
            child: Text('Move to Cart', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary600)),
          ),
          IconButton(
            onPressed: () => cart.removeFromSaved(item.productId),
            icon: Icon(Icons.close, size: 18, color: AppColors.gray400),
          ),
        ],
      ),
    );
  }

  Widget _emptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 72, color: AppColors.gray300),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray900)),
          const SizedBox(height: 8),
          Text('Browse products and add them to your cart', style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/store'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }
}
