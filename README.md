# flowmova-frontend

Frontend Flutter de la plateforme FlowMova.

## Prerequis

- Flutter SDK installe.
- Backend FlowMova disponible localement pour les appels API.

Dans cet environnement Windows, le SDK Flutter utilise par le projet est:

```powershell
C:\flutter-sdk\flutter\bin\flutter.bat
```

## Configuration API

L'URL backend est centralisee dans `lib/src/core/config/app_environment.dart`.

Valeur locale par defaut:

```text
http://localhost:8080
```

Pour cibler une autre API, utiliser `--dart-define`:

```powershell
C:\flutter-sdk\flutter\bin\flutter.bat run -d chrome --dart-define=FLOWMOVA_API_BASE_URL=http://localhost:8080
```

Exemple prod futur:

```powershell
C:\flutter-sdk\flutter\bin\flutter.bat build web --dart-define=FLOWMOVA_API_BASE_URL=https://api.flowmova.example
```

Swagger backend local:

```text
http://localhost:8080/swagger-ui/index.html
```

## Documentation

- Brand guidelines MVP: [docs/brand/flowmova-brand-guidelines.md](docs/brand/flowmova-brand-guidelines.md)
- Frontend MVP backlog: [docs/frontend/frontend-mvp-backlog.md](docs/frontend/frontend-mvp-backlog.md)
