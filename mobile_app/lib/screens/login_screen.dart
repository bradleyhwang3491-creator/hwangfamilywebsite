import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../models/auth_user.dart';
import '../providers/session_provider.dart';
import '../services/supabase_service.dart';

/// Ported from src/pages/LoginPage.tsx.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  bool _idTouched = false;
  bool _pwTouched = false;
  bool _loading = false;
  String? _loginError;

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  bool get _idValid => _idController.text.trim().isNotEmpty;
  bool get _pwValid => _pwController.text.length >= 4;
  bool get _formValid => _idValid && _pwValid;

  Future<void> _handleSubmit() async {
    setState(() {
      _idTouched = true;
      _pwTouched = true;
    });
    if (!_formValid) return;

    setState(() {
      _loginError = null;
      _loading = true;
    });

    try {
      final data = await SupabaseService.client.rpc('login', params: {
        'p_username': _idController.text.trim(),
        'p_password': _pwController.text,
      });

      final rows = data as List<dynamic>?;
      if (rows == null || rows.isEmpty) {
        setState(() {
          _loading = false;
          _loginError = '아이디 또는 비밀번호가 올바르지 않습니다.';
        });
        return;
      }

      final user = AuthUser.fromJson(rows.first as Map<String, dynamic>);
      await ref.read(sessionProvider.notifier).login(user);
      if (!mounted) return;
      context.go('/home');
    } catch (_) {
      setState(() {
        _loading = false;
        _loginError = '로그인 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: AppColors.shadowCard),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/images/family_hero.jpg', width: double.infinity, height: 200, fit: BoxFit.cover),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      _FieldLabel('아이디'),
                const SizedBox(height: 6),
                _LoginField(
                  controller: _idController,
                  hint: '아이디를 입력하세요',
                  obscure: false,
                  hasError: _idTouched && !_idValid,
                  onChanged: (_) => setState(() {}),
                  onBlur: () => setState(() => _idTouched = true),
                ),
                if (_idTouched && !_idValid) ...[
                  const SizedBox(height: 6),
                  const Text('아이디를 입력해주세요.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text900)),
                ],
                const SizedBox(height: 16),

                _FieldLabel('비밀번호'),
                const SizedBox(height: 6),
                _LoginField(
                  controller: _pwController,
                  hint: '비밀번호를 입력하세요',
                  obscure: true,
                  hasError: _pwTouched && !_pwValid,
                  onChanged: (_) => setState(() {}),
                  onBlur: () => setState(() => _pwTouched = true),
                ),
                if (_pwTouched && !_pwValid) ...[
                  const SizedBox(height: 6),
                  const Text('비밀번호는 4자 이상 입력해주세요.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text900)),
                ],

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                    child: const Text('아이디/비밀번호 찾기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text600)),
                  ),
                ),

                if (_loginError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _loginError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text900),
                  ),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _loading ? AppColors.text400 : AppColors.primary600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(_loading ? '확인 중...' : '로그인', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ),
                ),

                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.grayBorder, height: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: const Text('또는', style: TextStyle(fontSize: 12, color: AppColors.text400)),
                    ),
                    const Expanded(child: Divider(color: AppColors.grayBorder, height: 1)),
                  ],
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF1F3F5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('가족 초대 코드로 가입하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.text900)),
                  ),
                ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text600));
  }
}

class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onBlur;

  const _LoginField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.hasError,
    required this.onChanged,
    required this.onBlur,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) onBlur();
      },
      child: SizedBox(
        height: 52,
        child: TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, color: AppColors.text900),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.text400),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: hasError ? AppColors.text900 : AppColors.grayBorder, width: hasError ? 2 : 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: hasError ? AppColors.text900 : AppColors.grayBorder, width: hasError ? 2 : 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: hasError ? AppColors.text900 : AppColors.grayBorder, width: hasError ? 2 : 1),
            ),
          ),
        ),
      ),
    );
  }
}
