import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(const WineApp());
}

// ==========================================
// 1. Data Model
// ==========================================
class Wine {
  final String title;
  final String vintage;
  final String country;
  final double price;
  final String drinkingWindow;

  Wine({
    required this.title,
    required this.vintage,
    required this.country,
    required this.price,
    required this.drinkingWindow,
  });

  factory Wine.fromJson(Map<String, dynamic> json) {
    return Wine(
      title: json['title'] ?? 'Unknown',
      vintage: json['vintage']?.toString() ?? 'N/A',
      country: json['country'] ?? 'Unknown',
      price: (json['price'] ?? 0.0).toDouble(),
      drinkingWindow: json['drinkingWindow']?.toString() ?? 'N/A',
    );
  }
}

// ==========================================
// 2. Gemini AI Service
// ==========================================
class GeminiService {
  final String apiKey;
  late final GenerativeModel _model;

  GeminiService(this.apiKey) {
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<Wine?> processWineInput(String input) async {
    final prompt = '''
    Analyze this wine input: "$input". 
    Provide the details in a valid JSON format with keys: 
    "title" (string), 
    "vintage" (string), 
    "country" (string), 
    "price" (number),
    "drinkingWindow" (string, e.g., "2025-2032" or "Now").
    If a value is unknown, use "N/A" for strings and 0.0 for numbers.
    Return ONLY the JSON object.
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text != null) {
        final Map<String, dynamic> decoded = jsonDecode(_cleanJsonString(text));
        return Wine.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('Gemini API Error: \$e');
    }
    return null;
  }

  String _cleanJsonString(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1) {
      return text.substring(start, end + 1);
    }
    return text;
  }
}

// ==========================================
// 3. Application Theme & Root
// ==========================================
class WineApp extends StatelessWidget {
  const WineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Wine Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: AppBarTheme(backgroundColor: Colors.deepPurple.shade900),
      ),
      home: const InventoryScreen(),
    );
  }
}

// ==========================================
// 4. Main Inventory UI & Logic
// ==========================================
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final List<Wine> _wines = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  // IMPORTANT: Insert your Gemini API key here
  final GeminiService _gemini = GeminiService('YOUR_API_KEY_HERE');

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
      
      // Fallback: Alphabetical sort if both have same urgency
      return a.title.compareTo(b.title); 
    });
  }

  /// Removes the wine from the cooler list
  void _drinkWine(Wine wine) {
    setState(() {
      _wines.remove(wine);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('\${wine.title} removed from cooler.'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  /// Submits user text to Gemini and adds the resulting wine
  Future<void> _addWine() async {
    if (_controller.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus(); // Dismiss keyboard

    try {
      final wine = await _gemini.processWineInput(_controller.text);
      if (wine != null) {
        setState(() {
          _wines.add(wine);
          _sortWines();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not identify wine details. Please try again.')),
          );
        }
      }
    } finally {
      _controller.clear();
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wine Cooler Inventory'),
      ),
      body: Column(
        children: [
          // Input Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Identify Wine (e.g., 2018 Opus One)',
                border: const OutlineInputBorder(),
                suffixIcon: _isLoading 
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send), 
                        color: Colors.deepPurpleAccent,
                        onPressed: _addWine,
                      ),
              ),
              onSubmitted: (_) => _addWine(),
            ),
          ),
          
          // Data Table Section
          Expanded(
            child: _wines.isEmpty && !_isLoading
                ? const Center(child: Text('Your cooler is empty. Add a wine above.'))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(Colors.deepPurple.shade900.withOpacity(0.5)),
                        columns: const [
                          DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Vintage', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Country', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Window', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _wines.map((w) {
                          // Check urgency for text coloring
                          final startYear = _getStartYear(w.drinkingWindow);
                          final isUrgent = startYear != null && startYear <= DateTime.now().year + 1;

                          return DataRow(
                            cells: [
                              DataCell(Text(w.title)),
                              DataCell(Text(w.vintage)),
                              DataCell(Text(w.country)),
                              DataCell(
                                Text(
                                  w.drinkingWindow,
                                  style: TextStyle(
                                    color: isUrgent ? Colors.redAccent : Colors.white,
                                    fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
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
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
