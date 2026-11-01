import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ingredient_normalizer.dart';
import '../domain/ingredient.dart';

/// 식재료 직접 추가 또는 수정 모달 다이얼로그
class IngredientEditorDialog extends StatefulWidget {
  final Ingredient? initialIngredient;

  const IngredientEditorDialog({
    super.key,
    this.initialIngredient,
  });

  @override
  State<IngredientEditorDialog> createState() => _IngredientEditorDialogState();
}

class _IngredientEditorDialogState extends State<IngredientEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late IngredientCategory _selectedCategory;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final item = widget.initialIngredient;
    _nameController = TextEditingController(text: item?.name ?? '');
    _quantityController = TextEditingController(
      text: item?.quantity != null
          ? (item!.quantity! == item.quantity!.roundToDouble()
              ? item.quantity!.toInt().toString()
              : item.quantity!.toString())
          : '',
    );
    _unitController = TextEditingController(text: item?.unit ?? '개');
    _selectedCategory = item?.category ?? IngredientCategory.vegetable;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _onSave() {
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) {
      setState(() => _errorText = '식재료 이름을 입력해 주세요.');
      return;
    }
    if (IngredientNormalizer.isNonFoodItem(rawName)) {
      setState(() => _errorText = '식품이 아닌 물체($rawName)는 등록할 수 없습니다.');
      return;
    }

    final canonicalName = IngredientNormalizer.normalizeName(rawName);
    final parsedQty = double.tryParse(_quantityController.text.trim());
    final unitText = _unitController.text.trim();

    final result = Ingredient(
      id: widget.initialIngredient?.id ??
          'manual_${DateTime.now().millisecondsSinceEpoch}',
      name: canonicalName,
      category: IngredientNormalizer.inferCategory(
        canonicalName,
        _selectedCategory,
      ),
      quantity: (parsedQty != null && parsedQty > 0) ? parsedQty : null,
      unit: (parsedQty != null && parsedQty > 0)
          ? (unitText.isEmpty ? '개' : unitText)
          : null,
      confidence: RecognitionConfidence.high,
      isVerified: true,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialIngredient != null;
    return AlertDialog(
      backgroundColor: AppTheme.surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isEdit ? '식재료 수정' : '식재료 직접 추가',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '식재료명 (한국어)',
                hintText: '예: 계란, 삼겹살, 대파, 두부',
                errorText: _errorText,
              ),
              onChanged: (val) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
                final normalized = IngredientNormalizer.normalizeName(val);
                final inferred = IngredientNormalizer.inferCategory(normalized);
                if (inferred != IngredientCategory.other) {
                  setState(() => _selectedCategory = inferred);
                }
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<IngredientCategory>(
              key: ValueKey(_selectedCategory),
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: '카테고리'),
              items: IngredientCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text('${cat.emoji} ${cat.label}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategory = val);
                }
              },
            ),
            const SizedBox(height: 14),
            const Text(
              '수량 및 단위 (선택 사항)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: '미입력 가능 (예: 2)',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      hintText: '개, 모, g, 컵',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '※ 정확한 수량을 모르시면 비워두셔도 됩니다.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _onSave,
          child: Text(isEdit ? '수정 완료' : '추가하기'),
        ),
      ],
    );
  }
}
