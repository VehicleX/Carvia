import 'dart:math';
import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/compare_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/widgets/vehicle_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Scoring engine
// ─────────────────────────────────────────────────────────────────────────────
class _Score {
  final String label;
  final IconData icon;
  final double v1; // 0-10
  final double v2; // 0-10
  final String raw1;
  final String raw2;

  const _Score({
    required this.label,
    required this.icon,
    required this.v1,
    required this.v2,
    required this.raw1,
    required this.raw2,
  });
}

List<_Score> _computeScores(VehicleModel a, VehicleModel b) {
  double _norm(double val, double best, double worst, {bool lowerBetter = false}) {
    if (best == worst) return 5.0;
    final ratio = lowerBetter
        ? (worst - val) / (worst - best)
        : (val - worst) / (best - worst);
    return (ratio * 10).clamp(0, 10).toDouble();
  }

  // Price – lower is better
  final minP = min(a.price, b.price);
  final maxP = max(a.price, b.price);

  // Year – higher is better
  final minY = min(a.year, b.year).toDouble();
  final maxY = max(a.year, b.year).toDouble();

  // Mileage – lower is better (less KM driven)
  final minM = min(a.mileage, b.mileage).toDouble();
  final maxM = max(a.mileage, b.mileage).toDouble();

  // Fuel type score (electric > hybrid > cng > diesel > petrol)
  double _fuelScore(String f) {
    final m = {
      'electric': 10.0, 'ev': 10.0,
      'hybrid': 8.0,
      'cng': 7.0,
      'diesel': 5.0,
      'petrol': 4.0,
    };
    return m[f.toLowerCase()] ?? 5.0;
  }

  // Transmission score (auto > cvt > manual)
  double _transScore(String t) {
    final m = {
      'automatic': 10.0, 'cvt': 9.0, 'amt': 7.0, 'manual': 5.0,
    };
    return m[t.toLowerCase()] ?? 5.0;
  }

  // Popularity (wishlist + views composite)
  final maxWish = max(a.wishlistCount, b.wishlistCount).toDouble();
  final maxViews = max(a.viewsCount, b.viewsCount).toDouble();
  double _popScore(VehicleModel v) {
    final w = maxWish > 0 ? (v.wishlistCount / maxWish) * 5 : 0.0;
    final vv = maxViews > 0 ? (v.viewsCount / maxViews) * 5 : 0.0;
    return (w + vv).clamp(0, 10);
  }

  return [
    _Score(
      label: 'Price',
      icon: Iconsax.money,
      v1: _norm(a.price, minP, maxP, lowerBetter: true),
      v2: _norm(b.price, minP, maxP, lowerBetter: true),
      raw1: '₹${_compact(a.price)}',
      raw2: '₹${_compact(b.price)}',
    ),
    _Score(
      label: 'Year',
      icon: Iconsax.calendar_1,
      v1: _norm(a.year.toDouble(), maxY, minY),
      v2: _norm(b.year.toDouble(), maxY, minY),
      raw1: '${a.year}',
      raw2: '${b.year}',
    ),
    _Score(
      label: 'Mileage',
      icon: Iconsax.speedometer,
      v1: _norm(a.mileage.toDouble(), minM, maxM, lowerBetter: true),
      v2: _norm(b.mileage.toDouble(), minM, maxM, lowerBetter: true),
      raw1: '${a.mileage} km',
      raw2: '${b.mileage} km',
    ),
    _Score(
      label: 'Fuel',
      icon: Iconsax.gas_station,
      v1: _fuelScore(a.fuel),
      v2: _fuelScore(b.fuel),
      raw1: a.fuel,
      raw2: b.fuel,
    ),
    _Score(
      label: 'Transmission',
      icon: Iconsax.setting_2,
      v1: _transScore(a.transmission),
      v2: _transScore(b.transmission),
      raw1: a.transmission,
      raw2: b.transmission,
    ),
    _Score(
      label: 'Popularity',
      icon: Iconsax.heart,
      v1: _popScore(a),
      v2: _popScore(b),
      raw1: '${a.wishlistCount} ❤',
      raw2: '${b.wishlistCount} ❤',
    ),
  ];
}

