import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _name = '';
  String _email = '';
  String? _error;
  File? _imageFile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _name = doc['name'] ?? '';
        _email = user.email ?? '';
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    _formKey.currentState?.save();

    setState(() => _loading = true);

    try {
      // Actualizar nombre en Firestore
      await _firestore.collection('users').doc(user.uid).update({'name': _name});

      // TODO: Subir imagen a Storage y actualizar URL en Firestore
      // if (_imageFile != null) {...}

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

Future<void> _updateEmail(String newEmail) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    // ⚠️ Reautenticación antes de cambiar el correo
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: 'user_password', // Debes pedirle la contraseña real al usuario
    );
    await user.reauthenticateWithCredential(credential);

    // ✅ Nuevo método en firebase_auth v6
    await user.verifyBeforeUpdateEmail(newEmail);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Correo de verificación enviado al nuevo email.')),
    );
  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.message}')),
    );
  }
}

  Future<void> _updatePassword(String newPassword) async {
    try {
      await _auth.currentUser!.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada')));
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 10),
                  ],
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null ? const Icon(Icons.person, size: 50) : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: _name,
                          decoration: const InputDecoration(labelText: 'Nombre'),
                          validator: (v) => v == null || v.isEmpty ? 'Nombre obligatorio' : null,
                          onSaved: (v) => _name = v!,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _email,
                          decoration: const InputDecoration(labelText: 'Correo'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Correo obligatorio';
                            if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(v)) return 'Correo inválido';
                            return null;
                          },
                          onFieldSubmitted: _updateEmail,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                          obscureText: true,
                          onFieldSubmitted: _updatePassword,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(onPressed: _updateProfile, child: const Text('Actualizar perfil')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
