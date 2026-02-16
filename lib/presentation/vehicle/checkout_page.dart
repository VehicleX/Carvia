import 'package:carvia/core/models/order_model.dart';
import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/order_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class CheckoutPage extends StatefulWidget {
  final VehicleModel vehicle;

  const CheckoutPage({super.key, required this.vehicle});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _addressController = TextEditingController(text: "123 Main St, Springfield");
  String _selectedPayment = "Credit Card";
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVehicleSummary(),
            const SizedBox(height: 24),
            const Text("Delivery Address", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.location),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            const Text("Payment Method", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPaymentOption("Credit Card", Icons.credit_card),
            _buildPaymentOption("UPI / Netbanking", Icons.account_balance_wallet),
            const SizedBox(height: 30),
            _buildPriceBreakdown(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _processOrder,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primary,
          ),
          child: _isProcessing 
            ? const CircularProgressIndicator(color: Colors.white) 
            : Text("PAY \$${widget.vehicle.price.toStringAsFixed(0)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildVehicleSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.vehicle.images.isNotEmpty ? widget.vehicle.images.first : "",
              width: 100,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_,__,___) => Container(width: 100, height: 70, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.vehicle.brand} ${widget.vehicle.model}",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(widget.vehicle.year.toString(), style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(
            "\$${widget.vehicle.price.toStringAsFixed(0)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String label, IconData icon) {
    return RadioListTile<String>(
      value: label,
      groupValue: _selectedPayment,
      onChanged: (val) => setState(() => _selectedPayment = val!),
      title: Text(label),
      secondary: Icon(icon, color: AppColors.primary),
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildPriceBreakdown() {
    final price = widget.vehicle.price;
    final tax = price * 0.05;
    final total = price + tax + 500; // 500 delivery fee

    return Column(
      children: [
        _row("Vehicle Price", "\$${price.toStringAsFixed(0)}"),
        _row("Taxes (5%)", "\$${tax.toStringAsFixed(0)}"),
        _row("Delivery Fee", "\$500"),
        const Divider(height: 24),
        _row("Total Amount", "\$${total.toStringAsFixed(0)}", isBold: true),
      ],
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? null : AppColors.textMuted)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Future<void> _processOrder() async {
    setState(() => _isProcessing = true);
    
    // Simulate payment delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final orderService = Provider.of<OrderService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not logged in!")));
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final order = OrderModel(
        id: "", // Generated
        userId: user.uid,
        vehicleId: widget.vehicle.id,
        vehicleName: "${widget.vehicle.brand} ${widget.vehicle.model} ${widget.vehicle.year}",
        amount: widget.vehicle.price + (widget.vehicle.price * 0.05) + 500,
        date: DateTime.now(),
        status: OrderStatus.confirmed, // Auto-confirm for demo
        paymentMethod: _selectedPayment,
      );

      await orderService.createOrder(order);

      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 16),
              Text("Order Placed!"),
            ],
          ),
          content: const Text("Your order has been confirmed. You can track it in the Orders section."),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog
                Navigator.of(context).pop(); // Checkout Page
                Navigator.of(context).pop(); // Detail Page (Back to Home)
              },
              child: const Text("Back to Home"),
            ),
          ],
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
