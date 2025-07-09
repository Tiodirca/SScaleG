import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sscaleg/Widgets/tela_carregamento.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/estilo.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:sscaleg/uteis/textos.dart';
import 'package:sscaleg/uteis/usuario/validar_login_cadastro_usuario.dart';

class TelaLoginCadastro extends StatefulWidget {
  const TelaLoginCadastro({super.key});

  @override
  State<TelaLoginCadastro> createState() => _TelaLoginCadastroState();
}

class _TelaLoginCadastroState extends State<TelaLoginCadastro> {
  Estilo estilo = Estilo();
  bool exibirWidgetCarregamento = false;
  bool exibirOcultarSenha = true;
  IconData iconeExibirSenha = Icons.visibility;
  TextEditingController controleEmail = TextEditingController(text: "");
  TextEditingController controleSenha = TextEditingController(text: "");
  final _formKeyFormulario = GlobalKey<FormState>();

  Widget botao(String nomeBtn, BuildContext context) => Container(
    margin: const EdgeInsets.all(10),
    width: 100,
    height: 40,
    child: FloatingActionButton(
      heroTag: nomeBtn,
      onPressed: () {
        if (_formKeyFormulario.currentState!.validate()) {
          setState(() {
            exibirWidgetCarregamento = true;
          });
          if (nomeBtn == Textos.btnLogin) {
            chamarValidarLogin();
          } else if (nomeBtn == Textos.btnCadastrar) {
            chamarValidarCriarCadastro();
          }
        }
      },
      child: Text(
        nomeBtn,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black),
      ),
    ),
  );

  chamarValidarLogin() async {
    String retorno = await ValidarLoginCadastroUsuario.fazerLogin(
      controleEmail.text,
      controleSenha.text,
      context,
    );
    if (retorno == Constantes.tipoNotificacaoSucesso) {
      redirecionarTelaInicial();
    } else {
      setState(() {
        exibirWidgetCarregamento = false;
      });
      chamarValidarErro(retorno);
    }
  }

  chamarValidarCriarCadastro() async {
    String retorno = await ValidarLoginCadastroUsuario.criarCadastro(
      controleEmail.text,
      controleSenha.text,
      context,
    );
    if (retorno == Constantes.tipoNotificacaoSucesso) {
      redirecionarTelaInicial();
    } else {
      setState(() {
        exibirWidgetCarregamento = false;
        chamarValidarErro(retorno);
      });
    }
  }

  chamarValidarErro(String erro){
    MetodosAuxiliares.validarErro(erro,context);
  }

  redirecionarTelaInicial() {
    Navigator.pushReplacementNamed(context, Constantes.rotaTelaInicial);
  }

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

  Widget camposFormulario(
    String label,
    TextEditingController controle,
    IconData icone,
  ) => SizedBox(
    width: 300,
    height: 70,
    child: TextFormField(
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
                  title: Text(Textos.nomeApp),
                  leading: const Image(
                    image: AssetImage('assets/imagens/Logo.png'),
                    width: 10,
                    height: 10,
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
                        SizedBox(
                          width: larguraTela,
                          child: Text(
                            Textos.telaLoginUsuarioDescricao,
                            style: const TextStyle(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Form(
                          key: _formKeyFormulario,
                          child: Column(
                            children: [
                              camposFormulario(
                                Textos.labelEmail,
                                controleEmail,
                                Constantes.iconeEmail,
                              ),
                              camposFormulario(
                                Textos.labelSenha,
                                controleSenha,
                                Constantes.iconeSenha,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            botao(Textos.btnLogin, context),
                            botao(Textos.btnCadastrar, context),
                          ],
                        ),
                      ],
                    ),
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
