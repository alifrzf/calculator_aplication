import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalkulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({Key? key}) : super(key: key);

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // Menggunakan TextEditingController untuk mengontrol teks pada TextField.
  final TextEditingController _controller = TextEditingController(text: "0");

  // Fungsi untuk mengevaluasi ekspresi matematika secara keseluruhan
  // menggunakan algoritma shunting-yard dan evaluasi postfix.
  void _evaluateExpression() {
    // Gantikan 'x' dengan '*' jika ada (misalnya jika pengguna menggunakan tombol UI)
    String expression = _controller.text.replaceAll("x", "*");

    // Hilangkan spasi agar validasi lebih mudah.
    expression = expression.replaceAll(" ", "");

    // Cek apakah input hanya terdiri dari angka, titik, dan operator (+, -, *, /).
    if (!RegExp(r'^[0-9\.\+\-\*\/]+$').hasMatch(expression)) {
      // Tampilkan pesan error dan langsung hapus isi TextField.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Input tidak valid. Masukkan hanya angka dan operator."),
          duration: Duration(seconds: 2),
        ),
      );
      _controller.clear();
      return;
    }

    try {
      double result = _calculate(expression);
      // Tampilkan hasil perhitungan di dalam TextField.
      _controller.text =
          result % 1 == 0 ? result.toInt().toString() : result.toString();
    } catch (e) {
      // Jika error karena pembagian dengan nol, tampilkan pesan error menggunakan SnackBar.
      if (e.toString().contains("Division by zero")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pembagian dengan 0 tidak diizinkan!"),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ekspresi tidak valid!"),
            duration: Duration(seconds: 2),
          ),
        );
      }
      // Jangan mengganti teks di TextField dengan pesan error, cukup kosongkan.
      _controller.clear();
    }
  }

  // Fungsi untuk mengevaluasi ekspresi matematika menggunakan algoritma shunting-yard
  // dan evaluasi RPN (Reverse Polish Notation).
  double _calculate(String expression) {
    // Tokenisasi: memisahkan angka dan operator.
    List<String> tokens = [];
    String numberBuffer = "";
    for (int i = 0; i < expression.length; i++) {
      String ch = expression[i];
      if (_isDigit(ch) || ch == ".") {
        numberBuffer += ch;
      } else if (_isOperator(ch)) {
        if (numberBuffer.isNotEmpty) {
          tokens.add(numberBuffer);
          numberBuffer = "";
        }
        tokens.add(ch);
      }
    }
    if (numberBuffer.isNotEmpty) {
      tokens.add(numberBuffer);
    }

    // Konversi ke notasi postfix (RPN) menggunakan algoritma shunting-yard.
    List<String> outputQueue = [];
    List<String> operatorStack = [];
    Map<String, int> precedence = {
      "+": 1,
      "-": 1,
      "*": 2,
      "/": 2,
    };

    for (String token in tokens) {
      if (_isOperator(token)) {
        while (operatorStack.isNotEmpty &&
            precedence[operatorStack.last]! >= precedence[token]!) {
          outputQueue.add(operatorStack.removeLast());
        }
        operatorStack.add(token);
      } else {
        outputQueue.add(token);
      }
    }
    while (operatorStack.isNotEmpty) {
      outputQueue.add(operatorStack.removeLast());
    }

    // Evaluasi ekspresi postfix.
    List<double> evalStack = [];
    for (String token in outputQueue) {
      if (_isOperator(token)) {
        if (evalStack.length < 2) {
          throw Exception("Invalid expression");
        }
        double b = evalStack.removeLast();
        double a = evalStack.removeLast();
        double res = 0;
        switch (token) {
          case "+":
            res = a + b;
            break;
          case "-":
            res = a - b;
            break;
          case "*":
            res = a * b;
            break;
          case "/":
            if (b == 0) throw Exception("Division by zero");
            res = a / b;
            break;
        }
        evalStack.add(res);
      } else {
        evalStack.add(double.parse(token));
      }
    }
    if (evalStack.length != 1) {
      throw Exception("Invalid expression");
    }
    return evalStack.first;
  }

  // Helper: cek apakah karakter merupakan digit (0-9).
  bool _isDigit(String ch) {
    return "0123456789".contains(ch);
  }

  // Helper: cek apakah string merupakan operator.
  bool _isOperator(String ch) {
    return ch == "+" || ch == "-" || ch == "*" || ch == "/" || ch == "x";
  }

  // Fungsi untuk meng-handle penekanan tombol (baik dari tombol UI maupun input keyboard).
  void _buttonPressed(String buttonText) {
    String currentText = _controller.text;
    setState(() {
      if (buttonText == "CLEAR") {
        _controller.text = "0";
      } else if (buttonText == "=") {
        _evaluateExpression();
      }
      // Jika tombol yang ditekan adalah operator.
      else if (buttonText == "+" ||
          buttonText == "-" ||
          buttonText == "x" ||
          buttonText == "/") {
        if (currentText == "0" || currentText.isEmpty) {
          return;
        }
        if (currentText.endsWith("+") ||
            currentText.endsWith("-") ||
            currentText.endsWith("x") ||
            currentText.endsWith("/")) {
          _controller.text =
              currentText.substring(0, currentText.length - 1) + buttonText;
        } else {
          _controller.text += buttonText;
        }
      }
      // Jika tombol yang ditekan adalah angka atau titik desimal.
      else {
        if (currentText == "0" && buttonText != ".") {
          _controller.text = buttonText;
        } else {
          List<String> parts =
              currentText.split(RegExp(r'[\+\-\*x\/]')); // perhatikan operator *
          String currentNumber = parts.last;
          if (buttonText == "." && currentNumber.contains(".")) {
            return;
          }
          _controller.text += buttonText;
        }
      }
    });
  }

  // Fungsi untuk membangun tombol kalkulator.
  Widget _buildButton(String buttonText, {Color? color}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(24.0),
            backgroundColor: color ?? Colors.blueGrey[50],
          ),
          onPressed: () => _buttonPressed(buttonText),
          child: Text(
            buttonText,
            style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Fungsi untuk menampilkan dialog informasi tentang pembuat aplikasi.
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Tentang Aplikasi"),
          content: const Text("Kalkulator ini dibuat oleh Alif razan setiawan/XI RPL 1/003."),
          actions: <Widget>[
            TextButton(
              child: const Text("Tutup"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: <Widget>[
              // Menampilkan TextField agar pengguna dapat mengetik ekspresi secara manual.
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(fontSize: 32.0),
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Masukkan angka",
                  ),
                  keyboardType: TextInputType.text,
                  onSubmitted: (value) {
                    _evaluateExpression();
                  },
                ),
              ),
              // Grid tombol kalkulator.
              Expanded(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _buildButton("7"),
                        _buildButton("8"),
                        _buildButton("9"),
                        _buildButton("/", color: Colors.orangeAccent),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        _buildButton("4"),
                        _buildButton("5"),
                        _buildButton("6"),
                        _buildButton("x", color: Colors.orangeAccent),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        _buildButton("1"),
                        _buildButton("2"),
                        _buildButton("3"),
                        _buildButton("-", color: Colors.orangeAccent),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        _buildButton("."),
                        _buildButton("0"),
                        _buildButton("00"),
                        _buildButton("+", color: Colors.orangeAccent),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        _buildButton("CLEAR", color: Colors.redAccent),
                        _buildButton("=", color: Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // FloatingActionButton berada di kanan bawah untuk menampilkan informasi pembuat.
      floatingActionButton: FloatingActionButton(
        onPressed: _showAboutDialog,
        child: const Icon(Icons.info),
      ),
    );
  }
}
