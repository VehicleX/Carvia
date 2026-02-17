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
    double total = price + tax + 500; // 500 delivery fee
    
    if (_useCredits) {
      // Logic: 100 Credits = $10 discount (Example)
      // Cap discount at 10% of total or total credits value
      int availableCredits = Provider.of<AuthService>(context, listen: false).currentUser?.credits ?? 0;
      // In real app: final availableCredits = Provider.of<AuthService>(context).currentUser?.credits ?? 0;
      
      double discount = (availableCredits / 10).clamp(0, total * 0.1); 
      total -= discount;
    }

    return Column(
      children: [
        _row("Vehicle Price", "\$${price.toStringAsFixed(0)}"),
        _row("Taxes (5%)", "\$${tax.toStringAsFixed(0)}"),
        _row("Delivery Fee", "\$500"),
        
        // Credit Toggle
        SwitchListTile(
          title: const Text("Use Canvas Credits", style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text("Redeem 10% max discount"),
          value: _useCredits,
          onChanged: (val) => setState(() => _useCredits = val),
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        ),
        
        if (_useCredits)
           _row("Credits Discount", "-\$${(500/10).toStringAsFixed(0)}", color: Colors.green), // Mock calc

        const Divider(height: 24),
        _row("Total Amount", "\$${total.toStringAsFixed(0)}", isBold: true),
        
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const Icon(Iconsax.coin, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text("You will earn ${(price * 0.01).toInt()} Credits!", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? (isBold ? null : AppColors.textMuted))),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
  
  bool _useCredits = false;

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
       // Calculation Logic
      final double price = widget.vehicle.price;
      final double tax = price * 0.05;
      final double delivery = 500;
      double total = price + tax + delivery;
      
      int creditsToUse = 0;
      if (_useCredits) {
         int availableCredits = user.credits;
         // Discount logic: 10 credits = $1 discount
         double maxDiscount = total * 0.1; // Cap at 10%
         double potentialDiscount = availableCredits / 10;
         
         double actualDiscount = potentialDiscount < maxDiscount ? potentialDiscount : maxDiscount;
         
         creditsToUse = (actualDiscount * 10).toInt(); // Convert back to credits
         total -= actualDiscount;
      }
      
      final int earnedCredits = (price * 0.01).toInt();

      final order = OrderModel(
        id: "", // Generated
        userId: user.uid,
        vehicleId: widget.vehicle.id,
        vehicleName: "${widget.vehicle.brand} ${widget.vehicle.model} ${widget.vehicle.year}",
        amount: total, 
        date: DateTime.now(),
        status: OrderStatus.confirmed, 
        paymentMethod: _selectedPayment,
        creditsUsed: creditsToUse,
        creditsEarned: earnedCredits,
      );

      await orderService.createOrder(order); // Transaction automatically handles deduction/earning

      if (!mounted) return;
      
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
          content: Text("Your order has been confirmed. You earned $earnedCredits Credits!"),
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
