# Como testar feature nova sem tocar no APK de produção

> Conceito: nunca teste na produção. Gere um **APK de teste** (variante `dev`)
> com `applicationId` diferente — ele instala **lado a lado** com o app oficial.

## 1. Variantes (flavors) no Flutter

No `android/app/build.gradle.kts`, dentro de `android { ... }`:

```kotlin
flavorDimensions += "ambiente"

productFlavors {
    create("dev") {
        dimension = "ambiente"
        applicationIdSuffix = ".dev"
        versionNameSuffix = "-dev"
    }
    create("prod") {
        dimension = "ambiente"
    }
}
```

Resultado:

| Variante | applicationId | Instala junto? |
|---|---|---|
| `dev` | `com.seuapp.dev` | Sim, ícone separado |
| `prod` | `com.seuapp` | É o oficial |

## 2. Gerar o APK de teste local

```bash
# APK dev (debug, rápido — para testar no seu celular via USB)
flutter run --flavor dev --dart-define=APP_ENV=dev --dart-define=DEMO_MODE=true

# APK dev instalável (release local, assinado com chave debug)
flutter build apk --flavor dev --dart-define=APP_ENV=dev
```

O arquivo sai em `build/app/outputs/flutter-apk/app-dev-release.apk`.

## 3. Gerar o APK de teste pelo GitHub (sem precisar de PC)

No workflow de release (`.github/workflows/release.yml`), garanta a entrada
manual:

```yaml
on:
  workflow_dispatch:
    inputs:
      variant:
        description: 'Variante (dev ou prod)'
        required: false
        default: 'dev'
```

Disparo por botão ou CLI:

```bash
# Via site: Actions > Release > Run workflow > variant: dev
# Via CLI:
gh workflow run release.yml -f variant=dev
```

Baixe o APK em **Actions > run > Artifacts** (`imperiall-game-dev.apk`).

## 4. Backend de teste (não sujar a produção)

O APK dev deve apontar para dados de teste. Opções, da mais simples à ideal:

1. `DEMO_MODE=true` — sem backend, dados mockados.
2. Projeto Supabase **staging** separado (recomendado quando houver login):
   `--dart-define=SUPABASE_URL=<url-staging>`.
3. Prefixo nas tabelas/contas de teste (ex.: usuário `qa_*`).

Regra: **APK dev nunca escreve no banco de produção.**

## 5. Distribuir para testadores (opcional, grátis)

- **Firebase App Distribution**: suba o APK dev, testadores recebem link
  de instalação. Ideal quando mais gente testa.
- Sem Firebase: envie o arquivo do Artifacts diretamente.

## 6. Promover para produção (só depois do teste OK)

```bash
git tag v0.3.0
git push origin v0.3.0
# workflow gera o APK prod assinado (applicationId oficial)
```

## Checklist rápido

- [ ] Feature pronta em branch separada (`feat/...`)?
- [ ] APK dev gerado e instalado lado a lado?
- [ ] Testado contra backend de teste/staging?
- [ ] Sem segredo vazado no código (`git grep service_role`)?
- [ ] `flutter analyze` + `flutter test` verdes?
- [ ] Só então: merge + tag + release prod.
