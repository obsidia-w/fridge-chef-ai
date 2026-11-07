import { defineConfig, type Plugin } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import { GoogleGenAI, Type } from '@google/genai';
import type { IncomingMessage, ServerResponse } from 'node:http';

const SYSTEM_PROMPT = `
당신은 한국 가정집 냉장고 및 주방 식재료 정밀 비전(Vision) + 한글 OCR 판독 전문 AI입니다.
사진 속 식재료 인식률을 극대화하기 위해 반드시 아래 [4단계 공간 분할 및 한글 OCR 스캔 절차]를 수행하세요:

[1단계: 4구역 공간 분할 스캔 (Spatial Grid Scanning)]
사진을 한 번에 뭉뚱그려 보지 말고 다음 구역별로 구석구석 스캔하여 작은 재료나 안쪽 재료도 빠짐없이 찾으세요:
- 구역 A (상단/중단 선반): 투명 반찬통 내부 내용물(김치, 멸치, 나물, 장류), 두부 팩, 계란 트레이, 즉석밥, 가공식품(스팸, 참치캔, 어묵, 소시지, 치즈, 버터)
- 구역 B (하단 채소실/서랍): 비닐이나 망에 들어 있는 채소류(대파, 양파, 마늘, 고추, 감자, 당근, 애호박, 양배추, 버섯류, 파프리카, 오이, 상추, 깻잎)
- 구역 C (정육/신선 코너): 포장 육류(삼겹살, 돼지고기 목살/다짐육, 소고기, 닭고기, 베이컨) 및 해산물(새우, 오징어, 고등어)
- 구역 D (냉장고 문짝 포켓): 우유, 요거트, 계란, 간장, 고추장, 된장, 케첩, 마요네즈, 굴소스, 참기름, 식용유 등 병/튜브/팩 제품

[2단계: 한글 포장지/라벨 OCR 판독]
- 포장지, 병 라벨, 두부/우유/어묵/햄/소스 용기에 적힌 한글 텍스트(예: "풀무원 두부", "서울우유", "진간장", "청양고추", "부산어묵", "스팸")를 읽고 ocrLabel 필드에 기록한 뒤, name에는 브랜드명을 뺀 한국어 표준 식재료명(예: "두부", "우유", "간장", "고추", "어묵", "스팸/통조림햄")을 적으세요.

[3단계: 비식품 분리 및 불확실성 정직 표기]
- 빈 반찬통, 비닐봉지 자체, 선반, 냄비, 그릇, 아이스팩 등 식품이 아닌 물체는 isFood: false로 분류하세요.
- 불투명 용기나 검은 비닐에 가려져 내용물이 100% 확실하지 않은 경우 추측을 확정 사실로 쓰지 말고 confidence를 "medium" 또는 "low"로 설정한 뒤 uncertaintyNote에 구체적 이유(예: "반투명 용기 안의 붉은 양념 반찬으로 김치인지 확인 필요")를 작성하세요.
- 이미지에서 알 수 없는 수량, 중량, 유통기한은 절대 임의로 생성하지 마세요.
`;

function geminiScannerApiPlugin(): Plugin {
  const handleApiRequest = async (
    req: IncomingMessage,
    res: ServerResponse,
    next: () => void
  ) => {
    if (req.url !== '/api/scan' || req.method !== 'POST') {
      return next();
    }

    let rawBody = '';
    req.on('data', (chunk) => {
      rawBody += chunk.toString();
    });

    req.on('end', async () => {
      try {
        const body = JSON.parse(rawBody || '{}');
        const { imageBytesBase64, mimeType = 'image/jpeg' } = body;

        if (!imageBytesBase64) {
          res.statusCode = 400;
          res.setHeader('Content-Type', 'application/json');
          res.end(
            JSON.stringify({
              error: '촬영된 이미지 데이터가 비어 있습니다. 다시 촬영해 주세요.',
            })
          );
          return;
        }

        const apiKey = process.env.GEMINI_API_KEY;
        if (!apiKey) {
          res.statusCode = 500;
          res.setHeader('Content-Type', 'application/json');
          res.end(
            JSON.stringify({
              error:
                '서버에 GEMINI_API_KEY가 설정되어 있지 않습니다. Settings > Secrets 패널에서 키를 확인하거나 아래의 샘플 시뮬레이션을 이용해 주세요.',
            })
          );
          return;
        }

        const ai = new GoogleGenAI({
          apiKey,
          httpOptions: {
            headers: {
              'User-Agent': 'aistudio-build',
            },
          },
        });

        const response = await ai.models.generateContent({
          model: 'gemini-3.8-flash',
          contents: {
            parts: [
              { text: SYSTEM_PROMPT },
              {
                inlineData: {
                  mimeType,
                  data: imageBytesBase64,
                },
              },
            ],
          },
          config: {
            responseMimeType: 'application/json',
            responseSchema: {
              type: Type.OBJECT,
              properties: {
                zonesScanned: {
                  type: Type.ARRAY,
                  items: { type: Type.STRING },
                },
                ingredients: {
                  type: Type.ARRAY,
                  items: {
                    type: Type.OBJECT,
                    properties: {
                      name: { type: Type.STRING },
                      ocrLabel: { type: Type.STRING },
                      detectedZone: { type: Type.STRING },
                      category: {
                        type: Type.STRING,
                        enum: [
                          'vegetable',
                          'meat',
                          'seafood',
                          'eggDairy',
                          'processed',
                          'grain',
                          'seasoning',
                          'other',
                        ],
                      },
                      confidence: {
                        type: Type.STRING,
                        enum: ['high', 'medium', 'low'],
                      },
                      isFood: { type: Type.BOOLEAN },
                      uncertaintyNote: { type: Type.STRING },
                    },
                    required: ['name', 'category', 'confidence', 'isFood'],
                  },
                },
              },
              required: ['ingredients'],
            },
          },
        });

        res.statusCode = 200;
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ text: response.text ?? '{}' }));
      } catch (err: any) {
        res.statusCode = 500;
        res.setHeader('Content-Type', 'application/json');
        res.end(
          JSON.stringify({
            error:
              err?.message ||
              'AI 서버 응답 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.',
          })
        );
      }
    });
  };

  return {
    name: 'gemini-scanner-api',
    configureServer(server) {
      server.middlewares.use(handleApiRequest);
    },
    configurePreviewServer(server) {
      server.middlewares.use(handleApiRequest);
    },
  };
}

export default defineConfig({
  plugins: [react(), tailwindcss(), geminiScannerApiPlugin()],
  server: {
    host: '0.0.0.0',
    port: 3000,
    allowedHosts: true,
  },
});
