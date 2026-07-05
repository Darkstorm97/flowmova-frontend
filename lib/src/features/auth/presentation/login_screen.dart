import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../data/auth_gateway.dart';
import 'auth_form_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({this.authGateway, super.key});

  final AuthGateway? authGateway;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  AuthGateway? _authGateway;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _formError;
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
      title: 'Connexion',
      subtitle: 'Retrouvez vos tickets, vos entreprises et votre profil.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              validator: _validateRequiredPassword,
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
                  : const Text('Se connecter'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.register,
                    ),
              child: const Text('Creer un compte'),
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
      _emailError = null;
      _passwordError = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _authGateway!.login(
        LoginUserCommand(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
      if (!mounted) {
        return;
      }
      await SessionScope.of(context).authenticate(result.accessToken);
      if (!mounted) {
        return;
      }
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.profile,
        (route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
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
            'Connexion impossible pour le moment. Reessayez plus tard.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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

  String? _validateRequiredPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Mot de passe requis';
    }
    return null;
  }

  @override
  void dispose() {
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
