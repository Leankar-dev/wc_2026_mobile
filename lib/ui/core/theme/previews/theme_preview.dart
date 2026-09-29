import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/core/theme/app_colors.dart';
import 'package:wc_2026_mobile/ui/core/theme/app_theme.dart';

class const PreviewSurface({super.key, required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );
  }
}

class const PreviewDarkSurface({super.key, required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        backgroundColor: AppColors.ink,
        body: Center(child: child),
      ),
    );
  }
}

class const PreviewFieldSurface({super.key, required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PreviewSurface(child: SizedBox(width: 280, child: child));
  }
}

class const _ButtonBox({required final Widget child}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 220, height: 52, child: child);
  }
}

Widget previewSurface(Widget child) => PreviewSurface(child: child);

Widget previewDarkSurface(Widget child) => PreviewDarkSurface(child: child);

Widget previewFieldSurface(Widget child) => PreviewFieldSurface(child: child);

@Preview(
  group: 'Botões',
  name: 'Primary - CTA',
  size: Size(280, 120),
  wrapper: previewSurface,
)
Widget previewPrimaryButton() {
  return _ButtonBox(
    child: FilledButton(onPressed: () {}, child: const Text('CTA PRINCIPAL')),
  );
}

@Preview(
  group: 'Botões',
  name: 'Dark',
  size: Size(280, 120),
  wrapper: previewSurface,
)
Widget previewDarkButton() => _ButtonBox(
  child: FilledButton(
    style: AppTheme.darkButton,
    onPressed: () {},
    child: const Text('ESCURO'),
  ),
);

@Preview(
  group: 'Botões',
  name: 'Danger',
  size: Size(280, 120),
  wrapper: previewSurface,
)
Widget previewDangerButton() => _ButtonBox(
  child: FilledButton(
    style: AppTheme.dangerButton,
    onPressed: () {},
    child: const Text('NÃO TENHO'),
  ),
);

@Preview(
  group: 'Botões',
  name: 'Secondary',
  size: Size(280, 120),
  wrapper: previewSurface,
)
Widget previewSecondaryButton() => _ButtonBox(
  child: FilledButton(
    style: AppTheme.secondaryButton,
    onPressed: () {},
    child: const Text('SECUNDÁRIO'),
  ),
);

@Preview(
  group: 'Botões',
  name: 'Danger outline',
  size: Size(280, 120),
  wrapper: previewSurface,
)
Widget previewDangerOutlineButton() => _ButtonBox(
  child: FilledButton(
    style: AppTheme.dangerOutlineButton,
    onPressed: () {},
    child: const Text('SAIR DA CONTA'),
  ),
);

@Preview(
  group: 'Botões',
  name: 'Ghost',
  size: Size(280, 120),
  wrapper: previewDarkSurface,
)
Widget previewGhostButton() => _ButtonBox(
  child: FilledButton(
    style: AppTheme.ghostButton,
    onPressed: () {},
    child: const Text('FANTASMA'),
  ),
);

@Preview(
  group: 'Botões',
  name: 'Danger ghost',
  size: Size(280, 120),
  wrapper: previewDarkSurface,
)
Widget previewDangerGhostButton() => _ButtonBox(
  child: FilledButton(
    style: AppTheme.dangerGhostButton,
    onPressed: () {},
    child: const Text('SAIR'),
  ),
);

@Preview(
  group: 'Botões',
  name: 'Disabled',
  size: Size(280, 120),
  wrapper: previewSurface,
)
Widget previewDisabledButton() => const _ButtonBox(
  child: FilledButton(onPressed: null, child: Text('DESABILITADO')),
);

@Preview(
  group: 'Campos',
  name: 'Todos os estados',
  size: Size(340, 460),
  wrapper: previewFieldSurface,
)
Widget previewAllFields() => Column(
  mainAxisSize: MainAxisSize.min,
  spacing: 16,
  children: [
    TextFormField(initialValue: 'Leandro Silva'),
    TextFormField(
      decoration: const InputDecoration(hintText: 'voce@exemplo.com'),
    ),
    TextFormField(
      initialValue: '',
      autovalidateMode: AutovalidateMode.always,
      validator: (_) => 'Erro de campo obrigatorio',
    ),
    TextFormField(decoration: AppTheme.searchInput),
  ],
);
