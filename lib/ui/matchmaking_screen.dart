import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../services/user_preferences.dart';
import 'military_theme_widgets.dart';
import 'server_config_dialog.dart';
import 'tela_nome_usuario.dart';
import 'game_flow_screen.dart';

/// Tela de matchmaking que aguarda conexão com oponente.
class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isConnecting = false;
  bool _hasNavigated = false; // Flag para evitar navegação dupla

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startConnection();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  Future<void> _startConnection() async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      final nomeUsuario = await UserPreferences.getUserName();
      final serverAddress = await UserPreferences.getServerAddress();

      debugPrint('🔍 Nome obtido das preferências: $nomeUsuario');
      debugPrint('🔍 Endereço do servidor: $serverAddress');

      if (nomeUsuario == null) {
        debugPrint('❌ Nome é null, navegando para tela de nome');
        _navigateToNameScreen();
        return;
      }

      debugPrint('✅ Conectando ao servidor com nome: $nomeUsuario');

      // Conecta ao servidor
      ref
          .read(gameStateProvider.notifier)
          .conectarAoServidor(serverAddress, nomeUsuario);
    } catch (e) {
      debugPrint('Erro ao iniciar conexão: $e');
      _showConnectionError('Erro ao conectar: $e');
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  void _navigateToNameScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const TelaNomeUsuario()),
    );
  }

  void _showConnectionError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Tentar Novamente',
          textColor: Colors.white,
          onPressed: _startConnection,
        ),
      ),
    );
  }

  void _showServerConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => const ServerConfigDialog(),
    );
  }

  void _showUserMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildUserMenu(),
    );
  }

  Widget _buildUserMenu() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        color: Colors.black.withValues(alpha: 0.9),
        border: Border.all(
          color: MilitaryThemeWidgets.primaryGreen.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar militar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: MilitaryThemeWidgets.primaryGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header militar
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.military_tech,
                  color: MilitaryThemeWidgets.primaryGreen,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'MENU DE COMANDO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Menu items militares
          _buildMilitaryMenuItem(
            icon: Icons.person,
            title: 'ALTERAR NOME',
            onTap: () {
              Navigator.pop(context);
              _navigateToNameScreen();
            },
          ),
          _buildMilitaryMenuItem(
            icon: Icons.settings,
            title: 'CONFIGURAR SERVIDOR',
            onTap: () {
              Navigator.pop(context);
              _showServerConfigDialog();
            },
          ),
          _buildMilitaryMenuItem(
            icon: Icons.refresh,
            title: 'NOVA CONEXÃO',
            onTap: () {
              Navigator.pop(context);
              _startConnection();
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMilitaryMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MilitaryThemeWidgets.primaryGreen.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: MilitaryThemeWidgets.primaryGreen, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: MilitaryThemeWidgets.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(gameStateProvider);

    // Escuta mudanças no estado para detectar quando o jogo deve começar
    ref.listen<TelaJogoState>(gameStateProvider, (previous, current) {
      // Se recebeu um estado de jogo válido com 2 jogadores, pode iniciar placement
      if (!_hasNavigated &&
          current.estadoJogo != null &&
          current.estadoJogo!.jogadores.length >= 2 &&
          current.statusConexao == StatusConexao.jogando) {
        debugPrint('🚀 MatchmakingScreen: Navegando para GameFlowScreen');
        _hasNavigated = true;
        // Navega para o placement
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GameFlowScreen()),
        );
      }

      // Se ficou muito tempo conectado sem avançar, tenta reenviar o nome
      if (current.statusConexao == StatusConexao.conectado &&
          current.estadoJogo == null) {
        // Agenda reenvio do nome após 5 segundos conectado
        Future.delayed(const Duration(seconds: 5), () async {
          if (mounted &&
              ref.read(gameStateProvider).statusConexao ==
                  StatusConexao.conectado &&
              ref.read(gameStateProvider).estadoJogo == null) {
            debugPrint(
              '🔄 Muito tempo conectado sem progresso, reenviando nome...',
            );
            final nome = await UserPreferences.getUserName();
            if (nome != null) {
              ref.read(gameSocketProvider).forcarReenvioNome(nome);
            }
          }
        });
      }
    });

    return Scaffold(
      body: MilitaryThemeWidgets.militaryBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(uiState),
              Expanded(child: _buildContent(uiState)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TelaJogoState uiState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Logo grande do jogo
          Image.asset(
            'assets/images/logo.png',
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 16),

          // Título e nome do jogador
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (uiState.nomeUsuario != null)
                  Text(
                    'Combatente ${uiState.nomeUsuario}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Menu do usuário
          IconButton(
            onPressed: _showUserMenu,
            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
            tooltip: 'Menu',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TelaJogoState uiState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Ícone animado principal
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: MilitaryThemeWidgets.primaryGreen.withValues(
                      alpha: 0.2,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: MilitaryThemeWidgets.primaryGreen,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: MilitaryThemeWidgets.primaryGreen.withValues(
                          alpha: 0.4,
                        ),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getStatusIcon(uiState.statusConexao),
                    size: 60,
                    color: MilitaryThemeWidgets.primaryGreen,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Card principal de status - mais escuro e militar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: MilitaryThemeWidgets.primaryGreen.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _getStatusTitle(uiState.statusConexao),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  uiState.statusConexao.mensagem,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),

                if (uiState.statusConexao == StatusConexao.conectando ||
                    uiState.statusConexao == StatusConexao.conectado) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      MilitaryThemeWidgets.primaryGreen,
                    ),
                    strokeWidth: 3,
                  ),
                ],

                if (uiState.statusConexao == StatusConexao.erro ||
                    uiState.statusConexao == StatusConexao.desconectado) ...[
                  const SizedBox(height: 20),
                  MilitaryThemeWidgets.militaryButton(
                    text: 'TENTAR NOVAMENTE',
                    icon: Icons.refresh,
                    onPressed: _startConnection,
                    width: double.infinity,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Instruções de jogo - card militar escuro
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: MilitaryThemeWidgets.primaryGreen.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: MilitaryThemeWidgets.primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'INSTRUÇÕES DE BATALHA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: MilitaryThemeWidgets.primaryGreen,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '1. Conecte-se ao servidor de comando\n'
                  '2. Aguarde outro comandante se conectar\n'
                  '3. Posicione suas 40 peças no campo de batalha\n'
                  '4. Aguarde o oponente finalizar posicionamento\n'
                  '5. Clique em "PRONTO" quando terminar\n'
                  '6. A batalha começará automaticamente!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40), // Espaço extra no final
        ],
      ),
    );
  }

  IconData _getStatusIcon(StatusConexao status) {
    switch (status) {
      case StatusConexao.conectando:
        return Icons.wifi_find;
      case StatusConexao.conectado:
        return Icons.search;
      case StatusConexao.jogando:
        return Icons.check_circle;
      case StatusConexao.erro:
        return Icons.error;
      case StatusConexao.desconectado:
        return Icons.wifi_off;
      case StatusConexao.oponenteDesconectado:
        return Icons.person_off;
    }
  }

  String _getStatusTitle(StatusConexao status) {
    switch (status) {
      case StatusConexao.conectando:
        return 'Conectando...';
      case StatusConexao.conectado:
        return 'Procurando Oponente';
      case StatusConexao.jogando:
        return 'Oponente Encontrado!';
      case StatusConexao.erro:
        return 'Erro de Conexão';
      case StatusConexao.desconectado:
        return 'Desconectado';
      case StatusConexao.oponenteDesconectado:
        return 'Oponente Desconectou';
    }
  }
}
