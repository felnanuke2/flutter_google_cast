---
name: premium-visual-truco
description: >
  Aplica estilo visual premium metallic-dark da lobby em outras views do Truco.
  Usa tokens da paleta oficial, tipografia Unbounded, metallic finish,
  profundidade e hierarquia agressiva. Para usar: preencha View alvo,
  Componentes alvo, e cole no chat junto com arquivos da view.
---

## Objetivo

Aplicar o mesmo estilo visual premium metallic-dark da lobby em outra view, mantendo consistencia de branding e UX.

## Contexto do produto

- App de jogo de cartas (Truco), atmosfera competitiva, premium e moderna.
- Interface deve transmitir mesa de jogo, profundidade, contraste e leitura rapida.

## Referencias obrigatorias

- Paleta/tokens: theme.css
- Tipografia/tokens: typography.css
- Guia de cores: colors.md
- Linguagem visual de referencia: lobbyFancy.css

## Regras obrigatorias (hard constraints)

1. **Usar estritamente os tokens da paleta existente** — nenhuma cor nova.
2. **Nao introduzir roxo ou gradientes fora da paleta** — apenas cores oficiais.
3. **Manter tipografia Unbounded e hierarquia agressiva de titulos** — bold, uppercase quando apropriado.
4. **Criar profundidade com camadas, brilho metalico e sombras controladas** — metallic finish em paineis.
5. **Preservar layout responsivo mobile e desktop** — breakpoints existentes.
6. **Nao quebrar logica existente nem alterar comportamento funcional** — apenas CSS.
7. **Evitar inline style quando possivel** — preferir classes CSS coesas e reutilizaveis.
8. **Garantir boa legibilidade** — texto principal e secundario com contraste adequado WCAG.

## Direcao estetica

- Fundo com atmosfera de mesa (dark charcoal + highlights sutis).
- Cards/paineis com acabamento metalico (ouro/prata/bronze por hierarquia).
- Estados visuais claros: loading, erro, vazio, sucesso.
- Microinteracoes curtas e significativas (hover, focus, pressed).

## Escopo da tarefa

- View alvo: [COLOQUE_AQUI_O_ARQUIVO_DA_VIEW]
- Componentes alvo: [LISTA_DE_COMPONENTES]
- Nao mexer em: [COMPONENTES_SENSIVEIS]

## Copia e UX writing

- **Tom**: competitivo, elegante, linguagem de mesa de truco.
- Trocar textos genericos por textos tematicos, sem alterar chaves de i18n.
- Evitar texto longo em elementos de acao.

## Entrega esperada

1. Implementar estilos na view alvo com classes CSS.
2. Reaproveitar padroes de naming e estrutura visual da lobby.
3. Informar quais arquivos foram alterados.
4. Validar erros TypeScript/lint apos alteracoes.
5. Resumo final com o que foi feito e por que.

## Auto-check antes de finalizar

- [ ] Todos os tokens vem da paleta oficial?
- [ ] A view parece da mesma familia da lobby?
- [ ] Mobile ficou bom?
- [ ] Nenhuma regressao funcional?
- [ ] Sem erros de compilacao/lint?

## Como usar no dia a dia

1. Copie esse Prompt Master.
2. Preencha View alvo + Componentes alvo.
3. Cole no chat junto com o arquivo da view.
4. Peça explicitamente: **aplicar estilo premium metallic-dark da lobby com paleta estrita**.
