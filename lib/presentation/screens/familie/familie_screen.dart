import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../data/models/family_group_member_model.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/family/family_cubit.dart';

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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, authState) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: Text(context.l10n.familieTitle),
            backgroundColor: AppColors.surface,
            actions: [
              if (authState is AuthAuthenticated)
                TextButton(
                  onPressed: () => context.read<AuthCubit>().signOut(),
                  child: Text(
                    context.l10n.signOut,
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
            ],
          ),
          body: switch (authState) {
            AuthLoading() => const Center(child: CircularProgressIndicator()),
            AuthAuthenticated() => _GroupBody(userEmail: authState.user.email),
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

// ---------------------------------------------------------------------------
// Authenticated body — delegates to FamilyCubit state
// ---------------------------------------------------------------------------

class _GroupBody extends StatelessWidget {
  const _GroupBody({required this.userEmail});

  final String? userEmail;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FamilyCubit, FamilyState>(
      listener: (context, state) {
        if (state is FamilyError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.fehlerAufgetreten)),
          );
        }
      },
      builder: (context, state) => switch (state) {
        FamilyLoading() => const Center(child: CircularProgressIndicator()),
        FamilyNoGroup() => _NoGroupView(userEmail: userEmail),
        FamilyHasPendingInvite() => _PendingInviteView(state: state),
        FamilyHasGroup() => _GroupView(state: state),
        FamilyError() => _ErrorView(
          onRetry: () => context.read<FamilyCubit>().loadGroupStatus(),
        ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// No group yet
// ---------------------------------------------------------------------------

class _NoGroupView extends StatelessWidget {
  const _NoGroupView({required this.userEmail});

  final String? userEmail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.group_outlined,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            if (userEmail != null) ...[
              Text(
                context.l10n.welcomeUser(userEmail!),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              context.l10n.keinGruppe,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showCreateGroupDialog(context),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.gruppeErstellen),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.gruppeErstellen),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: context.l10n.gruppenname),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.abbrechen),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<FamilyCubit>().createGroup(name);
                Navigator.pop(dialogContext);
              }
            },
            child: Text(context.l10n.gruppeErstellen),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending invitation
// ---------------------------------------------------------------------------

class _PendingInviteView extends StatelessWidget {
  const _PendingInviteView({required this.state});

  final FamilyHasPendingInvite state;

  @override
  Widget build(BuildContext context) {
    final groupName = state.group.name == '—'
        ? context.l10n.gruppeUnbekannt
        : state.group.name;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mail_outline,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.einladungErhalten(groupName),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.read<FamilyCubit>().acceptInvite(
                      state.group.id,
                    ),
                    child: Text(context.l10n.einladungAnnehmen),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Has group — member list + invite
// ---------------------------------------------------------------------------

class _GroupView extends StatelessWidget {
  const _GroupView({required this.state});

  final FamilyHasGroup state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Group header
        Row(
          children: [
            const Icon(Icons.group, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state.group.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.familieGruppenTitel,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        const Divider(),

        // Members section
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            context.l10n.mitglieder,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ...state.members.map((m) => _MemberTile(member: m, state: state)),
        const SizedBox(height: 16),

        // Invite button (owner only)
        if (state.isOwner)
          OutlinedButton.icon(
            onPressed: () => _showInviteDialog(context),
            icon: const Icon(Icons.person_add_outlined),
            label: Text(context.l10n.mitgliedEinladen),
          ),

        const SizedBox(height: 8),

        // Leave group button (non-owners)
        if (!state.isOwner)
          TextButton(
            onPressed: () => _confirmLeave(context),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.l10n.gruppeVerlassen),
          ),

        // Delete group button (owner only)
        if (state.isOwner)
          TextButton(
            onPressed: () => _confirmDeleteGroup(context),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.l10n.gruppeLoeschen),
          ),
      ],
    );
  }

  void _showInviteDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.mitgliedEinladen),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: context.l10n.gruppeEinladenHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.abbrechen),
          ),
          FilledButton(
            onPressed: () {
              final email = controller.text.trim();
              if (email.isNotEmpty) {
                context.read<FamilyCubit>().inviteMember(email);
                Navigator.pop(dialogContext);
              }
            },
            child: Text(context.l10n.mitgliedEinladen),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.gruppeLoeschen),
        content: Text(context.l10n.gruppeLoeschenBestaetigung),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.abbrechen),
          ),
          FilledButton(
            onPressed: () {
              context.read<FamilyCubit>().deleteGroup();
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.l10n.gruppeLoeschen),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.gruppeVerlassen),
        content: Text(context.l10n.gruppeVerlassenBestaetigung),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.abbrechen),
          ),
          FilledButton(
            onPressed: () {
              context.read<FamilyCubit>().leaveGroup();
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.l10n.gruppeVerlassen),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.state});

  final FamilyGroupMemberModel member;
  final FamilyHasGroup state;

  @override
  Widget build(BuildContext context) {
    final roleLabel = member.isAdmin
        ? context.l10n.adminLabel
        : context.l10n.memberLabel;
    final statusLabel = member.isPending
        ? context.l10n.einladungAusstehend
        : null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withAlpha(30),
        child: Text(
          member.email.isNotEmpty ? member.email[0].toUpperCase() : '?',
          style: const TextStyle(color: AppColors.primary),
        ),
      ),
      title: Text(member.email, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          _Badge(label: roleLabel, color: AppColors.primary),
          if (statusLabel != null) ...[
            const SizedBox(width: 4),
            _Badge(label: statusLabel, color: Colors.orange),
          ],
        ],
      ),
      trailing: state.isOwner && !member.isAdmin
          ? IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              tooltip: context.l10n.mitgliedEntfernen,
              onPressed: () =>
                  context.read<FamilyCubit>().removeMember(member.id),
            )
          : null,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error view
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.fehlerAufgetreten, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.l10n.wiederholen),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Login form (unauthenticated)
// ---------------------------------------------------------------------------

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.emailController,
    required this.passwordController,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Text(
            context.l10n.familieHinweis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, color: AppColors.textPrimary),
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
            child: Text(
              context.l10n.signUp,
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.read<AuthCubit>().signInWithGoogle(),
              icon: SvgPicture.string(_kGoogleLogoSvg, width: 20, height: 20),
              label: Text(context.l10n.signInWithGoogle),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _kGoogleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 533.5 544.3">
  <path fill="#4285F4" d="M533.5 278.4c0-18.5-1.5-37.1-4.7-55.3H272.1v104.8h147c-6.1 33.8-25.7 63.7-54.4 82.7v68h87.7c51.5-47.4 81.1-117.4 81.1-200.2z"/>
  <path fill="#34A853" d="M272.1 544.3c73.4 0 135.3-24.1 180.4-65.7l-87.7-68c-24.4 16.6-55.9 26-92.6 26-71 0-131.2-47.9-152.8-112.3H28.9v70.1c46.2 91.9 140.3 149.9 243.2 149.9z"/>
  <path fill="#FBBC05" d="M119.3 324.3c-11.4-33.8-11.4-70.4 0-104.2V150H28.9c-38.6 76.9-38.6 167.5 0 244.4l90.4-70.1z"/>
  <path fill="#EA4335" d="M272.1 107.7c38.8-.6 76.3 14 104.4 40.8l77.7-77.7C405 24.6 339.7-.8 272.1 0 169.2 0 75.1 58 28.9 150l90.4 70.1c21.5-64.5 81.8-112.4 152.8-112.4z"/>
</svg>
''';
