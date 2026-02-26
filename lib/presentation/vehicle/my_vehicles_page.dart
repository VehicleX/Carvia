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
        title: Text("My Vehicles"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<VehicleModel>>(
        stream: _buildMergedStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
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
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Iconsax.car, size: 64, color: Theme.of(context).colorScheme.primary),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "No Vehicles Yet",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Vehicles you purchase or add manually\nwill appear here in real-time.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _addExternal(context, user.uid),
                    icon: Icon(Iconsax.add, color: Theme.of(context).colorScheme.onSurface),
                    label: Text("Add a Vehicle", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              return _buildVehicleCard(context, vehicles[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addExternal(context, user.uid),
        label: Text("Add Vehicle", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        icon: Icon(Iconsax.add, color: Theme.of(context).colorScheme.onSurface),
        backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
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
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05), blurRadius: 12, offset: Offset(0, 5))
          ],
        ),
        child: Column(
          children: [
            // ── Vehicle image
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                image: vehicle.images.isNotEmpty
                    ? DecorationImage(image: NetworkImage(vehicle.images.first), fit: BoxFit.cover)
                    : null,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              ),
              child: Stack(
                children: [
                  if (vehicle.images.isEmpty)
                    Center(child: Icon(Icons.directions_car, size: 60, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.54))),
                  // Badge: External vs Purchased
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isExternal
                            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85)
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isExternal ? "EXTERNAL" : "OWNED",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Vehicle details
            Padding(
              padding: EdgeInsets.all(16),
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
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            vehicle.specs['licensePlate'] ?? '',
                            style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    "${vehicle.fuel} • ${vehicle.transmission}",
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12),
                  ),
                  SizedBox(height: 12),
                  Divider(height: 1),
                  SizedBox(height: 10),
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
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.secondary)),
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
