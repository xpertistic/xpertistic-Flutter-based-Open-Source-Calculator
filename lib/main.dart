import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'calculator_provider.dart';
import 'unit_converter.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CalculatorProvider(),
      child: const CalculatorApp(),
    ),
  );
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  int _colorIndex = 0;
  final List<Color> _seedColors = [
    const Color(0xFF6750A4), // Deep Purple
    Colors.teal,
    Colors.blue,
    Colors.orange,
    Colors.pink,
  ];

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void _cycleAppearance() {
    setState(() {
      _colorIndex = (_colorIndex + 1) % _seedColors.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CalX',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColors[_colorIndex], brightness: Brightness.light),
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColors[_colorIndex], brightness: Brightness.dark),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: CalculatorHomePage(
        onToggleTheme: _toggleTheme,
        themeMode: _themeMode,
        onCycleAppearance: _cycleAppearance,
      ),
    );
  }
}

class CalculatorHomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  final VoidCallback onCycleAppearance;
  
  const CalculatorHomePage({
    super.key, 
    required this.onToggleTheme, 
    required this.themeMode,
    required this.onCycleAppearance,
  });

  @override
  State<CalculatorHomePage> createState() => _CalculatorHomePageState();
}

class _CalculatorHomePageState extends State<CalculatorHomePage> {
  bool _isScientific = false;
  bool _useGlassmorphism = true;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalculatorProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(widget.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: Icon(_isScientific ? Icons.calculate : Icons.science),
            onPressed: () => setState(() => _isScientific = !_isScientific),
            tooltip: 'Toggle Scientific Mode',
          ),
          IconButton(
            icon: Icon(provider.isListening ? Icons.mic : Icons.mic_none),
            onPressed: () => provider.toggleVoice(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildMainDrawer(context, provider),
      body: Stack(
        children: [
          // Background Gradient for Glassmorphism
          if (_useGlassmorphism)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withOpacity(0.05),
                      colorScheme.secondary.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildDisplay(context, provider, colorScheme),
                ),
                Expanded(
                  flex: 7,
                  child: _buildKeypad(context, provider, colorScheme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplay(BuildContext context, CalculatorProvider provider, ColorScheme colorScheme) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 100) {
          provider.onButtonPressed('DEL');
          HapticFeedback.lightImpact();
        }
      },
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: provider.display));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard')),
        );
      },
      child: Container(
        alignment: Alignment.bottomRight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              provider.expression,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              provider.display,
              style: GoogleFonts.outfit(
                fontSize: _isScientific ? 60 : 80,
                fontWeight: FontWeight.w300,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (provider.getFraction().isNotEmpty && provider.getFraction() != provider.display)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '≈ ${provider.getFraction()}',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(BuildContext context, CalculatorProvider provider, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (_isScientific) ...[
            _buildGlassPanel([
              _buildButtonRow(context, ['sin', 'cos', 'tan', 'log']),
              const SizedBox(height: 12),
              _buildButtonRow(context, ['ln', '√', '^', 'π']),
            ]),
            const SizedBox(height: 12),
          ],
          _buildButtonRow(context, ['AC', '+/-', 'MC', '÷']),
          const SizedBox(height: 12),
          _buildButtonRow(context, ['7', '8', '9', '×']),
          const SizedBox(height: 12),
          _buildButtonRow(context, ['4', '5', '6', '-']),
          const SizedBox(height: 12),
          _buildButtonRow(context, ['1', '2', '3', '+']),
          const SizedBox(height: 12),
          _buildSpecialBottomRow(context, provider),
        ],
      ),
    );
  }

  Widget _buildGlassPanel(List<Widget> children) {
    if (!_useGlassmorphism) return Column(children: children);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildButtonRow(BuildContext context, List<String> labels) {
    return Expanded(
      child: Row(
        children: labels.map((label) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildButton(context, label),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSpecialBottomRow(BuildContext context, CalculatorProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildButton(context, '0'),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildButton(context, '.'),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildButton(context, 'DEL', color: colorScheme.errorContainer, textCol: colorScheme.onErrorContainer),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildButton(context, '=', color: colorScheme.secondary, textCol: colorScheme.onSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label, {Color? color, Color? textCol}) {
    final provider = Provider.of<CalculatorProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;
    
    Color bgColor = color ?? colorScheme.surfaceContainerHighest;
    Color textColor = textCol ?? colorScheme.onSurfaceVariant;

    if (['AC', '+/-', 'MC'].contains(label)) {
      bgColor = colorScheme.tertiaryContainer;
      textColor = colorScheme.onTertiaryContainer;
    } else if (['÷', '×', '-', '+', '=', 'sin', 'cos', 'tan', 'log', 'ln', '√', '^', 'π'].contains(label)) {
      bgColor = color ?? colorScheme.primary;
      textColor = textCol ?? colorScheme.onPrimary;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(50),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          provider.onButtonPressed(label);
        },
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: label.length > 2 ? 14 : 24,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainDrawer(BuildContext context, CalculatorProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            accountName: const Text('CalX', style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: const Text('Scientific & Converters'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: colorScheme.onPrimary,
              child: Icon(Icons.calculate, color: colorScheme.primary, size: 40),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Unit Converter'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UnitConverterScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Appearance'),
            onTap: () {
              widget.onCycleAppearance();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.functions),
            title: const Text('Constants'),
            onTap: () {
              Navigator.pop(context);
              _showConstantsLibrary(context, provider);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: provider.history.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  title: Text(provider.history[index]),
                  onTap: () => Navigator.pop(context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showConstantsLibrary(BuildContext context, CalculatorProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Constants', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: CalculatorProvider.constants.entries.map((entry) {
                    return ListTile(
                      title: Text(entry.key),
                      trailing: Text(entry.value.toStringAsPrecision(4)),
                      onTap: () {
                        provider.insertConstant(entry.value);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
