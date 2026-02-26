import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/models/test_drive_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/core/widgets/vehicle_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BookTestDrivePage extends StatefulWidget {
  final VehicleModel vehicle;
  const BookTestDrivePage({super.key, required this.vehicle});

  @override
  State<BookTestDrivePage> createState() => _BookTestDrivePageState();
}

class _BookTestDrivePageState extends State<BookTestDrivePage> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  late TextEditingController _locationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    String defaultLocation = widget.vehicle.location;
    if (user != null && user.address.containsKey('street') && user.address['street'] != null) {
      defaultLocation = "${user.address['street']}, ${user.address['city'] ?? ''}";
    }
    _locationController = TextEditingController(text: defaultLocation.isNotEmpty ? defaultLocation : "Seller's Location");
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Book Test Drive", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVehicleSummary(),
            SizedBox(height: 30),
            Text("Select Date & Time", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            _buildDatePicker(),
            SizedBox(height: 16),
            _buildTimePicker(),
            SizedBox(height: 30),
            Text("Meeting Location", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.location),
                border: OutlineInputBorder(),
                hintText: "Enter a location for the test drive",
              ),
              maxLines: 2,
            ),
            SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)) 
                    : Text("Confirm Booking", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSummary() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.vehicle.images.isNotEmpty
                ? VehicleImage(src: widget.vehicle.images.first, width: 80, height: 80)
                : Container(width: 80, height: 80, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${widget.vehicle.brand} ${widget.vehicle.model}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text(widget.vehicle.year.toString(), style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                SizedBox(height: 8),
                Text("\$${widget.vehicle.price.toStringAsFixed(0)}", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Iconsax.calendar, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Date", style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
                Text(DateFormat('EEE, MMM d, y').format(_selectedDate), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.secondary),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(context: context, initialTime: _selectedTime);
        if (time != null) setState(() => _selectedTime = time);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Iconsax.clock, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Time", style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
                Text(_selectedTime.format(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.secondary),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBooking() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please login to book a test drive")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final booking = TestDriveModel(
        id: '', // Generated by Firestore
        userId: user.uid,
        sellerId: widget.vehicle.sellerId,
        buyerName: user.name,
        buyerPhone: user.phone,
        vehicleId: widget.vehicle.id,
        vehicleName: "${widget.vehicle.brand} ${widget.vehicle.model}",
        vehicleImage: widget.vehicle.images.firstOrNull ?? '',
        scheduledTime: scheduledDateTime,
        status: 'pending',
        createdAt: DateTime.now(),
        sellerLocation: widget.vehicle.location,
        meetingLocation: _locationController.text.trim(),
      );

      await Provider.of<VehicleService>(context, listen: false).bookTestDrive(booking);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Test drive booked successfully!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Booking failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
