import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sscaleg/Uteis/paleta_cores.dart';
import 'package:sscaleg/Widgets/tela_carregamento.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/estilo.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/textos.dart';
import 'package:sscaleg/widgets/barra_navegacao_widget.dart';

class TelaDadosUsuario extends StatefulWidget {
  const TelaDadosUsuario({super.key});

  @override
  State<TelaDadosUsuario> createState() => _TelaDadosUsuarioState();
}

class _TelaDadosUsuarioState extends State<TelaDadosUsuario> {
  Estilo estilo = Estilo();
  bool exibirWidgetCarregamento = false;
  bool exibirOcultarSenha = true;
  bool edicaoAtiva = false;
  IconData iconeExibirSenha = Icons.visibility;
  TextEditingController controleEmail = TextEditingController(text: "");
  TextEditingController controleSenha = TextEditingController(text: "");
  final _formKeyFormulario = GlobalKey<FormState>();
  String emailCadastrado = "";

  @override
  void initState() {
    super.initState();
    emailCadastrado =
        PassarPegarDados.recuperarInformacoesUsuario().entries.last.value;
    controleEmail.text = emailCadastrado;
  }

  Widget botao(String nomeBtn, BuildContext context) => Container(
    margin: const EdgeInsets.all(10),
    width: 100,
    height: 40,
    child: FloatingActionButton(
      heroTag: nomeBtn,
      onPressed: () {
        if (nomeBtn == Textos.btnSairConta) {
          chamarSairConta();
        } else if (nomeBtn == Textos.btnCadastrar) {}
      },
      child: Text(
        nomeBtn,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black),
      ),
    ),
  );

  chamarSairConta() async {
    await FirebaseAuth.instance.signOut();
    redirecionarTelaLoginCadastro();
  }

  redirecionarTelaLoginCadastro() {
    Navigator.pushReplacementNamed(context, Constantes.rotaTelaLoginCadastro);
  }

  Widget camposFormulario(
    String label,
    TextEditingController controle,
    IconData icone,
  ) => SizedBox(
    width: 300,
    height: 70,
    child: TextFormField(
      enabled: edicaoAtiva,
      controller: controle,
      validator: (value) {
        if (value!.isEmpty) {
          return Textos.erroCampoVazio;
        }
        return null;
      },
      keyboardType: TextInputType.text,
      obscureText: label == Textos.labelSenha ? exibirOcultarSenha : false,
      decoration: InputDecoration(
        prefixIcon: Icon(icone),
        label: Text(label),
        suffixIcon:
            label == Textos.labelSenha ? chamarExibicaoOcultarSenha() : null,
      ),
    ),
  );

  chamarExibicaoOcultarSenha() {
    return IconButton(
      onPressed: () {
        setState(() {
          if (exibirOcultarSenha) {
            setState(() {
              exibirOcultarSenha = false;
              iconeExibirSenha = Icons.visibility_off;
            });
          } else {
            setState(() {
              exibirOcultarSenha = true;
              iconeExibirSenha = Icons.visibility;
            });
          }
        });
      },
      icon: Icon(iconeExibirSenha),
    );
  }

  Widget botoesIcones(String label) => Container(
    margin: EdgeInsets.symmetric(horizontal: 10),
    height: 35,
    width: 35,
    child: FloatingActionButton(
      heroTag: label,
      onPressed: () async {
        if (label == Textos.labelEmail) {
        } else if (label == Textos.labelSenha) {
        } else if (label == Constantes.excluir) {
          setState(() {
            edicaoAtiva = false;
          });
        }
      },
      child: Icon(
        label != Constantes.excluir
            ? Constantes.iconeEditar
            : Constantes.iconeExclusao,
        color: PaletaCores.corAzulEscuro,
        size: 30,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    double alturaTela = MediaQuery.of(context).size.height;
    double larguraTela = MediaQuery.of(context).size.width;
    Timer(Duration(seconds: 2), () {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [SystemUiOverlay.bottom],
      );
    });
    return Theme(
      data: estilo.estiloGeral,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (exibirWidgetCarregamento) {
              return const TelaCarregamento();
            } else {
              return Scaffold(
                appBar: AppBar(
                  title: Text(Textos.telaDadosUsuarioTitulo),
                  leading: IconButton(
                    color: Colors.white,
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        Constantes.rotaTelaInicial,
                      );
                    },
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                ),
                body: Container(
                  color: Colors.white,
                  width: larguraTela,
                  height: alturaTela,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.all(10),
                          width: larguraTela,
                          child: Text(
                            Textos.telaDadosUsuarioDescricao,
                            style: const TextStyle(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Form(
                          key: _formKeyFormulario,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  camposFormulario(
                                    Textos.labelEmail,
                                    controleEmail,
                                    Constantes.iconeEmail,
                                  ),
                                  botoesIcones(Textos.labelEmail),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  camposFormulario(
                                    Textos.labelSenha,
                                    controleSenha,
                                    Constantes.iconeSenha,
                                  ),
                                  botoesIcones(Textos.labelSenha),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: edicaoAtiva,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              botao(Textos.btnSalvar, context),
                              botoesIcones(Constantes.excluir),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottomNavigationBar: Container(
                  width: larguraTela,
                  color: Colors.white,
                  height: 120,
                  child: Column(
                    children: [
                      botao(Textos.btnSairConta, context),
                      BarraNavegacao(),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
