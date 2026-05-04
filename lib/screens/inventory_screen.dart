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
  final GeminiService _gemini = GeminiService('YOUR_API_KEY_HERE'); // Replace with your key
  bool _isLoading = false;

  // --- Core Logic Features ---

  /// Extracts the starting year from the drinking window text
  int? _getStartYear(String window) {
    if (window.toLowerCase().contains('now')) return DateTime.now().year;
    final match = RegExp(r'(\d{4})').firstMatch(window);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  /// Sorts the list so wines nearing their window (this year or next) are at the top
  void _sortWines() {
    final currentYear = DateTime.now().year;

    _wines.sort((a, b) {
      final yearA = _getStartYear(a.drinkingWindow);
      final yearB = _getStartYear(b.drinkingWindow);

      bool isUrgentA = yearA != null && (yearA <= currentYear + 1);
      bool isUrgentB = yearB != null && (yearB <= currentYear + 1);

      if (isUrgentA && !isUrgentB) return -1;
      if (!isUrgentA && isUrgentB) return 1;
      return a.title.compareTo(b.title); // Alphabetical fallback
    });
  }

  /// Removes the wine from the cooler list
  void _drinkWine(Wine wine) {
    setState(() {
      _wines.remove(wine);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${wine.title} removed from cooler.')),
    );
  }

  void _addWine() async {
    if (_controller.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final wine = await _gemini.processWineInput(_controller.text);
      if (wine != null) {
        setState(() {
          _wines.add(wine);
          _sortWines(); // Apply sorting immediately after adding
        });
      }
    } finally {
      _controller.clear();
      setState(() => _isLoading = false);
    }
  }

  // --- UI ---

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
                labelText: 'Identify Wine (e.g., 2018 Opus One)',
                suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: _addWine),
              ),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Title')),
                    DataColumn(label: Text('Vintage')),
                    DataColumn(label: Text('Country')),
                    DataColumn(label: Text('Window')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: _wines.map((w) => DataRow(cells: [
                    DataCell(Text(w.title)),
                    DataCell(Text(w.vintage)),
                    DataCell(Text(w.country)),
                    DataCell(
                      Text(
                        w.drinkingWindow,
                        style: TextStyle(
                          color: _getStartYear(w.drinkingWindow) != null && _getStartYear(w.drinkingWindow)! <= DateTime.now().year + 1 
                            ? Colors.red 
                            : null,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ),
                    DataCell(Text(NumberFormat.currency(symbol: '\$').format(w.price))),
                    DataCell(
                      ElevatedButton.icon(
                        icon: const Icon(Icons.local_drink, size: 16),
                        label: const Text('Drink'),
                        onPressed: () => _drinkWine(w),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ])).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
