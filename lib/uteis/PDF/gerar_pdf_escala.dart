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
    List<dynamic> itens = escala.first.keys.toList();
    for (var element in itens) {
      listaLegenda.add(
        element
            .toString()
            .replaceAll("_", " ")
            .replaceAll("01", "")
            .replaceAll("02", "")
            .toUpperCase(),
      );
    }
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
            (context) => pdflib.Container(
              width: 1000,
              child: pdflib.Text(
                Textos.txtRodapePDF,
                textAlign: pdflib.TextAlign.center,
              ),
            ),
        pageFormat: PdfPageFormat.a4,

        orientation: validarOrientacaoPagina(),
        //CORPO DO PDF
        build:
            (context) => [
              //adicionando container para dar espacamento entre
              // cabecalho PDF e comeco da escala
              pdflib.SizedBox(height: 10),
              pdflib.TableHelper.fromTextArray(
                cellPadding: pdflib.EdgeInsets.symmetric(
                  horizontal: 0.0,
                  vertical: 2.0,
                ),
                headerPadding: pdflib.EdgeInsets.symmetric(
                  horizontal: 1.0,
                  vertical: 3.0,
                ),
                columnWidths: {
                  0: pdflib.IntrinsicColumnWidth(),
                  1: pdflib.IntrinsicColumnWidth(),
                },
                headerStyle: pdflib.TextStyle(
                  fontWeight: pdflib.FontWeight.bold,
                  fontSize: 11,
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
                          fontSize: 13,
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
