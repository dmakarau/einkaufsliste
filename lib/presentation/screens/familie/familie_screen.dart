import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';

class FamilieScreen extends StatefulWidget {
  const FamilieScreen({super.key});

  @override
  State<FamilieScreen> createState() => _FamilieScreenState();
}

class _FamilieScreenState extends State<FamilieScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: Text(context.l10n.familieTitle),
            backgroundColor: AppColors.surface,
            actions: [
              if (state is AuthAuthenticated)
                TextButton(
                  onPressed: () => context.read<AuthCubit>().signOut(),
                  child: Text(
                    context.l10n.signOut,
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
            ],
          ),
          body: switch (state) {
            AuthAuthenticated() => _AuthenticatedBody(user: state.user.email),
            AuthLoading() => const Center(child: CircularProgressIndicator()),
            _ => _LoginForm(
                emailController: _emailController,
                passwordController: _passwordController,
              ),
          },
        );
      },
    );
  }
}

class _AuthenticatedBody extends StatelessWidget {
  const _AuthenticatedBody({required this.user});

  final String? user;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              context.l10n.welcomeUser(user ?? ''),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.emailController,
    required this.passwordController,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Text(
            context.l10n.familieHinweis,
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 17, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 48),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: context.l10n.email),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(hintText: context.l10n.passwort),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.read<AuthCubit>().signIn(
                    email: emailController.text.trim(),
                    password: passwordController.text,
                  ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(context.l10n.signIn),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.read<AuthCubit>().signUp(
                  email: emailController.text.trim(),
                  password: passwordController.text,
                ),
            child: Text(context.l10n.signUp,
                style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
