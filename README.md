# fashio_me

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Coverage

This project supports generating coverage reports and viewing them in the browser or terminal.

Run tests with coverage:

```bash
flutter test --coverage
```

Generate the HTML report from the coverage file:

```bash
genhtml coverage/lcov.info -o coverage/html
```

Open the HTML report:

```bash
open coverage/html/index.html
```

View coverage in the terminal using the `test_cov_console` package:

```bash
dart run test_cov_console coverage/lcov.info
```

If you prefer, you can also generate the report using the existing Dart helper script:

```bash
dart run tool/generate_coverage_html.dart
```
