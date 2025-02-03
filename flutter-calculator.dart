import 'dart:math' as math; // <-- Important: for math.pow()
import 'package:flutter/material.dart';
import 'package:expressions/expressions.dart';

void main() {
  runApp(const MyCalculatorApp());
}

class MyCalculatorApp extends StatelessWidget {
  const MyCalculatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator by [Your Name]',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: const CalculatorScreen(title: 'Calculator by [Your Name]'),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  final String title;
  const CalculatorScreen({Key? key, required this.title}) : super(key: key);

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  /// The text string showing the user's input (numbers/operators).
  String _expression = '';
  /// The evaluated result, shown after pressing '='.
  String _result = '';

  /// Generic handler for digits, operators (except 'C', '=', and 'x²').
  void _onButtonClick(String value) {
    setState(() {
      // If the previous calculation ended with '=', start fresh if user types again
      if (_result.isNotEmpty && _expression.contains('=')) {
        _expression = '';
        _result = '';
      }
      _expression += value;
    });
  }

  /// Clears the current expression and result
  void _clear() {
    setState(() {
      _expression = '';
      _result = '';
    });
  }

  /// This method squares the *last numeric token* by wrapping it in `pow(<token>,2)`.
  /// Example: if _expression = "3+5", pressing x² -> "3+pow(5,2)"
  void _applySquare() {
    setState(() {
      // If we just finished a calculation with '=', reset for a new one
      if (_result.isNotEmpty && _expression.contains('=')) {
        _expression = '';
        _result = '';
      }

      // Find the last numeric token. We move left until we hit an operator or start.
      int i = _expression.length - 1;
      while (i >= 0 && !'+-*/%('.contains(_expression[i])) {
        i--;
      }

      // The token after i is the last numeric chunk. For instance, "3+5" -> i=1 ('+'), token is substring(2) = "5"
      final lastToken = _expression.substring(i + 1).trim();

      // If there's no valid token, do nothing
      if (lastToken.isEmpty) return;

      // Build a new expression: everything up to i, plus pow(<lastToken>,2)
      final before = _expression.substring(0, i + 1);
      final newToken = 'pow($lastToken,2)';
      _expression = before + newToken;
    });
  }

  /// Evaluates the current expression string using the expressions package
  /// with a custom context that includes the `pow` function.
  void _calculateResult() {
    try {
      // Remove trailing operator if present (+, -, *, /, %, etc.), as it can't be evaluated
      String safeExpression = _expression;
      if (safeExpression.isNotEmpty) {
        final lastChar = safeExpression[safeExpression.length - 1];
        if ('+-*/%^('.contains(lastChar)) {
          safeExpression = safeExpression.substring(0, safeExpression.length - 1);
        }
      }

      // Parse the expression
      final exp = Expression.parse(safeExpression);

      // Provide 'pow' in the context, so expressions can interpret pow(x,2)
      final context = <String, dynamic>{
        'pow': (num base, num exponent) => math.pow(base, exponent),
      };

      // Evaluate using the custom context
      final evaluator = const ExpressionEvaluator();
      final evalResult = evaluator.eval(exp, context);

      setState(() {
        _expression += '=';
        if (evalResult is double) {
          String strResult = evalResult.toString();
          // If it's something like 4.0, trim the trailing .0
          if (strResult.endsWith('.0')) {
            strResult = strResult.substring(0, strResult.length - 2);
          }
          _result = strResult;
        } else {
          _result = evalResult.toString();
        }
      });
    } catch (e) {
      // Catch any errors (like division by zero, parse error, etc.)
      setState(() {
        _expression += '=';
        _result = 'Error';
      });
    }
  }

  /// Helper to build each calculator button
  Widget _buildButton(String text, {Color? color, double textSize = 20}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4.0),
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.grey[200],
          ),
          onPressed: () {
            switch (text) {
              case 'C':
                _clear();
                break;
              case '=':
                _calculateResult();
                break;
              case 'x²':
                _applySquare();
                break;
              default:
                _onButtonClick(text);
            }
          },
          child: Text(
            text,
            style: TextStyle(fontSize: textSize, color: Colors.black87),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Combine the expression and result into one line, e.g.: "3+5= 8"
    String displayText = _expression;
    if (_result.isNotEmpty) {
      displayText += ' $_result';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Column(
          children: [
            // Display area
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: SingleChildScrollView(
                  reverse: true,
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    displayText,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Colors.grey),

            // Calculator keypad
            Column(
              children: [
                Row(
                  children: [
                    _buildButton('7'),
                    _buildButton('8'),
                    _buildButton('9'),
                    _buildButton('/', color: Colors.orange),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('4'),
                    _buildButton('5'),
                    _buildButton('6'),
                    _buildButton('*', color: Colors.orange),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('1'),
                    _buildButton('2'),
                    _buildButton('3'),
                    _buildButton('-', color: Colors.orange),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('0'),
                    _buildButton('.'),
                    _buildButton('C', color: Colors.red),
                    _buildButton('+', color: Colors.orange),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('x²', color: Colors.orange),
                    _buildButton('%', color: Colors.orange),
                    _buildButton('=', color: Colors.blue, textSize: 24),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
