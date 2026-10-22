
import 'package:flutter/material.dart';
import '../services/child_service.dart';

class AddChildAccountScreen extends StatefulWidget {
  const AddChildAccountScreen({super.key});

  @override
  State<AddChildAccountScreen> createState() =>
      _AddChildAccountScreenState();
}

class _AddChildAccountScreenState
    extends State<AddChildAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _age = TextEditingController();
  final _device = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _device.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _createChild() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await ChildService.createChildAccount(
        name: _name.text.trim(),
        age: int.parse(_age.text.trim()),
        device: _device.text.trim(),
        username: _username.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _field(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool number = false,
        bool email = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: number
            ? TextInputType.number
            : email
            ? TextInputType.emailAddress
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';

          if (text.isEmpty) return 'Required field';

          if (number) {
            final age = int.tryParse(text);
            if (age == null || age < 1 || age > 17) {
              return 'Age must be between 1 and 17';
            }
          }

          if (email &&
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(text)) {
            return 'Invalid email';
          }

          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Add Child Account'),
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(
              Icons.family_restroom,
              size: 65,
              color: Color(0xFF2563EB),
            ),

            const SizedBox(height: 14),

            const Text(
              'Create Child Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Your child will be linked to your '
                  'Parent account automatically.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            _field(
              _name,
              'Child Full Name',
              Icons.badge_outlined,
            ),

            _field(
              _age,
              'Age',
              Icons.cake_outlined,
              number: true,
            ),

            _field(
              _device,
              'Device Name',
              Icons.smartphone,
            ),

            const SizedBox(height: 8),

            const Text(
              'Child Login Information',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 14),

            _field(
              _username,
              'Child Username',
              Icons.person_outline,
            ),

            _field(
              _email,
              'Child Email (OTP)',
              Icons.email_outlined,
              email: true,
            ),

            TextFormField(
              controller: _password,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Child Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 8) {
                  return 'Password must have at least 8 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 26),

            FilledButton.icon(
              onPressed: _loading ? null : _createChild,
              icon: _loading
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.person_add),
              label: const Text('Create & Link Child'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.all(17),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
