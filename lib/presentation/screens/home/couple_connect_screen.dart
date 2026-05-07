import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

class CoupleConnectScreen extends StatefulWidget {
  const CoupleConnectScreen({super.key});

  @override
  State<CoupleConnectScreen> createState() => _CoupleConnectScreenState();
}

class _CoupleConnectScreenState extends State<CoupleConnectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _inviteCode;
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _generateInviteCode() async {
    setState(() => _isLoading = true);
    try {
      final code = await context.read<AppProvider>().createInviteCode();
      setState(() => _inviteCode = code);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e'), backgroundColor: AppColors.warning),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinWithCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('초대 코드를 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final error = await context.read<AppProvider>().joinWithInviteCode(code);
      if (mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.warning),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('커플 연결이 완료되었습니다!'),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.pop(context);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('커플 연결')),
      body: Column(
        children: [
          // 탭바
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.chipBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.secondaryText,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              tabs: const [
                Tab(text: '초대 코드 생성'),
                Tab(text: '코드로 참여'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCreateTab(),
                _buildJoinTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          AppCard(
            child: Column(
              children: [
                const Icon(Icons.favorite, color: AppColors.primary, size: 48),
                const SizedBox(height: 16),
                Text(
                  '초대 코드 생성',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '생성된 코드를 파트너에게 전달하면\n커플로 연결됩니다',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (_inviteCode != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.softMint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '초대 코드',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _inviteCode!,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryText,
                            letterSpacing: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlineButton(
                    text: '코드 복사하기',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _inviteCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('코드가 복사되었습니다'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icons.copy,
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    text: '새 코드 생성',
                    onPressed: _generateInviteCode,
                    isLoading: _isLoading,
                  ),
                ] else
                  PrimaryButton(
                    text: '초대 코드 생성하기',
                    onPressed: _generateInviteCode,
                    isLoading: _isLoading,
                    icon: Icons.add_circle_outline,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          AppCard(
            child: Column(
              children: [
                const Icon(Icons.link, color: AppColors.primary, size: 48),
                const SizedBox(height: 16),
                Text(
                  '코드로 참여하기',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '파트너가 생성한 초대 코드를\n입력해주세요',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                    color: AppColors.primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: '코드 입력',
                    hintStyle: TextStyle(
                      fontSize: 20,
                      letterSpacing: 4,
                      color: AppColors.secondaryText.withOpacity(0.5),
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: '연결하기',
                  onPressed: _joinWithCode,
                  isLoading: _isLoading,
                  icon: Icons.favorite,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
