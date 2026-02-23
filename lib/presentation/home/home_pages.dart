
import 'package:carvia/presentation/main_wrapper.dart';
import 'package:carvia/presentation/seller/seller_main_wrapper.dart';
import 'package:carvia/presentation/police/police_main_wrapper.dart';
import 'package:flutter/material.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainWrapper();
  }
}

class SellerHomePage extends StatelessWidget {
  const SellerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SellerMainWrapper();
  }
}



class PoliceHomePage extends StatelessWidget {
  const PoliceHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PoliceMainWrapper();
  }
}