String _compact(double v) {
  if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
  if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
  return v.toStringAsFixed(0);
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Page
// ─────────────────────────────────────────────────────────────────────────────
class ComparePage extends StatelessWidget {
  const ComparePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compare Vehicles',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear All',
            onPressed: () =>
                Provider.of<CompareService>(context, listen: false).clearcompare(),
          ),
        ],
      ),
      body: Consumer<CompareService>(
        builder: (context, cs, _) {
          final vehicles = cs.compareList;

          if (vehicles.isEmpty) {
            return _EmptyState(
                onAdd: () => _showVehiclePicker(context, cs));
          }

          final v1 = vehicles[0];
          final v2 = vehicles.length > 1 ? vehicles[1] : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header cards ──────────────────────────────────────
                _HeaderRow(
                  v1: v1,
                  v2: v2,
                  onAddSecond: () => _showVehiclePicker(context, cs),
                ),
                const SizedBox(height: 20),

                // ── Only show scoring + recommendation when 2 vehicles ─
                if (v2 != null) ...[
                  _ScoreSection(v1: v1, v2: v2),
                  const SizedBox(height: 20),
                  _RecommendationBanner(v1: v1, v2: v2),
                  const SizedBox(height: 20),
                ],

                // ── Spec comparison table ─────────────────────────────
                _SpecTable(v1: v1, v2: v2),

                if (v2 == null) ...[
                  const SizedBox(height: 20),
                  _AddVehicleButton(onTap: () => _showVehiclePicker(context, cs)),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showVehiclePicker(BuildContext context, CompareService cs) {
    if (cs.compareList.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can compare only 2 vehicles at a time')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const VehicleSelectionBottomSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header Row — two vehicle cards side by side
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderRow extends StatelessWidget {
  final VehicleModel v1;
  final VehicleModel? v2;
  final VoidCallback onAddSecond;

  const _HeaderRow({required this.v1, this.v2, required this.onAddSecond});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _VehicleCard(vehicle: v1)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('VS',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary)),
        ),
        Expanded(
          child: v2 != null
              ? _VehicleCard(vehicle: v2!)
              : _AddSlot(onTap: onAddSecond),
        ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: vehicle.images.isNotEmpty
                    ? VehicleImage(
                        src: vehicle.images.first,
                        height: 100,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        height: 100,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.05),
                        child: Icon(Icons.directions_car,
                            size: 40,
                            color: Theme.of(context).colorScheme.secondary),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(
                      '${vehicle.brand} ${vehicle.model}',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.displayPrice,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () =>
                  Provider.of<CompareService>(context, listen: false)
                      .toggleCompare(vehicle),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSlot extends StatelessWidget {
  final VoidCallback onTap;
  const _AddSlot({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
              width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(height: 8),
            Text('Add Vehicle',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Score Section with animated bar chart
// ─────────────────────────────────────────────────────────────────────────────
class _ScoreSection extends StatefulWidget {
  final VehicleModel v1;
  final VehicleModel v2;
  const _ScoreSection({required this.v1, required this.v2});

  @override
  State<_ScoreSection> createState() => _ScoreSectionState();
}

class _ScoreSectionState extends State<_ScoreSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scores = _computeScores(widget.v1, widget.v2);
    final total1 = scores.fold(0.0, (s, e) => s + e.v1);
    final total2 = scores.fold(0.0, (s, e) => s + e.v2);
    final maxTotal = scores.length * 10.0;

    final c1 = Theme.of(context).colorScheme.primary;
    final c2 = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Icon(Iconsax.chart_21, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Score Comparison',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 6),

          // Legend
          Row(
            children: [
              _Dot(color: c1),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${widget.v1.brand} ${widget.v1.model}',
                  style: TextStyle(fontSize: 12, color: c1, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _Dot(color: c2),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${widget.v2.brand} ${widget.v2.model}',
                  style: TextStyle(fontSize: 12, color: c2, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Score rows
          ...scores.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ScoreRow(score: s, anim: _anim, c1: c1, c2: c2),
              )),

          const Divider(height: 24),

          // Total score bars
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) {
              final pct1 = (total1 / maxTotal) * _anim.value;
              final pct2 = (total2 / maxTotal) * _anim.value;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'TOTAL SCORE',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                      Text(
                        '${total1.toStringAsFixed(1)} / ${total2.toStringAsFixed(1)}',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct1,
                            minHeight: 10,
                            backgroundColor:
                                c1.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation(c1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct2,
                            minHeight: 10,
                            backgroundColor:
                                c2.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation(c2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _ScoreRow extends StatelessWidget {
  final _Score score;
  final Animation<double> anim;
  final Color c1;
  final Color c2;

  const _ScoreRow(
      {required this.score,
      required this.anim,
      required this.c1,
      required this.c2});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final pct1 = (score.v1 / 10) * anim.value;
        final pct2 = (score.v2 / 10) * anim.value;
        final winner = score.v1 > score.v2
            ? 1
            : score.v2 > score.v1
                ? 2
                : 0;

        return Row(
          children: [
            // Left bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(score.raw1,
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.secondary)),
                      if (winner == 1)
                        Icon(Icons.star_rounded, size: 12, color: c1),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct1,
                      minHeight: 7,
                      backgroundColor: c1.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(c1),
                    ),
                  ),
                ],
              ),
            ),

            // Centre label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Icon(score.icon,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(height: 2),
                  Text(score.label,
                      style: TextStyle(
                          fontSize: 9,
                          color: Theme.of(context).colorScheme.secondary)),
                ],
              ),
            ),

            // Right bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (winner == 2)
                        Icon(Icons.star_rounded, size: 12, color: c2),
                      Text(score.raw2,
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.secondary)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct2,
                      minHeight: 7,
                      backgroundColor: c2.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(c2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recommendation Banner
// ─────────────────────────────────────────────────────────────────────────────
class _RecommendationBanner extends StatelessWidget {
  final VehicleModel v1;
  final VehicleModel v2;
  const _RecommendationBanner({required this.v1, required this.v2});

  @override
  Widget build(BuildContext context) {
    final scores = _computeScores(v1, v2);
    final total1 = scores.fold(0.0, (s, e) => s + e.v1);
    final total2 = scores.fold(0.0, (s, e) => s + e.v2);

    final VehicleModel winner;
    final String reason;
    final String subReason;

    if (total1 > total2) {
      winner = v1;
      final diff = total1 - total2;
      reason = 'Better overall score (+${diff.toStringAsFixed(1)} pts)';
      subReason = _buildSubReason(scores, forFirst: true);
    } else if (total2 > total1) {
      winner = v2;
      final diff = total2 - total1;
      reason = 'Better overall score (+${diff.toStringAsFixed(1)} pts)';
      subReason = _buildSubReason(scores, forFirst: false);
    } else {
      // Tie
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
          ]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.balance_rounded,
                color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Both vehicles are equally matched! Choose based on your personal preference.',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.13),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.emoji_events_rounded,
                    color: Theme.of(context).colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('★  Best for You',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 2),
                    Text(
                      '${winner.brand} ${winner.model}',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color:
                              Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReasonChip(icon: Icons.trending_up_rounded, text: reason),
          const SizedBox(height: 6),
          if (subReason.isNotEmpty)
            _ReasonChip(icon: Icons.check_circle_outline_rounded, text: subReason),
          const SizedBox(height: 12),
          Text(
            'We recommend the ${winner.brand} ${winner.model} based on price, '
            'year, mileage, fuel efficiency score and popularity.',
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .secondary,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  String _buildSubReason(List<_Score> scores, {required bool forFirst}) {
    final winning = <String>[];
    for (final s in scores) {
      final myScore = forFirst ? s.v1 : s.v2;
      final otherScore = forFirst ? s.v2 : s.v1;
      if (myScore > otherScore) winning.add(s.label);
    }
    if (winning.isEmpty) return '';
    return 'Wins on: ${winning.join(', ')}';
  }
}

class _ReasonChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ReasonChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => Row(
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spec Table
// ─────────────────────────────────────────────────────────────────────────────
class _SpecTable extends StatelessWidget {
  final VehicleModel v1;
  final VehicleModel? v2;
  const _SpecTable({required this.v1, this.v2});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Brand', v1.brand, v2?.brand),
      ('Model', v1.model, v2?.model),
      ('Year', '${v1.year}', v2 != null ? '${v2!.year}' : null),
      ('Price', v1.displayPrice, v2?.displayPrice),
      ('Fuel Type', v1.fuel, v2?.fuel),
      ('Transmission', v1.transmission, v2?.transmission),
      ('Mileage', '${v1.mileage} km', v2 != null ? '${v2!.mileage} km' : null),
      ('Type', v1.type, v2?.type),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Iconsax.element_3,
                    color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Spec Details',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          ...rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final (label, val1, val2) = entry.value;
            final isEven = idx.isEven;
            return _SpecRow(
              label: label,
              val1: val1,
              val2: val2,
              shaded: isEven,
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String val1;
  final String? val2;
  final bool shaded;

  const _SpecRow(
      {required this.label,
      required this.val1,
      this.val2,
      this.shaded = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: shaded
          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.secondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(val1,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Text(val2 ?? '—',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: val2 != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.5))),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add button
// ─────────────────────────────────────────────────────────────────────────────
class _AddVehicleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddVehicleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add),
        label: const Text('Add Another Vehicle to Compare'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compare_arrows_rounded,
              size: 72,
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No vehicles to compare',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.secondary)),
          const SizedBox(height: 8),
          Text('Add two vehicles to see score comparison & recommendation',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.7),
                  fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Vehicle'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle Selection Bottom Sheet (unchanged logic, improved style)
// ─────────────────────────────────────────────────────────────────────────────
class VehicleSelectionBottomSheet extends StatefulWidget {
  const VehicleSelectionBottomSheet({super.key});

  @override
  State<VehicleSelectionBottomSheet> createState() =>
      _VehicleSelectionBottomSheetState();
}

class _VehicleSelectionBottomSheetState
    extends State<VehicleSelectionBottomSheet> {
  String _searchQuery = '';
  VehicleModel? _selectedVehicle;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Container(
      height: height * 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Vehicle',
                  style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
              IconButton(
                  icon: Icon(Icons.close,
                      color: Theme.of(context).colorScheme.secondary),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) =>
                setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search vehicles...',
              prefixIcon: Icon(Icons.search,
                  color: Theme.of(context).colorScheme.secondary),
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<VehicleModel>>(
              stream: Provider.of<VehicleService>(context, listen: false)
                  .getAllVehiclesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text('No vehicles available',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary)));
                }

                final cs = Provider.of<CompareService>(context, listen: false);
                var available = snapshot.data!
                    .where((v) => !cs.isInCompare(v.id))
                    .toList();

                if (_searchQuery.isNotEmpty) {
                  available = available
                      .where((v) =>
                          v.brand.toLowerCase().contains(_searchQuery) ||
                          v.model.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                if (available.isEmpty) {
                  return Center(
                      child: Text('No match found',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary)));
                }

                return ListView.builder(
                  itemCount: available.length,
                  itemBuilder: (ctx, idx) {
                    final vehicle = available[idx];
                    final isSelected = _selectedVehicle?.id == vehicle.id;

                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedVehicle = vehicle),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${vehicle.brand} ${vehicle.model}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${vehicle.year} • ${vehicle.fuel}',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(vehicle.displayPrice,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded,
                                  color: Theme.of(context).colorScheme.primary),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_selectedVehicle != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final success = Provider.of<CompareService>(context,
                          listen: false)
                      .addToCompare(_selectedVehicle!);
                  Navigator.pop(context);
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text('You can compare only 2 vehicles at a time')));
                  }
                },
                child: const Text('Add to Compare'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
