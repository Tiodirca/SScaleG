import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdfLib;

import '../textos.dart';
import 'salvarPDF/SavePDFWeb.dart'
    if (dart.library.html) 'salvarPDF/SavePDFWeb.dart';

class GerarPDFEscala {
  static List<String> listaLegenda = [];
  List<Map> escala;
  String nomeEscala;

  GerarPDFEscala({required this.escala, required this.nomeEscala});

  pegarDados() {
    // listaLegenda.addAll([Textos.labelData]);
    // if (exibirMesaApoio) {
    //   listaLegenda.addAll([Textos.labelMesaApoio]);
    // }
    // if (exibirMesaApoio == false) {
    //   listaLegenda.addAll([
    //     Textos.labelPrimeiroHoraPulpito,
    //   ]);
    // }
    // listaLegenda.addAll([
    //   Textos.labelPrimeiroHoraEntrada,
    // ]);
    //
    // if (exibirUniformes) {
    //   listaLegenda.addAll([
    //     Textos.labelUniforme,
    //   ]);
    // }
    // listaLegenda.addAll([Textos.labelHorario]);
    // if (exibirServirSantaCeia) {
    //   listaLegenda.add(Textos.labelServirSantaCeia);
    // } else {
    //   listaLegenda.add("");
    // }
    // if (exibirIrmaoReserva && exibirRecolherOferta) {
    //   listaLegenda
    //       .addAll([Textos.labelRecolherOferta, Textos.labelIrmaoReserva]);
    // } else if (exibirRecolherOferta) {
    //   listaLegenda.add(Textos.labelRecolherOferta);
    // } else if (exibirRecolherOferta == false && exibirIrmaoReserva) {
    //   listaLegenda.addAll(["", Textos.labelIrmaoReserva]);
    // }
    gerarPDF();
  }

  gerarPDF() async {
    final pdfLib.Document pdf = pdfLib.Document();
    //definindo que a variavel vai receber o caminho da
    // imagem para serem exibidas
    final image =
        (await rootBundle.load(
          'assets/imagens/logo_nova_adtl_psc.png',
        )).buffer.asUint8List();
    //adicionando a pagina ao pdf
    pdf.addPage(
      pdfLib.MultiPage(
        //definindo formato
        margin: const pdfLib.EdgeInsets.only(
          left: 5,
          top: 5,
          right: 5,
          bottom: 10,
        ),
        //CABECALHO DO PDF
        header:
            (context) => pdfLib.Column(
              children: [
                pdfLib.Container(
                  alignment: pdfLib.Alignment.centerRight,
                  child: pdfLib.Column(
                    children: [
                      pdfLib.Image(
                        pdfLib.MemoryImage(image),
                        width: 60,
                        height: 60,
                      ),
                    ],
                  ),
                ),
                pdfLib.SizedBox(height: 5),
                pdfLib.Text(
                  Textos.txtCabecalhoPDF,
                  textAlign: pdfLib.TextAlign.center,
                ),
              ],
            ),
        //RODAPE DO PDF
        footer:
            (context) => pdfLib.Column(
              children: [
                pdfLib.Container(
                  child: pdfLib.Column(
                    mainAxisAlignment: pdfLib.MainAxisAlignment.spaceBetween,
                    children: [
                      pdfLib.Text(
                        Textos.txtRodapePDF,
                        textAlign: pdfLib.TextAlign.center,
                      ),
                    ],
                  ),
                ),
                pdfLib.Container(
                  padding: const pdfLib.EdgeInsets.only(
                    left: 0.0,
                    top: 10.0,
                    bottom: 0.0,
                    right: 0.0,
                  ),
                  alignment: pdfLib.Alignment.centerRight,
                  child: pdfLib.Container(
                    alignment: pdfLib.Alignment.centerRight,
                    child: pdfLib.Row(
                      mainAxisAlignment: pdfLib.MainAxisAlignment.end,
                      children: [],
                    ),
                  ),
                ),
              ],
            ),
        pageFormat: PdfPageFormat.a4,

        orientation: pdfLib.PageOrientation.portrait,
        //CORPO DO PDF
        build:
            (context) => [
              pdfLib.SizedBox(height: 20),
              pdfLib.TableHelper.fromTextArray(
                cellPadding: pdfLib.EdgeInsets.symmetric(
                  horizontal: 0.0,
                  vertical: 5.0,
                ),
                headerPadding: pdfLib.EdgeInsets.symmetric(
                  horizontal: 0.0,
                  vertical: 1.0,
                ),
                cellAlignment: pdfLib.Alignment.center,
                data: listagemDados(),
              ),
              pdfLib.Container(
                margin: pdfLib.EdgeInsets.all(10.0),
                child: pdfLib.Text(
                  "Textos.descricaoObsPDFConversa",
                  textAlign: pdfLib.TextAlign.center,
                  style: pdfLib.TextStyle(fontWeight: pdfLib.FontWeight.bold),
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

  listagemDados() {
    // if (exibirMesaApoio && exibirUniformes == true) {
    //   return <List<String>>[
    //     listaLegenda,
    //     ...escala.map((e) {
    //       return [
    //         e.dataCulto,
    //         e.mesaApoio,
    //         e.primeiraHoraEntrada,
    //         e.uniforme,
    //         e.horarioTroca,
    //         e.servirSantaCeia,
    //         e.recolherOferta,
    //         e.irmaoReserva
    //       ];
    //     }),
    //   ];
    // } else if (exibirMesaApoio == false && exibirUniformes == true) {
    //   return <List<String>>[
    //     listaLegenda,
    //     ...escala.map((e) => [
    //           e.dataCulto,
    //           e.primeiraHoraPulpito,
    //           e.primeiraHoraEntrada,
    //           e.uniforme,
    //           e.horarioTroca,
    //           e.servirSantaCeia,
    //           e.recolherOferta,
    //           e.irmaoReserva
    //         ])
    //   ];
    // }
    // if (exibirMesaApoio && exibirUniformes == false) {
    //   return <List<String>>[
    //     listaLegenda,
    //     ...escala.map((e) {
    //       return [
    //         e.dataCulto,
    //         e.mesaApoio,
    //         e.primeiraHoraEntrada,
    //         e.horarioTroca,
    //         e.servirSantaCeia,
    //         e.recolherOferta,
    //         e.irmaoReserva
    //       ];
    //     }),
    //   ];
    // } else if (exibirMesaApoio == false && exibirUniformes == false) {
    //   return <List<String>>[
    //     listaLegenda,
    //     ...escala.map((e) => [
    //           e.dataCulto,
    //           e.primeiraHoraPulpito,
    //           e.primeiraHoraEntrada,
    //           e.horarioTroca,
    //           e.servirSantaCeia,
    //           e.recolherOferta,
    //           e.irmaoReserva
    //         ])
    //   ];
    // }
  }
}
