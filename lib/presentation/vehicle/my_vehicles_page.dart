import 'dart:async';
import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/auth_service.dart';

import 'package:carvia/core/theme/app_theme.dart';

import 'package:carvia/presentation/vehicle/add_external_vehicle_page.dart';
import 'package:carvia/presentation/challan/e_challan_page.dart';
import 'package:carvia/presentation/vehicle/insurance_page.dart';
import 'package:carvia/presentation/vehicle/transfer_ownership_page.dart';
import 'package:carvia/presentation/vehicle/vehicle_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class MyVehiclesPage extends StatefulWidget {
  const MyVehiclesPage({super.key});

  @override
  State<MyVehiclesPage> createState() => _MyVehiclesPageState();
}

class _MyVehiclesPageState extends State<MyVehiclesPage> {
  /// Merges owned_vehicles (purchased via app) and external_vehicles (manually added)
  /// into a single real-time stream.
  Stream<List<VehicleModel>> _buildMergedStream(String userId) {
    final firestore = FirebaseFirestore.instance;

    final ownedStream = firestore
        .collection('users')
        .doc(userId)
        .collection('owned_vehicles')
        .snapshots()
        .map((s) => s.docs.map((d) => VehicleModel.fromMap(d.data(), d.id)).toList());

    final externalStream = firestore
        .collection('users')
        .doc(userId)
        .collection('external_vehicles')
        .snapshots()
        .map((s) => s.docs.map((d) => VehicleModel.fromMap(d.data(), d.id)).toList());

    // Merge both streams by keeping the latest snapshot from each
    return StreamZip([ownedStream, externalStream])
        .map((lists) => [...lists[0], ...lists[1]]);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login to view your vehicles")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Vehicles"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<VehicleModel>>(
        stream: _buildMergedStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final vehicles = snapshot.data ?? [];

          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.car, size: 64, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No Vehicles Yet",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Vehicles you purchase or add manually\nwill appear here in real-time.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _addExternal(context, user.uid),
                    icon: const Icon(Iconsax.add, color: Colors.white),
                    label: const Text("Add a Vehicle", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              return _buildVehicleCard(context, vehicles[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addExternal(context, user.uid),
        label: const Text("Add Vehicle", style: TextStyle(color: Colors.white)),
        icon: const Icon(Iconsax.add, color: Colors.white),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _addExternal(BuildContext context, String userId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExternalVehiclePage()),
    );
    // Stream auto-updates — no manual refresh needed
  }

  Widget _buildVehicleCard(BuildContext context, VehicleModel vehicle) {
    final isExternal = vehicle.isExternal;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VehicleDetailPage(vehicle: vehicle)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          children: [
            // ── Vehicle image
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                image: vehicle.images.isNotEmpty
                    ? DecorationImage(image: NetworkImage(vehicle.images.first), fit: BoxFit.cover)
                    : null,
                color: Colors.grey.shade800,
              ),
              child: Stack(
                children: [
                  if (vehicle.images.isEmpty)
                    const Center(child: Icon(Icons.directions_car, size: 60, color: Colors.white54)),
                  // Badge: External vs Purchased
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isExternal
                            ? Colors.blue.withValues(alpha: 0.85)
                            : Colors.green.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isExternal ? "EXTERNAL" : "OWNED",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Vehicle details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "${vehicle.year} ${vehicle.brand} ${vehicle.model}",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (vehicle.specs['licensePlate'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            vehicle.specs['licensePlate'] ?? '',
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${vehicle.fuel} • ${vehicle.transmission}",
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  // ── Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _actionButton(
                        icon: Iconsax.receipt,
                        label: "Challans",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EChallanPage(
                                filterVehicleNumber: vehicle.specs['licensePlate']),
                          ),
                        ),
                      ),
                      _actionButton(
                        icon: Iconsax.document,
                        label: "Insurance",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InsurancePage(
                              vehicleName: "${vehicle.brand} ${vehicle.model}",
                              vehicleNumber: vehicle.specs['licensePlate'] ?? "Unknown",
                              isExternal: vehicle.isExternal,
                            ),
                          ),
                        ),
                      ),
                      _actionButton(
                        icon: Iconsax.refresh,
                        label: "Transfer",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransferOwnershipPage(
                              vehicleName: "${vehicle.brand} ${vehicle.model}",
                              vehicleNumber: vehicle.specs['licensePlate'] ?? "Unknown",
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// Simple zip stream combinator (merges latest from multiple streams)
class StreamZip<T> extends Stream<List<T>> {
  final List<Stream<T>> streams;
  StreamZip(this.streams);

  @override
  StreamSubscription<List<T>> listen(
    void Function(List<T>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final latestValues = List<T?>.filled(streams.length, null);
    final hasValue = List<bool>.filled(streams.length, false);
    final subscriptions = <StreamSubscription<T>>[];
    late StreamController<List<T>> controller;

    controller = StreamController<List<T>>(
      onCancel: () {
        for (final sub in subscriptions) {
          sub.cancel();
        }
      },
    );

    for (int i = 0; i < streams.length; i++) {
      final idx = i;
      subscriptions.add(streams[idx].listen(
        (value) {
          latestValues[idx] = value;
          hasValue[idx] = true;
          if (hasValue.every((v) => v)) {
            controller.add(latestValues.cast<T>().toList());
          }
        },
        onError: controller.addError,
      ));
    }

    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
