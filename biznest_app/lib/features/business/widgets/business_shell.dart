import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'sidebar.dart';

class BusinessShell extends StatefulWidget {
  final Widget child;

  const BusinessShell({super.key, required this.child});

  @override
  State<BusinessShell> createState() => _BusinessShellState();
}

class _BusinessShellState extends State<BusinessShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.gray50,
      // Mobile drawer
      drawer: isDesktop
          ? null
          : Drawer(
              width: 260,
              child: AppSidebar(
                onClose: () => _scaffoldKey.currentState?.closeDrawer(),
              ),
            ),
      body: Row(
        children: [
          // Desktop persistent sidebar
          if (isDesktop)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: AppColors.gray200),
                ),
              ),
              child: const AppSidebar(),
            ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Mobile App Bar
                if (!isDesktop)
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.gray200),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            icon: const Icon(Icons.menu, size: 24),
                            color: AppColors.gray600,
                          ),
                          const Spacer(),
                          Text(
                            'BizNest',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48), // Balance the menu button
                        ],
                      ),
                    ),
                  ),

                // Page Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 32 : 16),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
