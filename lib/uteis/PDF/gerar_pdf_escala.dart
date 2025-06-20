import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdflib;

import '../textos.dart';
import 'salvarPDF/save_pdf_web.dart'
    if (dart.library.html) 'salvarPDF/SavePDFWeb.dart';

class GerarPDFEscala {
  List<dynamic> listaLegenda = [];
  List<Map> escala;
  int valorOrientacaoPagina;
  String nomeEscala;
  String nomeCabecalho;
  List<String> observacoes;
  XFile? imagemLogo;

  GerarPDFEscala({
    required this.escala,
    required this.nomeEscala,
    required this.nomeCabecalho,
    required this.imagemLogo,
    required this.observacoes,
    required this.valorOrientacaoPagina,
  });

  pegarDados() async {
    listaLegenda = escala.first.keys.toList();
    gerarPDF();
  }

  gerarPDF() async {
    final pdflib.Document pdf = pdflib.Document();
    //definindo que a variavel vai receber o caminho da
    // imagem para serem exibidas
    final image = pdflib.MemoryImage(File(imagemLogo!.path).readAsBytesSync());
    //adicionando a pagina ao pdf
    pdf.addPage(
      pdflib.MultiPage(
        //definindo formato
        margin: const pdflib.EdgeInsets.only(
          left: 5,
          top: 5,
          right: 5,
          bottom: 10,
        ),
        //CABECALHO DO PDF
        header:
            (context) => pdflib.Column(
              children: [
                pdflib.Container(
                  alignment: pdflib.Alignment.centerRight,
                  child: pdflib.Column(
                    children: [pdflib.Image(image, width: 60, height: 60)],
                  ),
                ),
                pdflib.SizedBox(height: 5),
                pdflib.Text(nomeCabecalho, textAlign: pdflib.TextAlign.center),
              ],
            ),
        //RODAPE DO PDF
        footer:
            (context) => pdflib.Column(
              children: [
                pdflib.Container(
                  child: pdflib.Column(
                    mainAxisAlignment: pdflib.MainAxisAlignment.spaceBetween,
                    children: [
                      pdflib.Text(
                        Textos.txtRodapePDF,
                        textAlign: pdflib.TextAlign.center,
                      ),
                    ],
                  ),
                ),
                pdflib.Container(
                  padding: const pdflib.EdgeInsets.only(
                    left: 0.0,
                    top: 10.0,
                    bottom: 0.0,
                    right: 0.0,
                  ),
                  alignment: pdflib.Alignment.centerRight,
                  child: pdflib.Container(
                    alignment: pdflib.Alignment.centerRight,
                    child: pdflib.Row(
                      mainAxisAlignment: pdflib.MainAxisAlignment.end,
                      children: [],
                    ),
                  ),
                ),
              ],
            ),
        pageFormat: PdfPageFormat.a4,

        orientation: validarOrientacaoPagina(),
        //CORPO DO PDF
        build:
            (context) => [
              pdflib.SizedBox(height: 20),
              pdflib.TableHelper.fromTextArray(
                cellPadding: pdflib.EdgeInsets.symmetric(
                  horizontal: 0.0,
                  vertical: 5.0,
                ),
                headerPadding: pdflib.EdgeInsets.symmetric(
                  horizontal: 0.0,
                  vertical: 1.0,
                ),
                cellAlignment: pdflib.Alignment.center,
                data: listagemDados(),
              ),
              pdflib.LayoutBuilder(
                builder: (context, constraints) {
                  if (observacoes.isNotEmpty) {
                    return pdflib.Container(
                      color: PdfColors.green,
                      margin: pdflib.EdgeInsets.all(10.0),
                      child: pdflib.Text(
                        Textos.observacaoTitulo,
                        textAlign: pdflib.TextAlign.center,
                      ),
                    );
                  } else {
                    return pdflib.Container();
                  }
                },
              ),
              pdflib.Container(
                margin: pdflib.EdgeInsets.all(10.0),
                child: pdflib.ListView.builder(
                  itemCount: observacoes.length,
                  itemBuilder: (context, index) {
                    return pdflib.Text(
                      observacoes.elementAt(index),
                      textAlign: pdflib.TextAlign.center,
                      style: pdflib.TextStyle(
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
  }

  validarOrientacaoPagina() {
    //se for 0 é horizontal
    if (valorOrientacaoPagina == 0) {
      return pdflib.PageOrientation.landscape;
    } else {
      return pdflib.PageOrientation.portrait;
    }
  }

  listagemDados() {
    int index = -1;
    return <List<dynamic>>[
      listaLegenda,
      ...escala.map((e) {
        index++;
        return escala.elementAt(index).values.toList();
      }),
    ];
  }
}
