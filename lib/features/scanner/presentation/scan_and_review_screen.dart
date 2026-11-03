import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../pantry/domain/ingredient.dart';
import '../../pantry/presentation/ingredient_editor_dialog.dart';
import '../data/ingredient_scanner_service.dart';

/// 카메라 촬영(갤러리 선택 제거), 4구역 정밀 AI 식재료 인식(Spatial Vision + 한글 포장지 OCR) 및 사용자 검수·수정 화면
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
  bool _errorRequiresApiKey = false;
  String? _analysisSummary;
  List<String> _scannedZones = const [];
  List<String> _excludedItems = const [];
  List<Ingredient> _draftIngredients = const [];
  bool _hasCompletedScan = false;
  String _selectedSourceDescription = '';
  Uint8List? _lastCapturedBytes;

  Future<void> _captureWithCamera() async {
    try {
      // 냉장고 안쪽 작은 식재료와 한글 포장지 라벨(OCR) 인식률을 높이기 위해 1920px / 92% 고해상도 촬영 적용
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 92,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      _lastCapturedBytes = bytes;
      await _runAiAnalysis(
        imageBytes: bytes,
        sourceLabel: '카메라 촬영 이미지 (4구역 비전 + 한글 OCR)',
      );
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage =
            '카메라 접근 권한을 확인할 수 없습니다. 기기 설정에서 카메라 권한을 허용하거나 아래의 스마트 샘플/수동 입력을 이용해 주세요.';
      });
    }
  }

  Future<void> _openApiKeyConfigDialog() async {
    final currentKey = ref.read(appStateProvider).customGeminiApiKey;
    final controller = TextEditingController(text: currentKey);

    final savedKey = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.key_rounded, color: AppTheme.terracottaDark),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'AI 비전 인식 키 설정 (Gemini 2.5)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '실제 카메라로 촬영한 냉장고 사진을 4구역 공간 분할 + 한글 포장지 OCR로 정밀 분석하려면 Google AI Studio의 Gemini API 키를 입력해 주세요.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: false,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key (AIza...)',
                hintText: 'AIzaSy...',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• 입력된 키는 기기 내부(SharedPreferences)에만 안전하게 저장됩니다.',
              style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.terracotta,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('저장 및 적용'),
          ),
        ],
      ),
    );

    if (savedKey != null) {
      ref.read(appStateProvider.notifier).setCustomGeminiApiKey(savedKey);
      // 방금 촬영해 둔 사진이 있다면 키 저장 즉시 재분석 실행!
      if (_lastCapturedBytes != null &&
          _lastCapturedBytes!.isNotEmpty &&
          savedKey.isNotEmpty) {
        await _runAiAnalysis(
          imageBytes: _lastCapturedBytes!,
          sourceLabel: '카메라 촬영 이미지 (4구역 비전 + 한글 OCR)',
        );
      }
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
      _errorRequiresApiKey = false;
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
        _scannedZones = result.scannedZones;
        _excludedItems = result.excludedNonFoodItems;
        _draftIngredients = result.recognizedIngredients;
      });
    } on ScannerException catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = e.message;
        _errorRequiresApiKey = e.requiresApiKey;
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
    final scanner = ref.watch(scannerServiceProvider);
    final hasLiveKey = scanner.hasLiveApiKey;
    final uncertainItems =
        _draftIngredients.where((e) => e.needsConfirmation).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 냉장고 식재료 스캔'),
        actions: [
          TextButton.icon(
            key: const Key('open_api_key_dialog_button'),
            style: TextButton.styleFrom(
              foregroundColor:
                  hasLiveKey ? AppTheme.primaryGreenDark : AppTheme.terracottaDark,
            ),
            onPressed: _openApiKeyConfigDialog,
            icon: Icon(
              hasLiveKey ? Icons.verified_rounded : Icons.key_rounded,
              size: 18,
            ),
            label: Text(
              hasLiveKey ? '실사진 AI 활성' : '🔑 AI 키 설정',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isAnalyzing
            ? _buildLoadingView()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildVisionAccuracyGuideCard(hasLiveKey),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.terracotta,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _saveAndProceedToRecommendations,
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          '재료 ${_draftIngredients.length}개 확정 및 요리 추천받기',
                          style: const TextStyle(
                            fontFeatures: AppTheme.tabularFigures,
                          ),
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

  /// 4구역 공간 분할 비전 + 한글 포장지 OCR 안내 배너
  Widget _buildVisionAccuracyGuideCard(bool hasLiveKey) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1917),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasLiveKey
                      ? AppTheme.primaryGreen
                      : AppTheme.terracotta,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasLiveKey
                      ? '4구역 공간비전 + 한글 OCR 활성'
                      : 'AI 비전 엔진 안내',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              if (!hasLiveKey)
                InkWell(
                  onTap: _openApiKeyConfigDialog,
                  child: const Text(
                    '실사진 분석 키 등록하기 →',
                    style: TextStyle(
                      color: AppTheme.terracotta,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• 인식률 2배 높이는 팁: 냉장고의 ①상단 ②중단 ③채소실 ④문짝 포켓이 잘 보이게 찍고, 두부·우유·어묵·소스류는 한글 라벨이 보이도록 촬영하면 OCR이 브랜드명을 자동 정제하여 정확히 인식합니다.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFE7E5E4),
              height: 1.42,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureSourceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. 냉장고 식재료 카메라 촬영',
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              '냉장고 내부나 조리대 위 식재료를 카메라로 직접 촬영하면 4구역 분할 비전 + 한글 OCR이 식재료를 탐지합니다.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('scan_camera_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.espressoCharcoal,
                  foregroundColor: Colors.white,
                ),
                onPressed: _captureWithCamera,
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppTheme.terracotta,
                ),
                label: const Text('카메라로 냉장고 촬영하기 (고해상도 OCR)'),
              ),
            ),
            const Divider(height: 28),
            const Text(
              '빠른 시뮬레이션 / 테스트용 냉장고 촬영 샘플',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
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
            const CircularProgressIndicator(color: AppTheme.terracotta),
            const SizedBox(height: 20),
            Text(
              '$_selectedSourceDescription 분석 중...',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              '1) 상단·중단·채소실·도어포켓 4구역 공간 스캔 중\n2) 포장지 한글 라벨 OCR 판독 및 브랜드명 정제 중\n3) 반찬통·비닐 등 비식품 자동 제외 중',
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.dangerRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorRequiresApiKey
                      ? '실제 카메라 사진 분석을 위해 AI 키 설정이 필요합니다'
                      : 'AI 식재료 인식에 실패했어요',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_errorRequiresApiKey)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.terracotta,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _openApiKeyConfigDialog,
                  icon: const Icon(Icons.key_rounded, size: 18),
                  label: const Text('Gemini API 키 입력하기'),
                ),
              OutlinedButton.icon(
                key: const Key('retry_scan_button'),
                onPressed: () => _runAiAnalysis(
                  imageBytes: Uint8List(0),
                  sourceLabel: '자취방 기본 냉장고 재시도',
                  demoPresetKey: 'typical_fridge',
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('샘플로 다시 시도'),
              ),
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
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.terracottaDark,
              ),
              onPressed: _addManualDraftItem,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text(
                '직접 추가',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        if (_analysisSummary != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _analysisSummary!,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.textSecondary,
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
          ),
        if (_scannedZones.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _scannedZones
                  .map(
                    (zone) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.terracottaLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '📍 스캔 구역: $zone',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.terracottaDark,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        if (_excludedItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warmWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSubtle),
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
              borderRadius: BorderRadius.circular(14),
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
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentAmberDark,
                      fontFeatures: AppTheme.tabularFigures,
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
        borderRadius: BorderRadius.circular(16),
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
                              fontWeight: FontWeight.w800,
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
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              needsCheck ? '⚠️ 확인 필요' : '✓ 인식 확실',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
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
                          fontFeatures: AppTheme.tabularFigures,
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
