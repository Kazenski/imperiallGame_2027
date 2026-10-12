# Ferramentas — produção de assets

Tudo que você precisa para **criar, editar e exportar** imagens, objetos, animações e sons do jogo.
Priorizei opções **gratuitas** e marquei com 💰 as pagas.

---

## 1. Ambiente de desenvolvimento (para rodar o app completo)

| Ferramenta | Para quê | Onde |
|---|---|---|
| **Flutter SDK 3.47+** | Compilar o app | <https://docs.flutter.dev/get-started/install> |
| **Android Studio** | Emulador Android + SDK + `adb` | <https://developer.android.com/studio> |
| **VS Code + extensões Flutter/Dart** | Editar código | <https://code.visualstudio.com> |
| **Git + GitHub CLI** | Versionamento e deploy | <https://cli.github.com> |
| **Supabase CLI** | Migrações e testes locais do backend | <https://supabase.com/docs/guides/cli> |

> Atalho: `flutter doctor` diz exatamente o que falta na sua máquina.

---

## 2. Arte 2D — personagem, UI, ícones

### Criação (raster)

| Ferramenta | Preço | Melhor para |
|---|---|---|
| **Krita** | Grátis | Pintura digital, arte do personagem. Excelente suporte a *layers*. |
| **GIMP** | Grátis | Edição/exportação rápida, redimensionar sprites, gerar `.webp`. |
| **Photopea** | Grátis (web) | Abre `.psd` no navegador sem instalar nada. |
| **Aseprite** | 💰 ~US$20 | **Padrão-ouro para pixel art** e sprites animados (exporta sprite sheet + GIF). |
| **LibreSprite** | Grátis | Fork livre do Aseprite. |
| **Piskel** | Grátis (web) | Pixel art simples direto no navegador. |
| **Inkscape** | Grátis | Vetores: ícones, HUD, molduras, badges. Escala sem perder qualidade. |
| **Adobe Illustrator** | 💰 | Vetores profissionais, se você já tem o pacote. |

### IA generativa (conceito e base)

| Ferramenta | Uso |
|---|---|
| **Gemini / ChatGPT / Copilot** | Gerar *concepts* de personagem, equipamentos e cenários. Você já usa bastante! |
| **Stable Diffusion (Automatic1111 / ComfyUI)** | Local, grátis, controle total, LoRA de estilo. Requer GPU. |
| **remove.bg / Photoroom** | Remover fundo de uma arte gerada → PNG transparente para camada. |

> **Fluxo recomendado:** IA gera o *concept* → você refina no Krita/Inkscape →
> exporta PNG transparente → o app compõe em camadas (ver `GAME_DESIGN.md §10`).

### Regras de exportação para o app

| Asset | Formato | Tamanho sugerido | Observação |
|---|---|---|---|
| Avatar (corpo) | PNG transparente | 512×512 @1x, @2x, @3x | `assets/images/avatar/body_tier{n}.png` |
| Equipamento | PNG transparente | 512×512 | Alinhado ao corpo (mesmo *pivot*) |
| Ícones de UI | SVG (preferir) ou PNG 24/48/96 | — | Vetor usa `flutter_svg` |
| Ícone do app | PNG | 1024×1024 | Gerar todos os tamanhos com `flutter_launcher_icons` |
| Fundo de tela | WebP (qualidade 80) | 1080×2400 | WebP reduz ~70% vs PNG |
| Sprite animado | Sprite sheet PNG | — | Use `flame` se animar |

