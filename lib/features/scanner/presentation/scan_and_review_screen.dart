import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../pantry/domain/ingredient.dart';
import '../../pantry/presentation/ingredient_editor_dialog.dart';
import '../data/ingredient_scanner_service.dart';

/// 카메라 촬영(갤러리 선택 제거), AI 식재료 인식 및 사용자 검수·수정 화면
class ScanAndReviewScreen extends ConsumerStatefulWidget {
  const ScanAndReviewScreen({super.key});

  @override
  ConsumerState<ScanAndReviewScreen> createState() =>
      _ScanAndReviewScreenState();
}

class _ScanAndReviewScreenState extends ConsumerState<ScanAndReviewScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _isAnalyzing = false;
  String? _errorMessage;
  String? _analysisSummary;
  List<String> _excludedItems = const [];
  List<Ingredient> _draftIngredients = const [];
  bool _hasCompletedScan = false;
  String _selectedSourceDescription = '';

  Future<void> _captureWithCamera() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 82,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      await _runAiAnalysis(
        imageBytes: bytes,
        sourceLabel: '카메라 촬영 이미지',
      );
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage =
            '카메라 접근 권한을 확인할 수 없습니다. 기기 설정에서 카메라 권한을 허용하거나 아래의 스마트 샘플/수동 입력을 이용해 주세요.';
      });
    }
  }

  Future<void> _runAiAnalysis({
    required Uint8List imageBytes,
    required String sourceLabel,
    String? demoPresetKey,
  }) async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _selectedSourceDescription = sourceLabel;
    });

    try {
      final scanner = ref.read(scannerServiceProvider);
      final result = await scanner.analyzeImage(
        imageBytes: imageBytes,
        demoPresetKey: demoPresetKey,
      );

      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _hasCompletedScan = true;
        _analysisSummary = result.analysisSummary;
        _excludedItems = result.excludedNonFoodItems;
        _draftIngredients = result.recognizedIngredients;
      });
    } on ScannerException catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = '알 수 없는 오류로 인식에 실패했습니다. 다시 시도하거나 직접 입력해 주세요.';
      });
    }
  }

  void _confirmSingleItem(Ingredient item) {
    setState(() {
      _draftIngredients = _draftIngredients.map((e) {
        if (e.id == item.id) {
          return e.copyWith(
            isVerified: true,
            confidence: RecognitionConfidence.high,
          );
        }
        return e;
      }).toList();
    });
  }

  Future<void> _editDraftItem(Ingredient item) async {
    final edited = await showDialog<Ingredient>(
      context: context,
      builder: (_) => IngredientEditorDialog(initialIngredient: item),
    );
    if (edited != null) {
      setState(() {
        _draftIngredients = _draftIngredients
            .map((e) => e.id == item.id ? edited : e)
            .toList();
      });
    }
  }

  void _removeDraftItem(String id) {
    setState(() {
      _draftIngredients = _draftIngredients.where((e) => e.id != id).toList();
    });
  }

  Future<void> _addManualDraftItem() async {
    final added = await showDialog<Ingredient>(
      context: context,
      builder: (_) => const IngredientEditorDialog(),
    );
    if (added != null) {
      setState(() {
        _hasCompletedScan = true;
        _errorMessage = null;
        _draftIngredients = [..._draftIngredients, added];
      });
    }
  }

  void _saveAndProceedToRecommendations() {
    if (_draftIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장할 식재료가 없습니다. 식재료를 최소 1개 이상 추가해 주세요.')),
      );
      return;
    }
    ref
        .read(appStateProvider.notifier)
        .mergeVerifiedScanResults(_draftIngredients);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final uncertainItems =
        _draftIngredients.where((e) => e.needsConfirmation).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 냉장고 식재료 스캔'),
      ),
      body: SafeArea(
        child: _isAnalyzing
            ? _buildLoadingView()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPrivacyNoticeBanner(),
                  const SizedBox(height: 16),
                  _buildCaptureSourceSection(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorFallbackCard(_errorMessage!),
                  ],
                  if (_hasCompletedScan) ...[
                    const SizedBox(height: 20),
                    _buildReviewSection(uncertainItems),
                  ],
                ],
              ),
      ),
      bottomNavigationBar: _hasCompletedScan && !_isAnalyzing
          ? SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
                ),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _addManualDraftItem,
                      icon: const Icon(Icons.add),
                      label: const Text('누락 재료 추가'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        key: const Key('confirm_scan_results_button'),
                        onPressed: _saveAndProceedToRecommendations,
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          '재료 ${_draftIngredients.length}개 확정 및 요리 추천받기',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPrivacyNoticeBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreenLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: AppTheme.primaryGreenDark,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '안심 사진 분석 안내: 촬영된 사진은 용량을 압축하여 식재료 인식에만 일시 사용되며 서버에 영구 저장되지 않습니다. 사진만으로 알 수 없는 수량·유통기한은 임의로 생성하지 않습니다.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureSourceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. 냉장고 식재료 카메라 촬영',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              '냉장고 내부나 조리대 위 식재료를 카메라로 직접 촬영하면 AI가 식재료를 인식합니다.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('scan_camera_button'),
                onPressed: _captureWithCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('카메라로 냉장고 촬영하기'),
              ),
            ),
            const Divider(height: 28),
            const Text(
              '빠른 시뮬레이션 / 테스트용 냉장고 촬영 샘플',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('demo_preset_typical_button'),
                  icon: const Icon(Icons.kitchen, size: 16),
                  label: const Text('자취방 기본 냉장고 (중복/불확실 포함)'),
                  onPressed: () => _runAiAnalysis(
                    imageBytes: Uint8List(0),
                    sourceLabel: '자취방 기본 냉장고 샘플',
                    demoPresetKey: 'typical_fridge',
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('demo_preset_meat_button'),
                  icon: const Icon(Icons.restaurant, size: 16),
                  label: const Text('고기/찌개 재료 냉장고'),
                  onPressed: () => _runAiAnalysis(
                    imageBytes: Uint8List(0),
                    sourceLabel: '고기/찌개 재료 냉장고 샘플',
                    demoPresetKey: 'meat_party',
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('demo_preset_error_button'),
                  icon: const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppTheme.dangerRed,
                  ),
                  label: const Text('인식 실패/오류 테스트'),
                  onPressed: () => _runAiAnalysis(
                    imageBytes: Uint8List(0),
                    sourceLabel: '오류 시뮬레이션',
                    demoPresetKey: 'simulate_error',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryGreen),
            const SizedBox(height: 20),
            Text(
              '$_selectedSourceDescription 분석 중...',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI가 식재료 이름을 한국어로 표준화하고\n반찬통·비닐 등 비식품을 제외하고 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorFallbackCard(String errorMsg) {
    return Container(
      key: const Key('scan_error_fallback_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.dangerRedLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: AppTheme.dangerRed),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI 식재료 인식에 실패했어요',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.dangerRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            errorMsg,
            style: const TextStyle(fontSize: 13.5, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                key: const Key('retry_scan_button'),
                onPressed: () => _runAiAnalysis(
                  imageBytes: Uint8List(0),
                  sourceLabel: '자취방 기본 냉장고 재시도',
                  demoPresetKey: 'typical_fridge',
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('다시 시도'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                key: const Key('manual_fallback_button'),
                onPressed: _addManualDraftItem,
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('직접 식재료 입력하기'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(List<Ingredient> uncertainItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '2. 인식 결과 확인 및 수정',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            TextButton.icon(
              onPressed: _addManualDraftItem,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('직접 추가'),
            ),
          ],
        ),
        if (_analysisSummary != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              _analysisSummary!,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        if (_excludedItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '🧹 자동 제외된 비식품 물체: ${_excludedItems.join(', ')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        if (uncertainItems.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentAmberLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentAmber),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.help_outline_rounded,
                  color: AppTheme.accentAmberDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '확인이 필요한 재료가 ${uncertainItems.length}개 있어요. 맞으면 [맞아요]를 누르거나 이름을 수정해 주세요.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentAmberDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ..._draftIngredients.map(_buildDraftIngredientTile),
      ],
    );
  }

  Widget _buildDraftIngredientTile(Ingredient item) {
    final needsCheck = item.needsConfirmation;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: needsCheck ? AppTheme.accentAmber : AppTheme.borderSubtle,
          width: needsCheck ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  item.category.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: needsCheck
                                  ? AppTheme.accentAmberLight
                                  : AppTheme.primaryGreenLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              needsCheck ? '⚠️ 확인 필요' : '✓ 인식 확실',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: needsCheck
                                    ? AppTheme.accentAmberDark
                                    : AppTheme.primaryGreenDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.category.label} · ${item.quantityDisplay}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (needsCheck)
                  TextButton(
                    key: Key('confirm_item_${item.name}'),
                    onPressed: () => _confirmSingleItem(item),
                    child: const Text('맞아요'),
                  ),
                IconButton(
                  tooltip: '수정',
                  onPressed: () => _editDraftItem(item),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  tooltip: '삭제',
                  onPressed: () => _removeDraftItem(item.id),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppTheme.dangerRed,
                  ),
                ),
              ],
            ),
            if (needsCheck && item.uncertaintyNote != null) ...[
              const SizedBox(height: 6),
              Text(
                '💡 ${item.uncertaintyNote}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.accentAmberDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
