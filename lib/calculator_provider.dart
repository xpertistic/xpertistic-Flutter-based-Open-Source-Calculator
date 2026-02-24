import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';

class CalculatorProvider with ChangeNotifier {
  String _display = '0';
  String _expression = '';
  double? _firstOperand;
  String? _operator;
  double _memory = 0;
  List<String> _history = [];
  bool _shouldResetDisplay = false;
  
  // Voice Input
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechInitialized = false;

  String get display => _display;
  String get expression => _expression;
  double get memory => _memory;
  List<String> get history => _history;
  bool get isListening => _isListening;

  void onButtonPressed(String label) {
    if (label == 'AC') {
      _display = '0';
      _expression = '';
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = false;
    } else if (label == '+/-') {
      if (_display != '0') {
        if (_display.startsWith('-')) {
          _display = _display.substring(1);
        } else {
          _display = '-$_display';
        }
      }
    } else if (label == '%') {
      double val = (double.tryParse(_display) ?? 0) / 100;
      _display = _formatResult(val);
    } else if (['+', '-', '×', '÷', '^'].contains(label)) {
      _handleOperator(label);
    } else if (['sin', 'cos', 'tan', 'log', 'ln', '√'].contains(label)) {
      _handleScientific(label);
    } else if (label == '=') {
      _calculateResult(isFinal: true);
    } else if (label == '.') {
      _handleDecimal();
    } else if (label == 'MC') {
      _memory = 0;
    } else if (label == 'M+') {
      _memory += double.tryParse(_display) ?? 0;
    } else if (label == 'M-') {
      _memory -= double.tryParse(_display) ?? 0;
    } else if (label == 'MR') {
      _display = _formatResult(_memory);
      _shouldResetDisplay = true;
    } else if (label == 'DEL') {
      deleteLast();
    } else if (label == 'π') {
      _display = _formatResult(3.141592653589793);
      _shouldResetDisplay = true;
    } else {
      _handleNumber(label);
    }
    notifyListeners();
  }

  void _handleNumber(String label) {
    if (_display == '0' || _shouldResetDisplay) {
      _display = label;
      _shouldResetDisplay = false;
    } else {
      if (_display.length < 15) {
        _display += label;
      }
    }
  }

  void _handleDecimal() {
    if (_shouldResetDisplay) {
      _display = '0.';
      _shouldResetDisplay = false;
    } else if (!_display.contains('.')) {
      _display += '.';
    }
  }

  void _handleOperator(String op) {
    if (_firstOperand == null) {
      _firstOperand = double.tryParse(_display);
      _operator = op;
      _expression = '$_display $op';
      _shouldResetDisplay = true;
    } else {
      if (!_shouldResetDisplay) {
        _calculateResult();
      }
      _operator = op;
      _expression = '$_formatResult(_firstOperand!) $op';
      _shouldResetDisplay = true;
    }
  }

  void _handleScientific(String func) {
    double val = double.tryParse(_display) ?? 0;
    String mathFunc = func;
    if (func == '√') mathFunc = 'sqrt';
    
    _expression = '$mathFunc($_display)';
    
    try {
      Parser p = Parser();
      Expression exp = p.parse('$mathFunc($val)');
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      
      _display = _formatResult(eval);
      _shouldResetDisplay = true;
    } catch (e) {
      _display = 'Error';
      _shouldResetDisplay = true;
    }
  }

  void _calculateResult({bool isFinal = false}) {
    if (_firstOperand == null || _operator == null) return;
    
    double secondOperand = double.tryParse(_display) ?? 0;
    String op = _operator!.replaceAll('×', '*').replaceAll('÷', '/');
    String evalExpr = '$_firstOperand $op $secondOperand';
    
    try {
      Parser p = Parser();
      Expression exp = p.parse(evalExpr);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      
      String res = _formatResult(eval);
      if (isFinal) {
        _history.insert(0, '$_expression $_display = $res');
        _expression = '';
        _firstOperand = null;
        _operator = null;
      } else {
        _firstOperand = eval;
        _expression = '$res $_operator';
      }
      _display = res;
      _shouldResetDisplay = true;
    } catch (e) {
      _display = 'Error';
      _shouldResetDisplay = true;
    }
  }

  void _calculate(String type) {
    double val = double.tryParse(_display) ?? 0;
    if (type == '%') {
      val = val / 100;
    }
    _display = _formatResult(val);
    notifyListeners();
  }

  String _formatResult(double result) {
    if (result.isInfinite || result.isNaN) return 'Error';
    
    final formatter = NumberFormat("###.#######", "en_US");
    String s = formatter.format(result);
    
    if (s.length > 15) {
      s = result.toStringAsExponential(5);
    }
    return s;
  }

  // Constants Library
  static const Map<String, double> constants = {
    'π (Pi)': 3.141592653589793,
    'e (Euler)': 2.718281828459,
    'c (Light)': 299792458,
    'G (Grav)': 6.674e-11,
    'g (Earth)': 9.80665,
    'φ (Golden)': 1.618033988749,
  };

