
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SeletorCor extends StatefulWidget {
  final String corInicial;
  final Function(String) onColorSelected;

  const SeletorCor({
    super.key,
    this.corInicial = '#1976D2',
    required this.onColorSelected,
  });

  @override
  State<SeletorCor> createState() => _SeletorCorState();
}

class _SeletorCorState extends State<SeletorCor> {
  late Color corSelecionada;

  @override
  void initState() {
    super.initState();
    corSelecionada = _hexToColor(widget.corInicial);
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  String _colorToHex(Color color) {
    return '#${(color.value & 0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0')
        .toUpperCase()}';
  }

  void _abrirSeletor() {
    Color corTemporaria = corSelecionada;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecionar cor'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: corSelecionada,
              onColorChanged: (color) {
                corTemporaria = color;
              },
              enableAlpha: false,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  corSelecionada = corTemporaria;
                });

                widget.onColorSelected(
                  _colorToHex(corSelecionada),
                );

                Navigator.pop(context);
              },
              child: const Text('Selecionar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hex = _colorToHex(corSelecionada);

    return Card(
      child: InkWell(
        onTap: _abrirSeletor,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: corSelecionada,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cor selecionada',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      hex,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.color_lens_outlined),
            ],
          ),
        ),
      ),
    );
  }
}
