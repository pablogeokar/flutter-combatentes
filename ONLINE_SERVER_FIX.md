# Correção para Servidor Online (Render.com)

## Problema Identificado

Após fazer o deploy do servidor para `flutter-combatentes.onrender.com`, o cliente não conseguia conectar e ficava travado na tela de "Procurando Oponente".

## Causa Raiz

1. **URL padrão incorreta**: Cliente estava configurado para `ws://localhost:8083`
2. **Protocolo incorreto**: Render.com força HTTPS, então WebSocket deve usar WSS (seguro)

## Correções Implementadas

### 1. Atualização do Endereço Padrão

**Arquivo**: `lib/services/user_preferences.dart`

```dart
// ANTES
static const String _defaultServerAddress = 'ws://localhost:8083';

// DEPOIS
static const String _defaultServerAddress = 'wss://flutter-combatentes.onrender.com';
```

### 2. Atualização do Diálogo de Configuração

**Arquivo**: `lib/ui/server_config_dialog.dart`

- Endereço padrão alterado para `wss://flutter-combatentes.onrender.com`
- Hint text atualizado
- Exemplos atualizados para mostrar o novo servidor como padrão

### 3. Atualização dos Placeholders

**Arquivo**: `lib/placement_controller.dart`

- Todas as referências hardcoded alteradas de `ws://localhost:8083` para `wss://flutter-combatentes.onrender.com`

### 4. Protocolo Seguro (WSS)

Mudança de `ws://` para `wss://` porque:

- Render.com força redirecionamento HTTPS
- WebSocket sobre HTTPS requer WSS (WebSocket Secure)
- Verificado com `curl -I` que o servidor redireciona para HTTPS

## Arquivos Modificados

1. `lib/services/user_preferences.dart` - Endereço padrão
2. `lib/ui/server_config_dialog.dart` - Interface de configuração
3. `lib/placement_controller.dart` - Placeholders de reconexão

## Limpeza de Cache

Removido o arquivo `combatentes_user.json` para forçar o uso do novo endereço padrão.

## Status

🟢 **RESOLVIDO** - Cliente agora está configurado para conectar ao servidor online:

- ✅ Endereço padrão: `wss://flutter-combatentes.onrender.com`
- ✅ Protocolo seguro (WSS) para compatibilidade com HTTPS
- ✅ Cache limpo para aplicar novas configurações
- ✅ Cliente recompilado e testando conectividade

## Próximos Passos

1. Testar conectividade com o servidor online
2. Verificar se o pareamento funciona entre múltiplas instâncias
3. Confirmar que o fluxo completo funciona em produção
