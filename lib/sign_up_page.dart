import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';


class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  Future<String> _getLocalFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/Users.txt';
  }

  void _signUp() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final age = _ageController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final email = _emailController.text.trim();

    if ([firstName, lastName, age, username, password, email].any((e) => e.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields."), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final path = await _getLocalFilePath();
      final file = File(path);

      if (!await file.exists()) {
        await file.create(recursive: true);
        await file.writeAsString('FirstName,LastName,Age,username,password,email\n');
      }

      final existing = await file.readAsLines();
      final duplicate = existing.any((line) => line.split(',')[3] == username);
      if (duplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Username already exists."), backgroundColor: Colors.red),
        );
        return;
      }

      final newEntry = '$firstName,$lastName,$age,$username,$password,$email\n';
      await file.writeAsString(newEntry, mode: FileMode.append);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!"), backgroundColor: Colors.green),
      );

      Navigator.pop(context); // Go back to SignInPage
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create account: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up"), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTextField(_firstNameController, "First Name"),
            _buildTextField(_lastNameController, "Last Name"),
            _buildTextField(_ageController, "Age", keyboardType: TextInputType.number),
            _buildTextField(_usernameController, "Username"),
            _buildTextField(_passwordController, "Password", obscure: true),
            _buildTextField(_emailController, "Email"),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscure = false, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
