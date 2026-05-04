import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wine.dart';
import '../services/gemini_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final List<Wine> _wines = [];
  final TextEditingController _controller = TextEditingController();
  final GeminiService _gemini = GeminiService('YOUR_API_KEY_HERE');
  bool _isLoading = false;

  void _addWine() async {
    if (_controller.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final wine = await _gemini.processWineInput(_controller.text);
      if (wine != null) setState(() => _wines.add(wine));
    } finally {
      _controller.clear();
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Wine Manager')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Identify Wine (e.g., 2018 Opus One from USA)',
                suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: _addWine),
              ),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Title')),
                  DataColumn(label: Text('Vintage')),
                  DataColumn(label: Text('Country')),
                  DataColumn(label: Text('Price')),
                ],
                rows: _wines.map((w) => DataRow(cells: [
                  DataCell(Text(w.title)),
                  DataCell(Text(w.vintage)),
                  DataCell(Text(w.country)),
                  DataCell(Text(NumberFormat.currency(symbol: '\$').format(w.price))),
                ])).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
