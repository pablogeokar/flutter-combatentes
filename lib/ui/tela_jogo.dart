import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modelos_jogo.dart';
import '../providers.dart';
import '../services/user_preferences.dart';
import '../audio_service.dart';
import './animated_board_widget.dart';
import './tela_nome_usuario.dart';
import './explosion_widget.dart';
import './audio_settings_dialog.dart';

/// A tela principal do jogo, agora como um ConsumerStatefulWidget que reage às mudanças de estado do Riverpod.
class TelaJogo extends ConsumerStatefulWidget {
  const TelaJogo({super.key});

  @override
  ConsumerState<TelaJogo> createState() => _TelaJogoState();
}

class _TelaJogoState extends ConsumerState<TelaJogo> {
  final List<ExplosionOverlay> _explosions = [];
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    // Inicia a música de fundo quando entra no jogo
    _audioService.playBackgroundMusic();
  }

  @override
  void dispose() {
    // Para a música quando sai do jogo
    _audioService.stopBackgroundMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Assiste a mudanças no estado do jogo.
    final uiState = ref.watch(gameStateProvider);
    final estadoJogo = uiState.estadoJogo;
    final nomeUsuario = uiState.nomeUsuario;

    // Escuta por mudanças de estado para mostrar dialogs ou snackbars, sem reconstruir o widget.
    ref.listen<TelaJogoState>(gameStateProvider, (previous, next) {
      // Detecta quando o oponente desconecta
      if (next.statusConexao == StatusConexao.oponenteDesconectado &&
          previous?.statusConexao != StatusConexao.oponenteDesconectado) {
        _showOpponentDisconnectedDialog(context, ref);
      }

      // Detecta mudança de turno e toca campainha se for a vez do jogador local
      if (previous?.estadoJogo != null &&
          next.estadoJogo != null &&
          previous!.estadoJogo!.idJogadorDaVez !=
              next.estadoJogo!.idJogadorDaVez) {
        final jogadorDaVez = next.estadoJogo!.jogadores.firstWhere(
          (j) => j.id == next.estadoJogo!.idJogadorDaVez,
        );

        // Verifica se é a vez do jogador local
        if (_isVezDoJogadorLocal(jogadorDaVez, next.nomeUsuario)) {
          debugPrint('🔔 É minha vez! Tocando campainha...');
          _audioService.playTurnNotification();
        }
      }

      // Mostra resultado do combate
      if (next.ultimoCombate != null &&
          previous?.ultimoCombate != next.ultimoCombate) {
        debugPrint(
          '📺 CHAMANDO DIÁLOGO DE COMBATE: ${next.ultimoCombate!.atacante.patente.nome} vs ${next.ultimoCombate!.defensor.patente.nome}',
        );

        // Verifica se precisa mostrar explosão ANTES do diálogo
        if (next.ultimoCombate!.defensor.patente == Patente.minaTerrestre) {
          debugPrint('💥 MINA TERRESTRE DETECTADA - Mostrando explosão');
          _showExplosionEffect(next.ultimoCombate!.posicaoCombate);

          // Toca som de explosão
          _audioService.playExplosionSound();

          // Mostra o diálogo após um pequeno delay para a explosão ser visível
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showCombatResultDialog(context, next.ultimoCombate!, ref);
            }
          });
        } else {
          // Para outros combates, toca som de tiro e mostra o diálogo imediatamente
          _audioService.playCombatSound();
          _showCombatResultDialog(context, next.ultimoCombate!, ref);
        }
      }

      // Detecta fim de jogo e toca sons apropriados
      if (next.estadoJogo?.idVencedor != null &&
          previous?.estadoJogo?.idVencedor == null) {
        final vencedorId = next.estadoJogo!.idVencedor!;
        final jogadorVencedor = next.estadoJogo!.jogadores.firstWhere(
          (j) => j.id == vencedorId,
        );

        // Verifica se o vencedor é o jogador local
        final ehVitoria = _isVezDoJogadorLocal(
          jogadorVencedor,
          next.nomeUsuario,
        );

        if (ehVitoria) {
          _audioService.playVictorySound();
        } else {
          _audioService.playDefeatSound();
        }
      }

      // Mostra uma mensagem de erro se uma ocorrer.
      if (next.erro != null && (previous?.erro != next.erro)) {
        // Verifica se é um erro de conexão para mostrar opção de reconexão
        if (next.erro!.toLowerCase().contains('conexão') ||
            next.erro!.toLowerCase().contains('servidor')) {
          _showConnectionErrorDialog(context, next.erro!, ref);
        } else if (!next.erro!.toLowerCase().contains('oponente')) {
          // Não mostra snackbar para erro de oponente desconectado (já tem diálogo)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.erro!), backgroundColor: Colors.red),
          );
        }
      }
      // Mostra o diálogo de fim de jogo quando a partida termina.
      if (next.estadoJogo?.jogoTerminou == true &&
          previous?.estadoJogo?.jogoTerminou == false) {
        _mostrarDialogoFimDeJogo(context, next.estadoJogo!, ref);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Combatentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (estadoJogo != null) ...[
              const SizedBox(width: 16),
              Expanded(child: _buildCompactGameInfo(estadoJogo, nomeUsuario)),
            ],
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.9),
        foregroundColor: Colors.white,
        actions: [
          // Menu de opções do usuário
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            onSelected: (value) => _handleMenuAction(context, value, ref),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'change_name',
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 20),
                    const SizedBox(width: 8),
                    Text('Alterar Nome'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'audio_settings',
                child: Row(
                  children: [
                    const Icon(Icons.volume_up, size: 20),
                    const SizedBox(width: 8),
                    Text('Configurações de Áudio'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_name',
                child: Row(
                  children: [
                    const Icon(Icons.delete, size: 20),
                    const SizedBox(width: 8),
                    Text('Limpar Nome'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'disconnect',
                child: Row(
                  children: [
                    const Icon(Icons.exit_to_app, size: 20),
                    const SizedBox(width: 8),
                    Text('Desconectar'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/tela_inicial.png',
              fit: BoxFit.cover,
            ),
          ),
          // Mostra um indicador de carregamento enquanto conecta ou o estado é nulo
          if (estadoJogo == null)
            Center(
              child: Card(
                color: Colors.black54,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mostra ícone diferente baseado no status
                      _buildStatusIcon(uiState.statusConexao),
                      const SizedBox(height: 16),
                      Text(
                        _getStatusMessage(uiState.statusConexao),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (uiState.erro != null &&
                          (uiState.erro!.toLowerCase().contains('conexão') ||
                              uiState.erro!.toLowerCase().contains('servidor')))
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: ElevatedButton.icon(
                            onPressed: () => _attemptReconnection(context, ref),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar Nova Conexão'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Mostra o tabuleiro quando o estado estiver disponível
            Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: AnimatedBoardWidget(
                  estadoJogo: estadoJogo,
                  idPecaSelecionada: uiState.idPecaSelecionada,
                  movimentosValidos: uiState.movimentosValidos,
                  nomeUsuarioLocal: nomeUsuario,
                  movimentoPendente: uiState.ultimoMovimento,
                  onPecaTap: (idPeca) => ref
                      .read(gameStateProvider.notifier)
                      .selecionarPeca(idPeca),
                  onPosicaoTap: (posicao) =>
                      ref.read(gameStateProvider.notifier).moverPeca(posicao),
                  onMovementComplete: () =>
                      ref.read(gameStateProvider.notifier).limparMovimento(),
                ),
              ),
            ),
          // Explosões
          ..._explosions,
        ],
      ),
    );
  }

  /// Mostra o efeito de explosão na posição especificada
  void _showExplosionEffect(PosicaoTabuleiro posicao) {
    debugPrint(
      '💥 _showExplosionEffect CHAMADA! Posição: (${posicao.linha}, ${posicao.coluna})',
    );

    // Calcula a posição da explosão baseada na posição da peça no tabuleiro
    final screenSize = MediaQuery.of(context).size;

    // Calcula o tamanho do tabuleiro (AspectRatio 1:1 centralizado)
    final availableHeight =
        screenSize.height - kToolbarHeight - MediaQuery.of(context).padding.top;
    final boardSize = screenSize.width < availableHeight
        ? screenSize.width * 0.95
        : availableHeight * 0.95;
    final cellSize = boardSize / 10;

    // Posição do centro da tela (considerando o AppBar)
    final centerX = screenSize.width / 2;
    final centerY =
        kToolbarHeight +
        MediaQuery.of(context).padding.top +
        availableHeight / 2;

    // Offset da posição da peça no tabuleiro (0,0 é canto superior esquerdo)
    final offsetX = (posicao.coluna - 4.5) * cellSize;
    final offsetY = (posicao.linha - 4.5) * cellSize;

    final explosionX =
        centerX + offsetX - 60; // 60 é metade do tamanho da explosão
    final explosionY = centerY + offsetY - 60;

    debugPrint('📊 Explosão calculada em: ($explosionX, $explosionY)');

    late ExplosionOverlay explosion;
    explosion = ExplosionOverlay(
      left: explosionX,
      top: explosionY,
      onComplete: () {
        if (mounted) {
          setState(() {
            _explosions.removeWhere((e) => e == explosion);
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _explosions.add(explosion);
        debugPrint('✅ Explosão adicionada! Total: ${_explosions.length}');
      });
    } else {
      debugPrint('❌ Widget não montado, explosão não adicionada');
    }
  }

  /// Mostra diálogo com o resultado do combate
  void _showCombatResultDialog(
    BuildContext context,
    InformacoesCombate combate,
    WidgetRef ref,
  ) {
    debugPrint(
      '🔍 COMBATE: ${combate.atacante.patente.nome} vs ${combate.defensor.patente.nome}',
    );
    final bool ehMeuAtacante = _isMinhaEquipe(
      combate.atacante,
      ref.read(gameStateProvider).nomeUsuario,
      ref,
    );
    final bool ehMeuDefensor = _isMinhaEquipe(
      combate.defensor,
      ref.read(gameStateProvider).nomeUsuario,
      ref,
    );

    String titulo;
    String mensagem;
    Color corTitulo;
    IconData icone;

    if (combate.foiEmpate) {
      titulo = "Empate!";
      mensagem =
          "${combate.atacante.patente.nome} vs ${combate.defensor.patente.nome}\n\nAmbas as peças foram eliminadas.";
      corTitulo = Colors.orange;
      icone = Icons.balance;
    } else if (combate.vencedor != null) {
      final bool vencedorEhMeu = _isMinhaEquipe(
        combate.vencedor!,
        ref.read(gameStateProvider).nomeUsuario,
        ref,
      );

      if (vencedorEhMeu) {
        titulo = "Vitória!";
        corTitulo = Colors.green;
        icone = Icons.military_tech;
      } else {
        titulo = "Derrota!";
        corTitulo = Colors.red;
        icone = Icons.close;
      }

      mensagem =
          "${combate.atacante.patente.nome} atacou ${combate.defensor.patente.nome}\n\n";
      mensagem += "${combate.vencedor!.patente.nome} venceu o combate!";

      // Adiciona informações sobre regras especiais
      if (combate.atacante.patente == Patente.agenteSecreto &&
          combate.defensor.patente == Patente.general) {
        mensagem += "\n\n🕵️ Agente Secreto eliminou o General!";
      } else if (combate.defensor.patente == Patente.minaTerrestre) {
        if (combate.atacante.patente == Patente.cabo) {
          mensagem += "\n\n💣 Cabo desativou a Mina Terrestre!";
        } else {
          mensagem += "\n\n💥 Mina Terrestre explodiu!";
        }
      }
    } else {
      titulo = "Combate";
      mensagem = "Resultado do combate não determinado.";
      corTitulo = Colors.grey;
      icone = Icons.help;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icone, color: corTitulo, size: 24),
            SizedBox(width: 8),
            Text(titulo, style: TextStyle(color: corTitulo)),
          ],
        ),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey[100]!, Colors.grey[50]!],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mostra as peças do combate
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCombatPieceInfo(
                    combate.atacante,
                    "Atacante",
                    ehMeuAtacante,
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.flash_on, color: Colors.orange, size: 32),
                  ),
                  _buildCombatPieceInfo(
                    combate.defensor,
                    "Defensor",
                    ehMeuDefensor,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  mensagem,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Limpa as informações do combate
              ref.read(gameStateProvider.notifier).limparCombate();
            },
            child: Text('Continuar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói informações visuais de uma peça no combate
  Widget _buildCombatPieceInfo(PecaJogo peca, String papel, bool ehMinha) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: peca.equipe == Equipe.preta
                ? Colors.grey[800]
                : Colors.green[700],
            borderRadius: BorderRadius.circular(12),
            border: ehMinha ? Border.all(color: Colors.yellow, width: 3) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.white.withValues(alpha: 0.9),
                      BlendMode.modulate,
                    ),
                    child: Image.asset(
                      peca.patente.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.error, color: Colors.red, size: 30);
                      },
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      peca.patente.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          papel,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Text(
          "Força: ${peca.patente.forca}",
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  /// Verifica se uma peça pertence à equipe do jogador local
  bool _isMinhaEquipe(PecaJogo peca, String? nomeUsuario, WidgetRef ref) {
    if (nomeUsuario == null) return false;

    final estadoJogo = ref.read(gameStateProvider).estadoJogo;
    if (estadoJogo == null) return false;

    // Busca o jogador local pelo nome
    final jogadorLocal = estadoJogo.jogadores.where((jogador) {
      final nomeJogador = jogador.nome.trim().toLowerCase();
      final nomeLocal = nomeUsuario.trim().toLowerCase();

      // Busca exata ou parcial
      return nomeJogador == nomeLocal ||
          nomeJogador.contains(nomeLocal) ||
          nomeLocal.contains(nomeJogador);
    }).firstOrNull;

    if (jogadorLocal != null) {
      return peca.equipe == jogadorLocal.equipe;
    }

    return false;
  }

  /// Verifica se é a vez do jogador local
  bool _isVezDoJogadorLocal(Jogador jogadorDaVez, String? nomeUsuario) {
    if (nomeUsuario == null) return false;

    final nomeJogadorDaVez = jogadorDaVez.nome.trim().toLowerCase();
    final nomeLocal = nomeUsuario.trim().toLowerCase();

    // Busca exata ou parcial
    return nomeJogadorDaVez == nomeLocal ||
        nomeJogadorDaVez.contains(nomeLocal) ||
        nomeLocal.contains(nomeJogadorDaVez);
  }

  /// Mostra diálogo quando o oponente desconecta
  void _showOpponentDisconnectedDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_off, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Oponente Desconectou'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seu oponente saiu da partida.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Você será redirecionado para aguardar um novo oponente.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // Volta para o estado de aguardando oponente
              ref
                  .read(gameStateProvider.notifier)
                  .voltarParaAguardandoOponente();
            },
            icon: Icon(Icons.refresh),
            label: Text('Aguardar Novo Oponente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Mostra diálogo de erro de conexão com opção de reconectar
  void _showConnectionErrorDialog(
    BuildContext context,
    String errorMessage,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Erro de Conexão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorMessage, style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            Text(
              'Verifique se o servidor está ativo e tente novamente.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Volta para a tela de nome do usuário
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const TelaNomeUsuario(),
                ),
              );
            },
            child: Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _attemptReconnection(context, ref);
            },
            icon: Icon(Icons.refresh),
            label: Text('Tentar Nova Conexão'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Tenta reconectar ao servidor
  void _attemptReconnection(BuildContext context, WidgetRef ref) {
    // Limpa o erro atual
    ref.read(gameStateProvider.notifier).clearError();

    // Tenta reconectar
    ref.read(gameStateProvider.notifier).reconnect();

    // Mostra feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Tentando reconectar...'),
          ],
        ),
        backgroundColor: Color(0xFF2E7D32),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Lida com as ações do menu do usuário
  void _handleMenuAction(BuildContext context, String action, WidgetRef ref) {
    switch (action) {
      case 'change_name':
        _showChangeNameDialog(context, ref);
        break;
      case 'audio_settings':
        _showAudioSettingsDialog(context);
        break;
      case 'clear_name':
        _showClearNameDialog(context, ref);
        break;
      case 'disconnect':
        _showDisconnectDialog(context, ref);
        break;
    }
  }

  /// Mostra diálogo de configurações de áudio
  void _showAudioSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AudioSettingsDialog(),
    );
  }

  /// Mostra diálogo para alterar nome
  void _showChangeNameDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();
    final nomeAtual = ref.read(gameStateProvider).nomeUsuario;
    if (nomeAtual != null) {
      controller.text = nomeAtual;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Nome'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Novo nome',
            hintText: 'Digite seu novo nome',
          ),
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final novoNome = controller.text.trim();
              if (novoNome.isNotEmpty && novoNome.length >= 2) {
                await UserPreferences.saveUserName(novoNome);
                ref.read(gameStateProvider.notifier).updateUserName(novoNome);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Nome alterado para: $novoNome'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  /// Mostra diálogo para limpar nome
  void _showClearNameDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Nome'),
        content: const Text(
          'Tem certeza que deseja limpar seu nome? '
          'Você precisará digitá-lo novamente na próxima vez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await UserPreferences.clearUserName();
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const TelaNomeUsuario(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  /// Mostra diálogo para desconectar
  void _showDisconnectDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desconectar'),
        content: const Text(
          'Tem certeza que deseja sair do jogo? '
          'Você será desconectado da partida atual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const TelaNomeUsuario(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
  }

  /// Constrói as informações compactas do jogo para o AppBar
  Widget _buildCompactGameInfo(EstadoJogo estado, String? nomeUsuario) {
    final jogadorDaVez = estado.jogadores.firstWhere(
      (j) => j.id == estado.idJogadorDaVez,
    );

    final bool ehMinhVez =
        nomeUsuario != null && jogadorDaVez.nome.contains(nomeUsuario);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompactPlayerInfo(estado.jogadores[0], estado, nomeUsuario),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ehMinhVez ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ehMinhVez ? 'Sua vez' : 'Oponente',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          _buildCompactPlayerInfo(estado.jogadores[1], estado, nomeUsuario),
        ],
      ),
    );
  }

  /// Constrói informações compactas de um jogador
  Widget _buildCompactPlayerInfo(
    Jogador jogador,
    EstadoJogo estado,
    String? nomeUsuario,
  ) {
    final bool ehEuMesmo =
        nomeUsuario != null && jogador.nome.contains(nomeUsuario);
    final bool ehVez = jogador.id == estado.idJogadorDaVez;
    final int pecasRestantes = estado.pecas
        .where((p) => p.equipe == jogador.equipe)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ehVez ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: ehVez ? Border.all(color: Colors.yellow, width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: jogador.equipe == Equipe.preta
                  ? Colors.grey[400]
                  : Colors.green[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            jogador.nome.length > 8
                ? '${jogador.nome.substring(0, 8)}...'
                : jogador.nome,
            style: TextStyle(
              color: Colors.white,
              fontWeight: ehEuMesmo ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$pecasRestantes',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o ícone apropriado baseado no status da conexão
  Widget _buildStatusIcon(StatusConexao status) {
    switch (status) {
      case StatusConexao.conectando:
        return const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        );
      case StatusConexao.conectado:
        return const Icon(Icons.people_outline, color: Colors.blue, size: 48);
      case StatusConexao.oponenteDesconectado:
        return const Icon(Icons.person_search, color: Colors.orange, size: 48);
      case StatusConexao.erro:
        return const Icon(Icons.error_outline, color: Colors.red, size: 48);
      case StatusConexao.desconectado:
        return const Icon(Icons.wifi_off, color: Colors.grey, size: 48);
      default:
        return const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        );
    }
  }

  /// Retorna a mensagem apropriada baseada no status da conexão
  String _getStatusMessage(StatusConexao status) {
    switch (status) {
      case StatusConexao.conectando:
        return 'Conectando ao servidor...';
      case StatusConexao.conectado:
        return 'Conectado ao servidor.\nAguardando oponente...';
      case StatusConexao.oponenteDesconectado:
        return 'Aguardando novo oponente...\n\nSeu oponente anterior saiu da partida.';
      case StatusConexao.erro:
        return 'Erro de conexão com o servidor.';
      case StatusConexao.desconectado:
        return 'Desconectado do servidor.';
      default:
        return 'Conectando...';
    }
  }

  /// Mostra um diálogo de fim de jogo.
  void _mostrarDialogoFimDeJogo(
    BuildContext context,
    EstadoJogo estadoFinal,
    WidgetRef ref,
  ) {
    final vencedor = estadoFinal.jogadores.firstWhere(
      (j) => j.id == estadoFinal.idVencedor,
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Fim de Jogo!"),
        content: Text(
          "O jogador ${vencedor.nome} (${vencedor.equipe.name}) venceu!",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
