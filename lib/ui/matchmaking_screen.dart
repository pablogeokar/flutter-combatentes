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

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
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

      if (nomeUsuario == null) {
        _navigateToNameScreen();
        return;
      }

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
    return MilitaryThemeWidgets.militaryCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.person,
              color: MilitaryThemeWidgets.primaryGreen,
            ),
            title: const Text('Alterar Nome'),
            onTap: () {
              Navigator.pop(context);
              _navigateToNameScreen();
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.settings,
              color: MilitaryThemeWidgets.primaryGreen,
            ),
            title: const Text('Configurar Servidor'),
            onTap: () {
              Navigator.pop(context);
              _showServerConfigDialog();
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.refresh,
              color: MilitaryThemeWidgets.primaryGreen,
            ),
            title: const Text('Tentar Nova Conexão'),
            onTap: () {
              Navigator.pop(context);
              _startConnection();
            },
          ),
        ],
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
      if (current.estadoJogo != null &&
          current.estadoJogo!.jogadores.length >= 2 &&
          current.statusConexao == StatusConexao.jogando) {
        // Navega para o placement
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GameFlowScreen()),
        );
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
          // Logo pequeno
          Image.asset(
            'assets/images/logo.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),

          // Título
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Combatentes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (uiState.nomeUsuario != null)
                  Text(
                    'Jogador: ${uiState.nomeUsuario}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),

          // Menu do usuário
          IconButton(
            onPressed: _showUserMenu,
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TelaJogoState uiState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone animado
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
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.search,
                    size: 60,
                    color: MilitaryThemeWidgets.primaryGreen,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Status da conexão
          MilitaryThemeWidgets.militaryCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  _getStatusTitle(uiState.statusConexao),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MilitaryThemeWidgets.primaryGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  uiState.statusConexao.mensagem,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),

                if (uiState.statusConexao == StatusConexao.conectando ||
                    uiState.statusConexao == StatusConexao.conectado) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      MilitaryThemeWidgets.primaryGreen,
                    ),
                  ),
                ],

                if (uiState.statusConexao == StatusConexao.erro ||
                    uiState.statusConexao == StatusConexao.desconectado) ...[
                  const SizedBox(height: 20),
                  MilitaryThemeWidgets.militaryButton(
                    text: 'Tentar Novamente',
                    onPressed: _startConnection,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Informações adicionais
          MilitaryThemeWidgets.militaryCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: MilitaryThemeWidgets.primaryGreen,
                  size: 24,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Como Funciona',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: MilitaryThemeWidgets.primaryGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Conecte-se ao servidor\n'
                  '2. Aguarde um oponente se conectar\n'
                  '3. Posicione suas 40 peças no tabuleiro\n'
                  '4. Aguarde o oponente terminar\n'
                  '5. Clique em "PRONTO" quando terminar\n'
                  '6. O jogo começará automaticamente!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