**Ferramenta de otimização:** [Squoosh](https://squoosh.app) (grátis, web) converte para WebP/AVIF.

---

## 3. Animação e assets animados

| Ferramenta | Uso |
|---|---|
| **Aseprite** | Animar sprites quadro a quadro, exportar sprite sheet. |
| **Rive** | Animações vetoriais interativas (avatar que reage, transições). SDK Flutter oficial. Roda leve. |
| **Lottie / LottieFiles** | Animações vetoriais prontas (efeitos, confetes, level-up). Pacote `lottie` no Flutter. |
| **Flutter nativo** | Animações de UI com `AnimationController`/`TweenAnimationBuilder` — zero asset extra. |

**Recomendação:** comece com **Flutter nativo** (efeitos de XP, level-up) + **Rive** para o avatar.
Só use sprite sheet/Aseprite se quiser pixel art tradicional.

---

## 4. Áudio e música

| Ferramenta | Preço | Uso |
|---|---|---|
| **Audacity** | Grátis | Editar/cortar/normalizar efeitos sonoros. |
| **LMMS** | Grátis | Criar trilhas musicais (estilo DAW). |
| **Bosca Ceoil** | Grátis | Chiptune/8-bit rápido. |
| **freesound.org** | Grátis (CC) | Biblioteca de efeitos prontos. |
| **ElevenLabs / Suno / Udio** | 💰/freemium | Voz e música por IA. |
| **ffmpeg** | Grátis | Converter tudo para **OGG Vorbis** (menor e suportado em Android/iOS). |

Formato de saída: **`.ogg`** para efeitos, **`.ogg`** ou `.mp3` para música longa.
Coloque em `assets/audio/` e registre no `pubspec.yaml`.

---

## 5. Fontes e tipografia

| Fonte | Estilo | Uso |
|---|---|---|
| **Cinzel** | Serif medieval | Títulos, nome do nível |
| **Rajdhani / Orbitron** | Tech/geométrica | Números de XP, HUD |
| **Inter / Rubik** | Sans legível | Corpo de texto |
| **Press Start 2P** | Pixel | Se optar por pixel art |

Baixe em [Google Fonts](https://fonts.google.com) (grátis, licença aberta) e coloque em `assets/fonts/`.
Registre em `pubspec.yaml` → `fonts:`.

---

## 6. Design de UI/UX e prototipagem

| Ferramenta | Uso |
|---|---|
| **Figma** (grátis) | Prototipar telas, paleta, biblioteca de componentes. **Recomendado.** |
| **Penpot** (grátis, open source) | Alternativa ao Figma. |
| **Excalidraw** (grátis) | Wireframes rápidos à mão. |
| **Coolors** (grátis) | Gerar/validar paletas com contraste acessível. |
| **Realtime Colors** | Testar paleta em um layout real na hora. |

Paletas e mockups vão em `design/concept/`.

---

## 7. 3D (opcional, só se quiser profundidade)

| Ferramenta | Uso |
|---|---|
| **Blender** (grátis) | Modelar/renderizar. Pode gerar *renders 2D* do personagem. |
| **Spline** (freemium) | 3D leve para web/app, exporta para Flutter. |
| **Kenney.nl** (grátis) | Pacotes de assets 3D e 2D prontos, domínio público. |

> Para um app de fitness, **2D em camadas é mais que suficiente**. 3D encarece muito o pipeline.

---

## 8. Pipelines e automação de assets

| Ferramenta | Uso |
|---|---|
| **flutter_launcher_icons** | Gera todos os ícones do app a partir de um PNG 1024. |
| **flutter_native_splash** | Gera a splash screen. |
| **flutter_svg** | Renderiza ícones vetoriais. |
| **image** (Dart pkg) | Processar imagens em build. |
| **Squoosh CLI / Sharp** | Conversão em lote para WebP. |

---

## 9. Kit inicial sugerido (tudo grátis)

```text
 1. Flutter + Android Studio ......... roda o app
 2. VS Code + extensões .............. edita código
 3. Krita ............................ pinta o personagem
 4. Inkscape ......................... ícones e HUD em vetor
 5. Photopea (web) ................... edita .psd sem instalar
 6. Figma ............................ prototipa as telas
 7. Squoosh (web) .................... otimiza imagens para WebP
 8. Audacity + freesound ............. efeitos sonoros
 9. Google Fonts ..................... tipografia
10. Rive ............................. animação do avatar
```

Com esse kit você produz **todo** o app sem gastar nada. Só o Aseprite (💰) é um luxo
opcional para pixel art.

---

## 10. Estrutura de pastas de assets

```text
assets/
├── images/
│   ├── avatar/       body_tier1.png ... body_tier4.png
│   ├── gear/         weapon_*.png, armor_*.png
│   ├── icons/        *.svg
│   └── backgrounds/  *.webp
├── audio/
│   ├── sfx/          level_up.ogg, coin.ogg
│   └── music/        theme.ogg
└── fonts/
    ├── Cinzel-Bold.ttf
    └── Rajdhani-SemiBold.ttf
```

Após adicionar um asset, declare no `pubspec.yaml` e rode `flutter pub get`.
