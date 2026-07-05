import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../data/auth_gateway.dart';
import 'auth_form_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({this.authGateway, super.key});

  final AuthGateway? authGateway;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  AuthGateway? _authGateway;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _formError;
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _passwordError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authGateway ??=
        widget.authGateway ??
        BackendAuthGateway(
          ApiClient(
            accessTokenProvider: SessionScope.of(context).currentAccessToken,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormShell(
      title: 'Creer un compte',
      subtitle:
          'Un compte vous permet de suivre vos tickets et vos espaces entreprise.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'Prenom',
                errorText: _firstNameError,
              ),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.givenName],
              validator: _validateRequired,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Nom',
                errorText: _lastNameError,
              ),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.familyName],
              validator: _validateRequired,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: _emailError,
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                helperText: '8 caracteres minimum',
                errorText: _passwordError,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Afficher le mot de passe'
                      : 'Masquer le mot de passe',
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _submit(),
              validator: _validatePassword,
            ),
            if (_formError != null) ...[
              const SizedBox(height: 14),
              _AuthErrorMessage(message: _formError!),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Creer mon compte'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.login,
                    ),
              child: const Text('J ai deja un compte'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _formError = null;
      _firstNameError = null;
      _lastNameError = null;
      _emailError = null;
      _passwordError = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _authGateway!.register(
        RegisterUserCommand(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte cree. Vous pouvez maintenant vous connecter.'),
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _firstNameError = error.fieldMessage('firstName');
        _lastNameError = error.fieldMessage('lastName');
        _emailError = error.fieldMessage('email');
        _passwordError = error.fieldMessage('password');
        _formError = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _formError =
            'Creation du compte impossible pour le moment. Reessayez plus tard.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _validateRequired(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Champ requis';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email requis';
    }
    if (!email.contains('@')) {
      return 'Email invalide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Mot de passe requis';
    }
    if (password.length < 8) {
      return '8 caracteres minimum';
    }
    return null;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _AuthErrorMessage extends StatelessWidget {
  const _AuthErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: FlowMovaColors.error),
    );
  }
}
