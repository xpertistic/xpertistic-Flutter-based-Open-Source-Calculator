import 'package:flutter/material.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  String _category = 'Length';
  double _inputValue = 0;
  String _fromUnit = 'Meters';
  String _toUnit = 'Kilometers';
  double _outputValue = 0;

  final Map<String, List<String>> _units = {
    'Length': ['Meters', 'Kilometers', 'Miles', 'Feet'],
    'Weight': ['Kilograms', 'Grams', 'Pounds', 'Ounces'],
    'Temperature': ['Celsius', 'Fahrenheit', 'Kelvin'],
  };

  void _convert() {
    setState(() {
      if (_category == 'Length') {
        _convertLength();
      } else if (_category == 'Weight') {
        _convertWeight();
      } else if (_category == 'Temperature') {
        _convertTemperature();
      }
    });
  }

  void _convertLength() {
    // Meters as base
    double base = 0;
    switch (_fromUnit) {
      case 'Meters': base = _inputValue; break;
      case 'Kilometers': base = _inputValue * 1000; break;
      case 'Miles': base = _inputValue * 1609.34; break;
      case 'Feet': base = _inputValue * 0.3048; break;
    }
    
    switch (_toUnit) {
      case 'Meters': _outputValue = base; break;
      case 'Kilometers': _outputValue = base / 1000; break;
      case 'Miles': _outputValue = base / 1609.34; break;
      case 'Feet': _outputValue = base / 0.3048; break;
    }
  }

  void _convertWeight() {
    // Kilograms as base
    double base = 0;
    switch (_fromUnit) {
      case 'Kilograms': base = _inputValue; break;
      case 'Grams': base = _inputValue / 1000; break;
      case 'Pounds': base = _inputValue * 0.453592; break;
      case 'Ounces': base = _inputValue * 0.0283495; break;
    }

    switch (_toUnit) {
      case 'Kilograms': _outputValue = base; break;
      case 'Grams': _outputValue = base * 1000; break;
      case 'Pounds': _outputValue = base / 0.453592; break;
      case 'Ounces': _outputValue = base / 0.0283495; break;
    }
  }

  void _convertTemperature() {
    double celsius = 0;
    if (_fromUnit == 'Celsius') celsius = _inputValue;
    else if (_fromUnit == 'Fahrenheit') celsius = (_inputValue - 32) * 5 / 9;
    else if (_fromUnit == 'Kelvin') celsius = _inputValue - 273.15;

    if (_toUnit == 'Celsius') _outputValue = celsius;
    else if (_toUnit == 'Fahrenheit') _outputValue = (celsius * 9 / 5) + 32;
    else if (_toUnit == 'Kelvin') _outputValue = celsius + 273.15;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Unit Converter')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _category,
              isExpanded: true,
              items: _units.keys.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _category = val!;
                  _fromUnit = _units[_category]![0];
                  _toUnit = _units[_category]![1];
                  _convert();
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'From ($_fromUnit)',
                border: const OutlineInputBorder(),
              ),
              onChanged: (val) {
                _inputValue = double.tryParse(val) ?? 0;
                _convert();
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _fromUnit,
                    isExpanded: true,
                    items: _units[_category]!.map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _fromUnit = val!);
                      _convert();
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.arrow_forward),
                ),
                Expanded(
                  child: DropdownButton<String>(
                    value: _toUnit,
                    isExpanded: true,
                    items: _units[_category]!.map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _toUnit = val!);
                      _convert();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('Result', style: TextStyle(color: colorScheme.onSecondaryContainer)),
                  const SizedBox(height: 10),
                  Text(
                    _outputValue.toStringAsFixed(4),
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorScheme.onSecondaryContainer),
                  ),
                  Text(_toUnit, style: TextStyle(color: colorScheme.onSecondaryContainer)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