  String getFraction() {
    double? val = double.tryParse(_display);
    if (val == null || val == 0 || val.isInfinite || val.isNaN) return '';
    return _toFraction(val);
  }

  String _toFraction(double value, {double tolerance = 1.0e-6}) {
    double x = value;
    double a = x.floorToDouble();
    double h1 = 1, h2 = a;
    double k1 = 0, k2 = 1;

    while ((x - a).abs() > tolerance * k2 * k2) {
      x = 1.0 / (x - a);
      a = x.floorToDouble();
      double h = a * h2 + h1;
      h1 = h2;
      h2 = h;
      double k = a * k2 + k1;
      k1 = k2;
      k2 = k;
      if (k2 > 10000) break; // Limit denominator
    }

    if (k2 == 1) return h2.toInt().toString();
    return '${h2.toInt()}/${k2.toInt()}';
  }

  void insertConstant(double value) {
    _display = _formatResult(value);
    _shouldResetDisplay = true;
    notifyListeners();
  }

  void deleteLast() {
    if (_shouldResetDisplay) {
      _display = '0';
      _shouldResetDisplay = false;
    } else if (_display.length > 1) {
      _display = _display.substring(0, _display.length - 1);
    } else {
      _display = '0';
    }
    notifyListeners();
  }

  // Voice Input Implementation
  Future<void> toggleVoice() async {
    if (!_speechInitialized) {
      _speechInitialized = await _speech.initialize(
        onError: (val) {
          print('Speech Error: $val');
          _isListening = false;
          notifyListeners();
        },
        onStatus: (val) {
          print('Speech Status: $val');
          if (val == 'done' || val == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
      );
    }

    if (_speechInitialized) {
      if (!_isListening) {
        _isListening = true;
        _speech.listen(
          onResult: (result) {
            // Only process if it's the final result to avoid double triggers
            if (result.finalResult) {
              _processVoiceCommand(result.recognizedWords);
              _isListening = false;
              notifyListeners();
            }
          },
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
        );
      } else {
        _isListening = false;
        _speech.stop();
      }
    }
    notifyListeners();
  }

  void _processVoiceCommand(String text) {
    text = text.toLowerCase().trim();
    if (text.isEmpty) return;
    print('Processing Voice Command: $text');

    // Number mapping
    final Map<String, String> numberMap = {
      'zero': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4',
      'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
      'ten': '10', 'point': '.', 'dot': '.'
    };

    // Operator mapping
    final Map<String, String> operatorMap = {
      'plus': '+', 'add': '+',
      'minus': '-', 'subtract': '-',
      'times': '×', 'multiply': '×', 'multiplied': '×',
      'divide': '÷', 'divided': '÷',
      'equals': '=', 'calc': '=', 'calculate': '=',
      'clear': 'AC', 'reset': 'AC',
      'sin': 'sin', 'sine': 'sin',
      'cos': 'cos', 'cosine': 'cos',
      'tan': 'tan', 'tangent': 'tan',
      'root': '√', 'square root': '√',
      'power': '^', 'exponent': '^'
    };

    // Handle common phrases like "add two and two" or "two plus two"
    // We'll normalize the text by replacing words with their tokens
    String normalized = text;
    
    // Replace multi-word operators first
    operatorMap.forEach((key, value) {
      if (key.contains(' ')) {
        normalized = normalized.replaceAll(key, ' $value ');
      }
    });

    // Replace single word operators and numbers
    List<String> rawWords = normalized.split(RegExp(r'\s+'));
    List<String> tokens = [];

    for (String word in rawWords) {
      if (operatorMap.containsKey(word)) {
        tokens.add(operatorMap[word]!);
      } else if (numberMap.containsKey(word)) {
        tokens.add(numberMap[word]!);
      } else if (RegExp(r'^\d+$').hasMatch(word)) {
        tokens.add(word);
      } else if (word == 'and') {
        // 'and' is often a filler or means 'plus'
        // For "add 2 and 2", it's a filler. For "2 and 2", it might be plus.
        // We'll skip it and let the operator at the start handle logic if found
      }
    }

    // Process tokens
    if (tokens.contains('+') && tokens.indexOf('+') == 0 && tokens.length >= 3) {
      // Pattern: "add X and Y" -> tokens ["+", "X", "Y"]
      onButtonPressed('AC'); 
      onButtonPressed(tokens[1]);
      onButtonPressed('+');
      onButtonPressed(tokens[2]);
      onButtonPressed('=');
    } else {
      // Generic token-by-token processing
      for (String token in tokens) {
        // If token is a number like "10", we need to press "1" then "0"
        if (RegExp(r'^\d+$').hasMatch(token) && token.length > 1) {
          for (int i = 0; i < token.length; i++) {
            onButtonPressed(token[i]);
          }
        } else {
          onButtonPressed(token);
        }
      }
    }
    
    // Auto-calculate if not already triggered and we have enough info
    if (tokens.isNotEmpty && !tokens.contains('=') && !tokens.contains('AC')) {
      // Optional: Auto-equals? Maybe safer to wait for user to say "equals"
    }
  }
}
