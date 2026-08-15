import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../config/theme.dart';
import '../models/auth_user.dart';
import '../providers/session_provider.dart';
import '../services/image_resize_service.dart';
import '../services/supabase_service.dart';

/// 마이페이지 — 내 정보 수정 + 로그아웃. update_profile RPC(008 마이그레이션) 사용.
/// 비밀번호 변경은 이번 스코프 밖.
class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  bool _editMode = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  Uint8List? _newAvatarBytes;
  String? _newAvatarFileName;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _enterEditMode(AuthUser user) {
    _nameController.text = user.name;
    _phoneController.text = user.phoneNumber ?? '';
    _newAvatarBytes = null;
    _newAvatarFileName = null;
    setState(() {
      _error = null;
      _editMode = true;
    });
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final resized = await ImageResizeService.resizeToLimit(bytes, file.name);
    setState(() {
      _newAvatarBytes = resized.bytes;
      _newAvatarFileName = resized.fileName;
    });
  }

  Future<void> _handleSave(AuthUser user) async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = '이름을 입력해주세요.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final client = SupabaseService.client;
    try {
      var avatarUrl = user.avatarUrl;
      if (_newAvatarBytes != null) {
        final ext = (_newAvatarFileName ?? 'jpg').split('.').last;
        final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
        await client.storage.from('avatars').uploadBinary(path, _newAvatarBytes!);
        avatarUrl = client.storage.from('avatars').getPublicUrl(path);
      }

      final rows = await client.rpc('update_profile', params: {
        'p_user_id': user.id,
        'p_name': _nameController.text.trim(),
        'p_phone_number': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'p_avatar_url': avatarUrl,
      }) as List<dynamic>;

      final updated = AuthUser.fromJson(rows.first as Map<String, dynamic>);
      await ref.read(sessionProvider.notifier).login(updated);

      if (!mounted) return;
      setState(() {
        _saving = false;
        _editMode = false;
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = '저장 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      });
    }
  }

  Future<void> _handleLogout() async {
    await ref.read(sessionProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.text900), onPressed: () => context.pop()),
        title: const Text('MY', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text900)),
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const Border(bottom: BorderSide(color: AppColors.grayBorder)),
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('불러오지 못했습니다.')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('로그인 정보가 없습니다.', style: TextStyle(fontSize: 14, color: AppColors.text400)));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Column(
              children: [
                _editMode ? _buildEditForm(user) : _buildView(user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildView(AuthUser user) {
    return Column(
      children: [
        _Avatar(url: user.avatarUrl, name: user.name, size: 88),
        const SizedBox(height: 16),
        Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text900)),
        const SizedBox(height: 4),
        Text('@${user.username}', style: const TextStyle(fontSize: 13, color: AppColors.text400)),
        const SizedBox(height: 24),
        _InfoRow(label: '전화번호', value: user.phoneNumber ?? '등록된 번호가 없어요'),
        _InfoRow(label: '역할', value: user.role),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => _enterEditMode(user),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.grayBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('내 정보 수정', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text900)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _handleLogout,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.grayBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('로그아웃', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text600)),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(AuthUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: InkWell(
            onTap: _pickAvatar,
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                _newAvatarBytes != null
                    ? ClipOval(child: Image.memory(_newAvatarBytes!, width: 88, height: 88, fit: BoxFit.cover))
                    : _Avatar(url: user.avatarUrl, name: user.name, size: 88),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(color: AppColors.primary600, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('이름', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text600)),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
          ),
        ),
        const SizedBox(height: 16),
        const Text('전화번호', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text600)),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text900)),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : () => _handleSave(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_saving ? '저장 중...' : '저장', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => setState(() => _editMode = false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.grayBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('취소', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.text600)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  const _Avatar({required this.url, required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url != null) {
      return ClipOval(child: Image.network(url!, width: size, height: size, fit: BoxFit.cover));
    }
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: AppColors.primary600, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name.substring(0, 1) : '?',
        style: TextStyle(color: Colors.white, fontSize: size * 0.35, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.grayBorder))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.text600)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text900)),
        ],
      ),
    );
  }
}
