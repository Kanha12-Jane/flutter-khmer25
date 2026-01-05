import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:project_flutter_khmer25/screens/cart_screen.dart';
import 'package:url_launcher/url_launcher.dart';


class PaymentFlowScreen extends StatelessWidget {
  final int orderId;
  final String orderCode;
  final num total;
  final String payUrl;

  const PaymentFlowScreen({
    super.key,
    required this.orderId,
    required this.orderCode,
    required this.total,
    required this.payUrl,
  });

  Future<void> _openPayway(BuildContext context) async {
    if (kIsWeb) {
      final ok = await launchUrl(
        Uri.parse(payUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("បើកទំព័រទូទាត់មិនបាន 😅")),
        );
      }
      return;
    }

    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PayWayCheckoutPage(payUrl: payUrl, title: "ABA KHQR"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalText = total.toString().replaceAll(".00", "");

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: const Text("ទូទាត់ប្រាក់"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _StepCard(
            title: "Order របស់អ្នក",
            subtitle: "សូមពិនិត្យព័ត៌មានមុនទូទាត់",
            icon: Icons.receipt_long,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: "Order Code", value: orderCode),
                const SizedBox(height: 6),
                _InfoRow(label: "Amount", value: "$totalText៛"),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StepCard(
            title: "ជំហានទី 1: បើក ABA KHQR",
            subtitle: kIsWeb
                ? "វានឹងបើកនៅ Tab ថ្មី (Browser)"
                : "វានឹងបើកក្នុង App (WebView)",
            icon: Icons.qr_code_2,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openPayway(context),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text(
                      "បើក ABA KHQR",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    kIsWeb
                        ? "✅ បើក QR នៅ Tab ថ្មី → បង់ប្រាក់ → ត្រឡប់មក Tab នេះ → ចុច Upload ខាងក្រោម"
                        : "✅ បង់ប្រាក់រួច សូមត្រឡប់មកវិញ ហើយចុច Upload ខាងក្រោម",
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StepCard(
            title: "ជំហានទី 2: Upload Screenshot",
            subtitle: "បន្ទាប់ពីបង់រួច សូមផ្ញើភស្តុតាងទៅ Admin",
            icon: Icons.cloud_upload_outlined,
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final uploaded = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UploadPaymentScreen(
                        orderId: orderId,
                        orderCode: orderCode,
                        total: total,
                      ),
                    ),
                  );

                  if (context.mounted) {
                    Navigator.pop(context, uploaded == true);
                  }
                },
                icon: const Icon(Icons.upload),
                label: const Text(
                  "Upload Proof",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.10),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}
