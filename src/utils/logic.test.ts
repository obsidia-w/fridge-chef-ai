import test from 'node:test';
import assert from 'node:assert/strict';
import { IngredientNormalizer } from './ingredientNormalizer';
import { recommendRecipes } from './recipeRecommendationEngine';
import { VERIFIED_RECIPES } from '../data/verifiedRecipesData';
import { AiResponseValidator } from '../services/ingredientScannerService';
import { getExpirationStatus, Ingredient } from '../types';

test('IngredientNormalizer normalizes synonyms and strips brand names', () => {
  assert.equal(IngredientNormalizer.normalizeName('풀무원 목초 달걀 (특란)'), '계란');
  assert.equal(IngredientNormalizer.normalizeName('비비고 포기김치'), '김치');
  assert.equal(IngredientNormalizer.normalizeName('한돈 삼겹살'), '삼겹살');
  assert.equal(IngredientNormalizer.normalizeName('진간장'), '간장');
});

test('IngredientNormalizer filters non-food items and deduplicates quantities and expiration dates', () => {
  assert.equal(IngredientNormalizer.isNonFoodItem('락앤락 반찬통'), true);
  assert.equal(IngredientNormalizer.isNonFoodItem('양파'), false);

  const raw: Ingredient[] = [
    {
      id: '1',
      name: '달걀',
      category: 'eggDairy',
      quantity: 4,
      unit: '개',
      expirationDate: '2026-11-10',
      confidence: 'high',
      isVerified: true,
    },
    {
      id: '2',
      name: '특란',
      category: 'eggDairy',
      quantity: 2,
      unit: '개',
      expirationDate: '2026-11-06',
      confidence: 'high',
      isVerified: true,
    },
    {
      id: '3',
      name: '플라스틱 용기',
      category: 'other',
      confidence: 'low',
      isVerified: false,
    },
  ];

  const deduplicated = IngredientNormalizer.normalizeAndDeduplicate(raw);
  assert.equal(deduplicated.length, 1);
  assert.equal(deduplicated[0].name, '계란');
  assert.equal(deduplicated[0].quantity, 6);
  assert.equal(deduplicated[0].expirationDate, '2026-11-06');
});

test('getExpirationStatus classifies expired, expiringSoon (<= 3 days), fresh, and none', () => {
  const refDate = new Date(2026, 10, 5); // 2026-11-05

  const noneStatus = getExpirationStatus(null, refDate);
  assert.equal(noneStatus.urgency, 'none');
  assert.equal(noneStatus.isWarning, false);

  const dDayStatus = getExpirationStatus('2026-11-05', refDate);
  assert.equal(dDayStatus.urgency, 'expiringSoon');
  assert.equal(dDayStatus.daysRemaining, 0);
  assert.equal(dDayStatus.isWarning, true);

  const twoDaysStatus = getExpirationStatus('2026-11-07', refDate);
  assert.equal(twoDaysStatus.urgency, 'expiringSoon');
  assert.equal(twoDaysStatus.daysRemaining, 2);
  assert.equal(twoDaysStatus.label, '소비기한 임박 (D-2)');
  assert.equal(twoDaysStatus.isWarning, true);

  const expiredStatus = getExpirationStatus('2026-11-03', refDate);
  assert.equal(expiredStatus.urgency, 'expired');
  assert.equal(expiredStatus.daysRemaining, -2);
  assert.equal(expiredStatus.isWarning, true);

  const freshStatus = getExpirationStatus('2026-11-15', refDate);
  assert.equal(freshStatus.urgency, 'fresh');
  assert.equal(freshStatus.daysRemaining, 10);
  assert.equal(freshStatus.isWarning, false);
});

test('recommendRecipes classifies canMakeNow vs almostReady and filters by main ingredient and allergens', () => {
  const pantry: Ingredient[] = [
    { id: '1', name: '계란', category: 'eggDairy', quantity: 4, unit: '개', confidence: 'high', isVerified: true },
    { id: '2', name: '대파', category: 'vegetable', quantity: 1, unit: '대', confidence: 'high', isVerified: true },
    { id: '3', name: '밥', category: 'grain', quantity: 2, unit: '공기', confidence: 'high', isVerified: true },
    { id: '4', name: '김치', category: 'processed', quantity: 300, unit: 'g', confidence: 'high', isVerified: true },
    { id: '5', name: '스팸/통조림햄', category: 'processed', quantity: 200, unit: 'g', confidence: 'high', isVerified: true },
  ];
  const seasonings = new Set(['소금', '간장', '식용유', '참기름', '고춧가루', '설탕']);

  const allRecs = recommendRecipes({
    pantryIngredients: pantry,
    ownedSeasonings: seasonings,
    allRecipes: VERIFIED_RECIPES,
    preferences: { allergens: [], dislikedIngredients: [] },
  });

  const canMakeNowIds = allRecs.filter((r) => r.tier === 'canMakeNow').map((r) => r.recipe.id);
  assert.ok(canMakeNowIds.includes('kimchi_fried_rice'));

  // Filter by main ingredient '김치'
  const kimchiOnly = recommendRecipes({
    pantryIngredients: pantry,
    ownedSeasonings: seasonings,
    allRecipes: VERIFIED_RECIPES,
    preferences: { allergens: [], dislikedIngredients: [] },
    selectedMainIngredient: '김치',
  });
  assert.ok(kimchiOnly.length > 0);
  assert.ok(kimchiOnly.every((r) => r.usesSelectedMainIngredient));

  // Filter out 'egg' allergen
  const eggAllergyRecs = recommendRecipes({
    pantryIngredients: pantry,
    ownedSeasonings: seasonings,
    allRecipes: VERIFIED_RECIPES,
    preferences: { allergens: ['egg'], dislikedIngredients: [] },
  });
  assert.ok(!eggAllergyRecs.some((r) => r.recipe.id === 'kimchi_fried_rice'));
});

test('AiResponseValidator validates JSON schema, strips non-food items, and parses zones', () => {
  const rawJson = JSON.stringify({
    zonesScanned: ['상단 선반', '문짝 포켓'],
    ingredients: [
      {
        name: '풀무원 국산콩 두부',
        category: 'processed',
        confidence: 'medium',
        uncertaintyNote: '포장 모서리 일부 가려짐',
      },
      {
        name: '투명 비닐봉지',
        category: 'other',
        confidence: 'low',
        isFood: false,
      },
    ],
  });

  const parsed = AiResponseValidator.validateAndParse(rawJson);
  assert.equal(parsed.recognizedIngredients.length, 1);
  assert.equal(parsed.recognizedIngredients[0].name, '두부');
  assert.equal(parsed.recognizedIngredients[0].confidence, 'medium');
  assert.equal(parsed.recognizedIngredients[0].isVerified, false);
  assert.ok(parsed.excludedNonFoodItems.includes('투명 비닐봉지'));
  assert.deepEqual(parsed.scannedZones, ['상단 선반', '문짝 포켓']);
});
