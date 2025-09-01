import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sscaleg/Uteis/paleta_cores.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/textos.dart';

import 'package:intl/intl.dart';

class WidgetAjustarHorario extends StatefulWidget {
  const WidgetAjustarHorario({super.key});

  @override
  State<WidgetAjustarHorario> createState() => _WidgetAjustarHorarioState();
}

class _WidgetAjustarHorarioState extends State<WidgetAjustarHorario> {
  bool exibirTrocaTurno = false;
  TimeOfDay? horarioPadrao = const TimeOfDay(hour: 19, minute: 00);
  final TextEditingController controleHorarioSemana = TextEditingController(
    text: "",
  );
  final TextEditingController controleHorarioFinalSemana =
      TextEditingController(text: "");

  final TextEditingController controleTrocaHorarioSemana =
      TextEditingController(text: "");
  final TextEditingController controleTrocaHorarioFinalSemana =
      TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    recuperarSharePreferences();
  }

  formatarHorario(String horarioRecuperado) {
    String horarioSemCaracteres = horarioRecuperado
        .replaceAll(Textos.widgetAjustarHorarioInicio, "")
        .replaceAll(Textos.widgetAjustarTrocaHorario, "")
        .replaceAll(" ", "");
    DateTime conversaoHorarioPData = DateFormat(
      "HH:mm",
    ).parse(horarioSemCaracteres);

    setState(() {
      TimeOfDay conversaoDataPTimeOfDay = TimeOfDay.fromDateTime(
        conversaoHorarioPData,
      );
      horarioPadrao = conversaoDataPTimeOfDay;
    });
  }

  Widget exibicaoHorarioDefinido(
    String label,
    TextEditingController controleHorario,
  ) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 10.0),
    width: 250,
    child: Column(
      children: [
        TextFormField(
          readOnly: true,
          controller: controleHorario,
          decoration: InputDecoration(
            label: Text(label),
            hintStyle: const TextStyle(color: PaletaCores.corAzulEscuro),
          ),
        ),
      ],
    ),
  );

  Widget botoesSwitch(String label, bool valorBotao) => SizedBox(
    width: 180,
    child: Row(
      children: [
        Text(label),
        Switch(
          inactiveThumbColor: PaletaCores.corAzulEscuro,
          value: valorBotao,
          activeColor: PaletaCores.corAzulEscuro,
          onChanged: (bool valor) {
            setState(() {
              exibirTrocaTurno = !exibirTrocaTurno;
              recuperarSharePreferences();
            });
          },
        ),
      ],
    ),
  );

  Widget botoesAcoes(
    double larguraTela,
    TextEditingController controleHorario,
    String label,
  ) => Container(
    margin: const EdgeInsets.symmetric(vertical: 20.0),
    width: larguraTela,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 50,
          width: 50,
          child: FloatingActionButton(
            elevation: 0,
            heroTag: label,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              side: BorderSide(color: PaletaCores.corCastanho),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            onPressed: () async {
              formatarHorario(controleHorario.text);
              exibirTimePicker(label);
            },
            child: const Icon(
              Constantes.iconeMudarHorario,
              color: PaletaCores.corAzulEscuro,
            ),
          ),
        ),
        exibicaoHorarioDefinido(label, controleHorario),
      ],
    ),
  );

  exibirTimePicker(String label) async {
    TimeOfDay? novoHorario = await showTimePicker(
      context: context,
      initialTime: horarioPadrao!,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.white,
              onPrimary: PaletaCores.corCastanho,
              surface: PaletaCores.corAzulEscuro,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (novoHorario != null) {
      setState(() {
        horarioPadrao = novoHorario;
        if (label == Textos.widgetAjustarHorarioSemana) {
          // HORARIO SEMANA
          String horarioDefinido = MetodosAuxiliares.formatarHorarioAjuste(
            horarioPadrao!,
            false,
          );
          MetodosAuxiliares.gravarHorarioInicioTrabalhoDefinido(
            Constantes.sharePreferencesAjustarHorarioSemana,
            horarioDefinido,
          );
        } else if (label == Textos.widgetAjustarHorarioFinalSemana) {
          // HORARIO FINAL DE SEMANA
          String horarioDefinido = MetodosAuxiliares.formatarHorarioAjuste(
            horarioPadrao!,
            false,
          );
          MetodosAuxiliares.gravarHorarioInicioTrabalhoDefinido(
            Constantes.sharePreferencesAjustarHorarioFinalSemana,
            horarioDefinido,
          );
        } else if (label == Textos.widgetAjustarTrocaHorarioSemana) {
          // TROCA DE TURNO SEMANA
          String horarioDefinido = MetodosAuxiliares.formatarHorarioAjuste(
            horarioPadrao!,
            true,
          );
          MetodosAuxiliares.gravarHorarioInicioTrabalhoDefinido(
            Constantes.sharePreferencesTrocaHorarioSemana,
            horarioDefinido,
          );
        } else if (label == Textos.widgetAjustarTrocaHorarioFinalSemana) {
          // TROCA DE TURNO FINAL DE SEMANA
          String horarioDefinido = MetodosAuxiliares.formatarHorarioAjuste(
            horarioPadrao!,
            true,
          );
          MetodosAuxiliares.gravarHorarioInicioTrabalhoDefinido(
            Constantes.sharePreferencesTrocaHorarioFinalSemana,
            horarioDefinido,
          );
        }
      });
      recuperarSharePreferences();
    }
  }

  recuperarSharePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      controleHorarioSemana.text =
          prefs.getString(Constantes.sharePreferencesAjustarHorarioSemana) ??
          '';
      controleHorarioFinalSemana.text =
          prefs.getString(
            Constantes.sharePreferencesAjustarHorarioFinalSemana,
          ) ??
          '';

      controleTrocaHorarioSemana.text =
          prefs.getString(Constantes.sharePreferencesTrocaHorarioSemana) ?? '';
      controleTrocaHorarioFinalSemana.text =
          prefs.getString(Constantes.sharePreferencesTrocaHorarioFinalSemana) ??
          '';

      PassarPegarDados.passarHorarioSemanaDefinido(controleHorarioSemana.text);
      PassarPegarDados.passarHorarioFinalSemanaDefinido(
        controleHorarioFinalSemana.text,
      );
      if (exibirTrocaTurno) {
        PassarPegarDados.passarHorarioTrocaTurnoSemanaDefinido(
          controleTrocaHorarioSemana.text,
        );
        PassarPegarDados.passarHorarioTrocaTurnoFinalSemanaDefinido(
          controleTrocaHorarioFinalSemana.text,
        );
      } else {
        PassarPegarDados.passarHorarioTrocaTurnoSemanaDefinido("");
        PassarPegarDados.passarHorarioTrocaTurnoFinalSemanaDefinido("");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double larguraTela = MediaQuery.of(context).size.width;
    double alturaTela = MediaQuery.of(context).size.height;
    return Container(
      margin: EdgeInsets.all(10),
      width: larguraTela,
      height: alturaTela * 0.7,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              Textos.widgetAjustarHorarioDescricao,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            botoesSwitch(Textos.trocaTurno, exibirTrocaTurno),
            botoesAcoes(
              larguraTela,
              controleHorarioSemana,
              Textos.widgetAjustarHorarioSemana,
            ),
            botoesAcoes(
              larguraTela,
              controleHorarioFinalSemana,
              Textos.widgetAjustarHorarioFinalSemana,
            ),
            Visibility(
              visible: exibirTrocaTurno,
              child: Column(
                children: [
                  botoesAcoes(
                    larguraTela,
                    controleTrocaHorarioSemana,
                    Textos.widgetAjustarTrocaHorarioSemana,
                  ),
                  botoesAcoes(
                    larguraTela,
                    controleTrocaHorarioFinalSemana,
                    Textos.widgetAjustarTrocaHorarioFinalSemana,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
