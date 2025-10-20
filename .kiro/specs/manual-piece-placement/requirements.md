# Requirements Document

## Introduction

Este documento especifica a implementação do sistema de posicionamento manual de peças no jogo Combatentes. Atualmente, as peças são posicionadas aleatoriamente no tabuleiro quando a partida inicia. A nova funcionalidade permitirá que cada jogador posicione manualmente suas 40 peças em sua área do tabuleiro antes do início da partida, seguindo as regras tradicionais do Stratego.

## Requirements

### Requirement 1

**User Story:** Como um jogador, eu quero posicionar manualmente minhas peças no tabuleiro antes da partida começar, para que eu possa implementar minha estratégia desde o início.

#### Acceptance Criteria

1. WHEN um jogador é pareado com um oponente THEN o sistema SHALL exibir um tabuleiro vazio
2. WHEN o tabuleiro é exibido THEN o sistema SHALL mostrar apenas a área de posicionamento do jogador local (4 linhas)
3. WHEN o jogador está posicionando peças THEN o sistema SHALL exibir um inventário com todas as 40 peças disponíveis
4. WHEN o jogador clica em uma peça do inventário THEN o sistema SHALL permitir posicionar a peça em qualquer posição válida de sua área
5. WHEN uma peça é posicionada THEN o sistema SHALL remover a peça do inventário e colocá-la no tabuleiro
6. WHEN o jogador clica em uma peça já posicionada THEN o sistema SHALL permitir mover a peça para outra posição válida
7. WHEN o jogador clica em uma peça posicionada e depois clica no inventário THEN o sistema SHALL devolver a peça ao inventário

### Requirement 2

**User Story:** Como um jogador, eu quero ter controle total sobre o posicionamento das minhas peças, para que eu possa corrigir erros e ajustar minha estratégia.

#### Acceptance Criteria

1. WHEN o jogador está na fase de posicionamento THEN o sistema SHALL permitir mover peças já posicionadas
2. WHEN o jogador arrasta uma peça THEN o sistema SHALL mostrar visualmente as posições válidas
3. WHEN o jogador tenta posicionar uma peça em área inválida THEN o sistema SHALL mostrar feedback visual de erro
4. WHEN o jogador posiciona uma peça sobre outra THEN o sistema SHALL trocar as posições das peças
5. WHEN o jogador remove uma peça do tabuleiro THEN o sistema SHALL devolver a peça ao inventário
6. IF o inventário está vazio THEN o sistema SHALL habilitar o botão "PRONTO"
7. IF o inventário não está vazio THEN o sistema SHALL manter o botão "PRONTO" desabilitado

### Requirement 3

**User Story:** Como um jogador, eu quero confirmar quando terminar de posicionar minhas peças, para que o jogo possa prosseguir quando ambos jogadores estiverem prontos.

#### Acceptance Criteria

1. WHEN todas as 40 peças estão posicionadas THEN o sistema SHALL habilitar o botão "PRONTO"
2. WHEN o jogador clica em "PRONTO" THEN o sistema SHALL enviar confirmação para o servidor
3. WHEN o jogador confirma THEN o sistema SHALL desabilitar a edição do posicionamento
4. WHEN apenas um jogador confirmou THEN o sistema SHALL exibir "Aguardando oponente..."
5. WHEN ambos jogadores confirmaram THEN o sistema SHALL iniciar a partida
6. WHEN a partida inicia THEN o sistema SHALL ocultar as peças do oponente e mostrar apenas silhuetas

### Requirement 4

**User Story:** Como um jogador, eu quero ver o progresso do meu oponente sem ver suas peças, para saber quando ele está pronto.

#### Acceptance Criteria

1. WHEN o oponente está posicionando peças THEN o sistema SHALL mostrar "Oponente posicionando peças..."
2. WHEN o oponente confirma THEN o sistema SHALL mostrar "Oponente pronto! Aguardando você..."
3. WHEN ambos confirmam THEN o sistema SHALL mostrar "Iniciando partida..." por 3 segundos
4. WHEN a partida inicia THEN o sistema SHALL mostrar o tabuleiro de jogo normal
5. IF um jogador desconecta durante posicionamento THEN o sistema SHALL retornar ambos para busca de oponente

### Requirement 5

**User Story:** Como um jogador, eu quero ter uma interface intuitiva para posicionar peças, para que o processo seja rápido e eficiente.

#### Acceptance Criteria

1. WHEN o inventário é exibido THEN o sistema SHALL agrupar peças por tipo com contador
2. WHEN o jogador seleciona um tipo de peça THEN o sistema SHALL destacar visualmente a seleção
3. WHEN o jogador posiciona peças THEN o sistema SHALL mostrar animações suaves
4. WHEN há erro de posicionamento THEN o sistema SHALL mostrar feedback visual claro
5. WHEN o jogador está posicionando THEN o sistema SHALL mostrar dicas visuais das áreas válidas
6. WHEN o processo está completo THEN o sistema SHALL mostrar confirmação visual clara

### Requirement 6

**User Story:** Como desenvolvedor, eu quero que o sistema seja robusto contra desconexões, para que a experiência do usuário seja consistente.

#### Acceptance Criteria

1. WHEN um jogador desconecta durante posicionamento THEN o sistema SHALL salvar o estado atual
2. WHEN o jogador reconecta THEN o sistema SHALL restaurar o posicionamento parcial
3. WHEN o oponente desconecta THEN o sistema SHALL notificar e aguardar reconexão por 60 segundos
4. IF o oponente não reconecta THEN o sistema SHALL retornar para busca de novo oponente
5. WHEN há erro de rede THEN o sistema SHALL tentar reconectar automaticamente
6. WHEN a reconexão falha THEN o sistema SHALL mostrar opção de tentar novamente

### Requirement 7

**User Story:** Como um jogador, eu quero que o posicionamento seja validado, para garantir que as regras do jogo sejam respeitadas.

#### Acceptance Criteria

1. WHEN o jogador posiciona peças THEN o sistema SHALL validar que estão na área correta (4 linhas)
2. WHEN o jogador confirma THEN o sistema SHALL validar que todas as 40 peças estão posicionadas
3. WHEN há peças faltando THEN o sistema SHALL mostrar quais peças ainda precisam ser posicionadas
4. WHEN o posicionamento é inválido THEN o sistema SHALL impedir a confirmação
5. IF há peças sobrepostas THEN o sistema SHALL resolver automaticamente ou mostrar erro
6. WHEN a validação passa THEN o sistema SHALL permitir prosseguir para o jogo
