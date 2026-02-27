import 'package:carvia/core/models/challan_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/challan_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PoliceChallanListPage extends StatefulWidget {
  const PoliceChallanListPage({super.key});

  @override
  State<PoliceChallanListPage> createState() => _PoliceChallanListPageState();
}

class _PoliceChallanListPageState extends State<PoliceChallanListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ChallanModel>? _challans;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChallans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChallans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final officerId =
          Provider.of<AuthService>(context, listen: false).currentUser!.uid;
      final challans = await Provider.of<ChallanService>(context, listen: false)
          .fetchIssuedChallans(officerId);
      if (mounted) setState(() => _challans = challans);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ChallanModel> _filtered(ChallanStatus? status) {
    if (_challans == null) return [];
    if (status == null) return _challans!;
    return _challans!.where((c) => c.status == status).toList();
  }

  Future<void> _deleteChallan(String challanId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Challan?"),
        content: const Text(
          "This action cannot be undone. The challan will be removed from the system.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep it"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<ChallanService>(context, listen: false)
            .deleteChallan(challanId);
        _loadChallans(); // Refresh list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Challan deleted successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "My Issued Challans",
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fadeIn().slideX(begin: -0.2),
                        const SizedBox(height: 4),
                        Text(
                          _challans == null
                              ? "Loading…"
                              : "${_challans!.length} challan(s) issued by you",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 13,
                          ),
                        ).animate().fadeIn(delay: 150.ms),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loadChallans,
                    icon: const Icon(Iconsax.refresh),
                    tooltip: "Refresh",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Filter Tabs
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.onSurface,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: "All"),
                Tab(text: "Unpaid"),
                Tab(text: "Paid"),
              ],
            ),
            // ── List Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildList(null),
                            _buildList(ChallanStatus.unpaid),
                            _buildList(ChallanStatus.paid),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ChallanStatus? filter) {
    final items = _filtered(filter);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.receipt,
                size: 56,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No challans found",
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Challans you issue will appear here.",
              style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 13),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadChallans,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildChallanCard(items[index], index),
      ),
    );
  }

  Widget _buildChallanCard(ChallanModel challan, int index) {
    final isPaid = challan.status == ChallanStatus.paid;
    final isDisputed = challan.status == ChallanStatus.disputed;

    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;

    if (isPaid) {
      statusColor = Colors.green;
      statusIcon = Iconsax.tick_circle;
      statusLabel = "PAID";
    } else if (isDisputed) {
      statusColor = Colors.orange;
      statusIcon = Iconsax.warning_2;
      statusLabel = "DISPUTED";
    } else {
      statusColor = Colors.red;
      statusIcon = Iconsax.timer_1;
      statusLabel = "UNPAID";
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Violation icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Iconsax.receipt_1, color: statusColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challan.violationType,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Iconsax.car,
                              size: 12,
                              color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            challan.vehicleNumber,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 12,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _deleteChallan(challan.id),
                      child: Icon(
                        Iconsax.trash,
                        size: 20,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _infoChip(
                  Icons.currency_rupee,
                  "₹${challan.fineAmount.toStringAsFixed(0)}",
                  statusColor,
                ),
                const SizedBox(width: 12),
                _infoChip(
                  Iconsax.calendar_1,
                  DateFormat('dd MMM yyyy').format(challan.issuedAt),
                  Theme.of(context).colorScheme.secondary,
                ),
                if (challan.paymentDueDate != null) ...[
                  const SizedBox(width: 12),
                  _infoChip(
                    Iconsax.timer,
                    "Due: ${DateFormat('dd MMM').format(challan.paymentDueDate!)}",
                    isPaid
                        ? Colors.green
                        : challan.paymentDueDate!.isBefore(DateTime.now())
                            ? Colors.red
                            : Colors.orange,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2,
              size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text("Failed to load challans",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(_error ?? "",
              style:
                  TextStyle(color: Theme.of(context).colorScheme.secondary)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadChallans,
            icon: const Icon(Iconsax.refresh),
            label: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
