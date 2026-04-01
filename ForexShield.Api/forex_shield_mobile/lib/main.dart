import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const ForexShieldApp());

class ForexShieldApp extends StatelessWidget {
  const ForexShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      home: const FinancialRiskDashboard(),
    );
  }
}

class FinancialRiskDashboard extends StatefulWidget {
  const FinancialRiskDashboard({super.key});

  @override
  State<FinancialRiskDashboard> createState() => _FinancialRiskDashboardState();
}

class _FinancialRiskDashboardState extends State<FinancialRiskDashboard> {
  // Config & Mock Data
  final double _orderAmountUSD = 5000.0;
  final double _budgetLimitTRY = 215000.0;
  
  double _currentRate = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshExchangeRate();
  }

  Future<void> _refreshExchangeRate() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentRate = (data['rates']['TRY'] as num).toDouble();
          _isLoading = false;
        });
      }
    } catch (err) {
      debugPrint("Fetch Error: $err");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDebtTRY = _orderAmountUSD * _currentRate;
    final isOverBudget = totalDebtTRY > _budgetLimitTRY;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Forex Risk Shield', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(onPressed: _refreshExchangeRate, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator.adaptive())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                children: [
                  _buildStatusIndicator(isOverBudget),
                  const SizedBox(height: 25),
                  _buildFinancialSummary(totalDebtTRY, isOverBudget),
                  const SizedBox(height: 20),
                  _buildDetailList(totalDebtTRY),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusIndicator(bool danger) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: danger ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: danger ? Colors.red[200]! : Colors.green[200]!),
      ),
      child: Column(
        children: [
          Icon(danger ? Icons.gpp_maybe : Icons.verified_user, 
               color: danger ? Colors.red[700] : Colors.green[700], size: 48),
          const SizedBox(height: 12),
          Text(
            danger ? "KRİTİK BÜTÇE AŞIMI" : "GÜVENLİ BÜTÇE ARALIĞI",
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: danger ? Colors.red[900] : Colors.green[900]
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(double total, bool danger) {
    return Column(
      children: [
        const Text("Güncel Borç Karşılığı", style: TextStyle(color: Colors.grey)),
        Text(
          "₺${total.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 36, 
            fontWeight: FontWeight.w900, 
            color: danger ? Colors.red[800] : Colors.indigo[900],
            letterSpacing: -1
          ),
        ),
      ],
    );
  }

  Widget _buildDetailList(double total) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _dataRow("Döviz Tutarı", "5,000.00 USD"),
          const Divider(height: 1),
          _dataRow("Canlı USD/TRY", "₺${_currentRate.toStringAsFixed(4)}"),
          const Divider(height: 1),
          _dataRow("Bütçe Limiti", "₺${_budgetLimitTRY.toStringAsFixed(2)}"),
          const Divider(height: 1),
          _dataRow(
            "Fark", 
            "₺${(total - _budgetLimitTRY).abs().toStringAsFixed(2)}",
            valueColor: total > _budgetLimitTRY ? Colors.red : Colors.green
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}