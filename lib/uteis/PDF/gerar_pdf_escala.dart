import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdflib;

import '../textos.dart';
import 'salvarPDF/save_pdf_web.dart'
    if (dart.library.html) 'salvarPDF/SavePDFWeb.dart';

class GerarPDFEscala {
  List<dynamic> listaLegenda = [];
  List<dynamic> _chavesOrdenadas = [];
  List escala;
  int valorOrientacaoPagina;
  String nomeEscala;
  String nomeCabecalho;
  List<String> observacoes;
  String cor;
  XFile? imagemLogo;

  GerarPDFEscala({
    required this.escala,
    required this.nomeEscala,
    required this.nomeCabecalho,
    required this.imagemLogo,
    required this.observacoes,
    required this.cor,
    required this.valorOrientacaoPagina,
  });

  pegarDados() async {
    listaLegenda = [];
    _chavesOrdenadas = [];

    if (escala.isNotEmpty) {
      _chavesOrdenadas = escala.first.keys.toList();
      for (var element in _chavesOrdenadas) {
        listaLegenda.add(
          element
              .toString()
              .replaceAll("_", " ")
              .replaceAll("01 data", "data")
              .replaceAll("02 horario de Trabalho", "HORARIO DE TRABALHO")
              .toUpperCase(),
        );
      }
    }
    gerarPDF();
  }

  pdflib.Widget _construirCabecalho(pdflib.MemoryImage? image) {
    final textoCabecalho = pdflib.Text(
      nomeCabecalho,
      textAlign: pdflib.TextAlign.center,
    );

    if (image == null) {
      return pdflib.Container(
        width: double.infinity,
        alignment: pdflib.Alignment.center,
        child: textoCabecalho,
      );
    }

    // Mantém o título centralizado mesmo quando a logo está à direita
    return pdflib.Row(
      mainAxisAlignment: pdflib.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pdflib.CrossAxisAlignment.center,
      children: [
        pdflib.SizedBox(width: 40, height: 40),
        pdflib.Expanded(child: textoCabecalho),
        pdflib.SizedBox(
          width: 40,
          height: 40,
          child: pdflib.Image(image, width: 40, height: 40),
        ),
      ],
    );
  }

  gerarPDF() async {
    final pdflib.Document pdf = pdflib.Document();
    pdflib.MemoryImage? image;
    if (imagemLogo != null) {
      image = pdflib.MemoryImage(File(imagemLogo!.path).readAsBytesSync());
    }

    pdf.addPage(
      pdflib.MultiPage(
        margin: const pdflib.EdgeInsets.only(
          left: 5,
          top: 5,
          right: 5,
          bottom: 10,
        ),
        header: (context) => _construirCabecalho(image),
        footer:
            (context) => pdflib.Container(
              width: 1000,
              child: pdflib.Text(
                Textos.txtRodapePDF,
                textAlign: pdflib.TextAlign.center,
              ),
            ),
        pageFormat: validarOrientacaoPaginaGeral(),
        orientation: validarOrientacaoPagina(),
        build:
            (context) => [
              pdflib.SizedBox(height: 10),
              pdflib.TableHelper.fromTextArray(
                cellPadding: pdflib.EdgeInsets.symmetric(
                  horizontal: 0.0,
                  vertical: 1.0,
                ),
                cellDecoration: (index, data, rowNum) {
                  return pdflib.BoxDecoration(color: PdfColor.fromHex(cor));
                },
                headerDecoration: pdflib.BoxDecoration(
                  color: PdfColor.fromHex(cor),
                ),
                headerPadding: pdflib.EdgeInsets.symmetric(
                  horizontal: 1.0,
                  vertical: 1.0,
                ),
                columnWidths: {
                  0: pdflib.IntrinsicColumnWidth(),
                  1: pdflib.IntrinsicColumnWidth(),
                },
                headerStyle: pdflib.TextStyle(
                  fontWeight: pdflib.FontWeight.bold,
                  fontSize: 10,
                ),
                cellAlignment: pdflib.Alignment.center,
                data: listagemDados(),
              ),
              pdflib.LayoutBuilder(
                builder: (context, constraints) {
                  if (observacoes.isNotEmpty) {
                    return pdflib.Container(
                      width: 1000,
                      child: pdflib.Text(
                        Textos.observacaoTitulo,
                        style: pdflib.TextStyle(
                          fontSize: 12,
                          fontWeight: pdflib.FontWeight.bold,
                        ),
                        textAlign: pdflib.TextAlign.center,
                      ),
                    );
                  } else {
                    return pdflib.Container();
                  }
                },
              ),
              pdflib.Container(
                width: 1000,
                margin: pdflib.EdgeInsets.all(10.0),
                child: pdflib.ListView.builder(
                  itemCount: observacoes.length,
                  itemBuilder: (context, index) {
                    return pdflib.Text(
                      observacoes.elementAt(index),
                      textAlign: pdflib.TextAlign.center,
                      style: pdflib.TextStyle(
                        fontSize: 11,
                        fontWeight: pdflib.FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ],
      ),
    );
    List<int> bytes = await pdf.save();
    salvarPDF(bytes, '$nomeEscala.pdf');
    escala = [];
    listaLegenda = [];
    _chavesOrdenadas = [];
  }

  validarOrientacaoPagina() {
    if (valorOrientacaoPagina == 0) {
      return pdflib.PageOrientation.landscape;
    } else {
      return pdflib.PageOrientation.portrait;
    }
  }

  validarOrientacaoPaginaGeral() {
    if (valorOrientacaoPagina == 0) {
      return PdfPageFormat.a4.landscape;
    } else {
      return PdfPageFormat.a4.portrait;
    }
  }

  listagemDados() {
    return <List<dynamic>>[
      listaLegenda,
      ...escala.map((linha) {
        return _chavesOrdenadas.map((chave) => linha[chave] ?? '').toList();
      }),
    ];
  }
}
