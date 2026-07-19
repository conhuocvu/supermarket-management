import 'package:flutter/material.dart';

import 'cashier_pos_screen.dart';

/// Opens a local POS draft. No invoice row is created until the cashier adds
/// the first product.
class NewInvoiceLauncherScreen extends StatelessWidget {
  const NewInvoiceLauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CashierPosScreen(invoiceNumber: null);
  }
}
