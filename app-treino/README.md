# Ferro & Rotina — app de treino ABCD

App de treino pessoal, feito em cima da rotina ABCD (Peito/Tríceps, Costas/Bíceps,
Pernas, Ombros/Trapézio) com foco em emagrecimento mantendo a força.

Página única, sem back-end, sem conta e sem rastreamento. Tudo é salvo no
`localStorage` do próprio navegador e funciona offline depois da primeira visita.

## Como usar

**No computador:** abra `index.html` no navegador.

**No celular (recomendado):** publique a pasta em qualquer host estático e abra
o endereço no celular. Com GitHub Pages:

1. `Settings → Pages → Deploy from a branch`, apontando para a branch e a pasta `/app-treino`.
2. Abra a URL no celular e use *Adicionar à tela de início* — ele instala como
   app (`manifest.webmanifest` + service worker) e passa a abrir em tela cheia,
   inclusive sem internet.

O service worker só registra em `http://` ou `https://`; abrindo o arquivo direto
por `file://` o app funciona normalmente, mas sem o modo offline instalado.

## O que ele faz

| Aba | Função |
|---|---|
| **Hoje** | Sugere o próximo treino do ciclo ABCD, mostra o peso atual contra a meta, os treinos da semana e as metas de calorias, proteína e ritmo de perda. |
| **Treinos** | Os quatro treinos completos: aquecimento, exercícios, séries, repetições e descanso. |
| **Sessão** | Registro série a série (carga e repetições), cronômetro de descanso automático com alerta sonoro e vibração, volume e tempo acumulados em tempo real. |
| **Peso** | Registro de peso, gráfico de evolução, IMC, ritmo semanal por regressão linear dos últimos 28 dias e projeção da data da meta. |
| **Histórico** | Sessões salvas, volume por treino e a maior carga já registrada em cada exercício. |
| **Ajustes** | Altura, idade, peso inicial, meta, sexo, nível de atividade, ajuste de descanso, alerta, tema e exportar/importar/apagar dados. |

## Detalhes de funcionamento

- **Sugestão de carga.** Ao iniciar um treino, cada série vem pré-preenchida com
  a maior carga da última vez. Quando todas as séries do exercício bateram o topo
  da faixa de repetições, o app sugere subir a carga (2,5 kg no geral, 5 kg no leg
  press, 1 kg na elevação lateral).
- **Descanso.** O cronômetro dispara sozinho ao marcar uma série e usa o descanso
  do plano, com ajuste global de ±30s em Ajustes. Ele conta por horário absoluto,
  então volta correto mesmo se a tela do celular apagar — só o alerta pode atrasar
  se o navegador tiver suspendido a aba.
- **Gasto calórico.** Mifflin-St Jeor multiplicado pelo fator de atividade, menos
  cerca de 500–600 kcal. Sem sexo informado, usa a média entre as fórmulas
  masculina e feminina. É estimativa: quem calibra é a balança ao longo de
  2 a 3 semanas.
- **Escala do gráfico de peso.** O eixo acompanha os registros para a variação
  semanal ficar visível; a linha da meta entra no gráfico quando o peso chega
  perto dela, em vez de achatar a curva desde o começo.
- **Backup.** Limpar os dados do navegador apaga o histórico. Exporte o JSON em
  Ajustes de tempos em tempos, principalmente antes de trocar de aparelho.

## Estrutura

```
app-treino/
├── index.html            # app inteiro: marcação, estilos e lógica
├── manifest.webmanifest  # instalação como PWA
├── sw.js                 # cache offline
├── icon.svg              # ícone (any)
└── icon-maskable.svg     # ícone (maskable)
```

Os treinos ficam no objeto `PROGRAM`, no topo do `<script>` do `index.html` —
é ali que se troca exercício, séries, repetições, descanso ou dica de execução.

## Aviso

O app organiza o treino e faz contas de estimativa; ele não substitui avaliação
profissional. Acompanhamento com médico e nutricionista é recomendado, e vale ter
um educador físico conferindo a execução, principalmente em agachamento, stiff e
supino. Dor articular não é normal: pare a série e reveja carga e execução.
