import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/helpers.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _api = ApiService();
  List<dynamic> _tickets = [];
  bool _loading = true;
  String _filter = 'all';
  String _search = '';
  final _replyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final res = await _api.getSupportTickets();
      setState(() {
        _tickets = res.data is List ? res.data : [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered {
    var list = _tickets;
    if (_filter != 'all') {
      list = list
          .where((t) => (t['status'] ?? '').toString().toLowerCase() == _filter)
          .toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((t) {
        return (t['customerName'] ?? '').toString().toLowerCase().contains(q) ||
            (t['subject'] ?? '').toString().toLowerCase().contains(q) ||
            (t['orderNumber'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  Future<void> _reply(String ticketId) async {
    if (_replyCtrl.text.trim().isEmpty) return;
    try {
      await _api.replySupportTicket(ticketId, {
        'message': _replyCtrl.text.trim(),
      });
      _replyCtrl.clear();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      _fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send reply: $e')));
      }
    }
  }

  Future<void> _updateStatus(String ticketId, String status) async {
    try {
      await _api.updateSupportTicketStatus(ticketId, status);
      _fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  void _openReplyDialog(Map<String, dynamic> ticket) {
    _replyCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reply to ${ticket['customerName'] ?? 'Customer'}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ticket['subject'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.gray500,
                  ),
                ),
                const SizedBox(height: 16),
                // Original message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Original Message',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticket['message'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.gray700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Reply',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray700,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _replyCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Write your reply...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.gray200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.gray200),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
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
                      child: ElevatedButton.icon(
                        onPressed: () => _reply(ticket['_id']),
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('Send Reply'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final filtered = _filtered;
    final openCount = _tickets.where((t) => t['status'] == 'open').length;
    final inProgressCount = _tickets
        .where((t) => t['status'] == 'in_progress')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support Inbox',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$openCount open • $inProgressCount in progress',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filter chips + Search
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip('All', 'all'),
            _filterChip('Open', 'open'),
            _filterChip('In Progress', 'in_progress'),
            _filterChip('Resolved', 'resolved'),
            const SizedBox(width: 8),
            SizedBox(
              width: 220,
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search tickets...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Ticket List
        if (filtered.isEmpty)
          _emptyState()
        else
          ...filtered.map(
            (t) => _ticketCard(Map<String, dynamic>.from(t as Map)),
          ),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary600 : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
    );
  }

  Widget _ticketCard(Map<String, dynamic> t) {
    final status = (t['status'] ?? 'open').toString();
    final statusColor = _statusColor(status);
    final statusLabel = status
        .replaceAll('_', ' ')
        .replaceFirstMapped(RegExp(r'^\w'), (m) => m[0]!.toUpperCase());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
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
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF3E8FF),
                child: Text(
                  (t['customerName'] ?? '?')[0].toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9333EA),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['customerName'] ?? 'Customer',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    if ((t['orderNumber'] ?? '').toString().isNotEmpty)
                      Text(
                        'Order: ${t['orderNumber']}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if ((t['issueType'] ?? '').toString().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                t['issueType'],
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray600,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            t['subject'] ?? '',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t['message'] ?? '',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.gray600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(
            formatDateTime(t['createdAt'] ?? ''),
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.gray400),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _openReplyDialog(t),
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('Reply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: GoogleFonts.inter(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              if (status == 'open')
                OutlinedButton(
                  onPressed: () => _updateStatus(t['_id'], 'in_progress'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray600,
                    side: BorderSide(color: AppColors.gray200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Mark In Progress'),
                ),
              if (status == 'in_progress')
                OutlinedButton(
                  onPressed: () => _updateStatus(t['_id'], 'resolved'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF22C55E),
                    side: const BorderSide(color: Color(0xFF22C55E)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Resolve'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  ({Color bg, Color text}) _statusColor(String status) {
    switch (status) {
      case 'open':
        return (bg: const Color(0xFFFEF3C7), text: const Color(0xFF92400E));
      case 'in_progress':
        return (bg: const Color(0xFFDBEAFE), text: const Color(0xFF1E40AF));
      case 'resolved':
        return (bg: const Color(0xFFDCFCE7), text: const Color(0xFF166534));
      default:
        return (bg: AppColors.gray100, text: AppColors.gray800);
    }
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: [
          Icon(Icons.chat_outlined, size: 64, color: AppColors.gray300),
          const SizedBox(height: 12),
          Text(
            'No tickets found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'When customers reach out, tickets will appear here',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}
