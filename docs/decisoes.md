# Decisões de modelagem

## Tipos e acúmulo

`Partida` tem os cinco campos da entrada. Em `Linha` ficam as contagens da campanha. Pontos, saldo e aproveitamento são calculados a partir delas, para evitar dois valores gravados para a mesma informação. `resultadoPara` devolve `Nothing` para um time que não jogou a partida.

`linhaDoTime` usa `filter` para separar os jogos do time e `foldl` para acumular as contagens a partir de uma linha zerada. `maiorGoleada` fica com a primeira partida quando a diferença de gols se repete. A goleada e a média devolvem `Nothing` se a lista estiver vazia. O aproveitamento de quem não jogou é zero.

## Desempate

Os jogos são fictícios e a ordem segue o art. 15 da Série A de 2026. Primeiro, `sortBy` ordena pontos, vitórias, saldo e gols pró em ordem decrescente. `comparing` indica o valor comparado, `Down` inverte a ordem e `<>` passa ao próximo critério quando o anterior retornou `EQ`.

Quem continua empatado fica junto com `groupBy`. Para um grupo de dois clubes, a lista de partidas permite encontrar o jogo de ida e o de volta. Com os dois jogos, comparamos primeiro os pontos e depois o saldo nesse confronto. Grupos com mais de dois clubes passam direto para os cartões. Nas tabelas parciais ou de turno único, o confronto só é aplicado se os dois mandos aparecerem na entrada.

`classificacaoComDesempate` recebe os totais de cartões por time no mesmo recorte de partidas. Com os totais de todos os integrantes de um grupo, compara primeiro o menor número de vermelhos, depois o menor número de amarelos. Se ainda houver empate, pode usar a ordem do sorteio já realizado. Sem os dados necessários, os clubes ficam na mesma posição. Por exemplo, dois clubes empatados em primeiro aparecem com posição 1, e o próximo aparece com posição 3.

`classificacao` mantém a assinatura do enunciado e devolve somente as linhas obtidas com os placares. A demonstração usa `classificacaoComDesempate` para que a formatação preserve eventuais posições compartilhadas.

[Regulamento Específico da Série A de 2026, art. 15](https://stcbfsiteprdimgbrs.blob.core.windows.net/img-site/cdn/REC_Brasileiro_SA_rie_A_2026_v15_12_2025_final_02692c1077.pdf#page=10)

## Leitura e validação

Os números são lidos primeiro como `Integer`, com `readMaybe`. A conversão para `Int` só acontece para valores entre `minBound` e `maxBound`. Na leitura do campeonato, a linha em que um total de gols pró ou contra ultrapassa esse limite também gera erro. A média usa `Integer` na soma para comportar placares grandes de vários times.

A lista é numerada antes de remover linhas em branco e comentários. `analisarLinha` reúne os erros que podem ser verificados separadamente. Por exemplo, `1;A;-1;-2;A` gera um erro para o placar e outro para o time enfrentar a si mesmo. O erro de placar negativo é registrado uma vez por partida.

`scanl` fornece o histórico anterior a cada linha. Só entram no histórico partidas válidas quando consideradas isoladamente. Uma linha com placar inválido ainda pode apontar um time repetido, se a rodada e o nome puderem ser lidos e o time já constar no histórico. Com o número de campos errado, o programa aponta a estrutura inválida.

`lerPartida` encadeia as etapas com `do` em `Either`. Para o texto inteiro, `lerCampeonato` usa `traverse` nas linhas já associadas a seus históricos. Assim, uma repetição na linha 2 é devolvida antes de um placar malformado na linha 3. `todosOsErros` concatena as listas de erros na ordem em que as linhas aparecem.

## Conferência feita à mão

Exemplo do Coritiba: venceu Operário (3 x 0), Paraná (2 x 0) e Athletico (2 x 0), empatou com o Maringá (2 x 2) e perdeu para o Londrina (0 x 3). Fez 9 gols e sofreu 5, então tem 3 × 3 + 1 = 10 pontos e saldo 9 − 5 = 4. O Operário também tem 10 pontos e 3 vitórias, mas saldo 0, por isso fica em segundo. É o caso de desempate do campeonato de teste: o critério que decide é o saldo.

### Classificação final

| Pos | Time | Pts | J | V | E | D | GP | GC | SG |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | Coritiba | 10 | 5 | 3 | 1 | 1 | 9 | 5 | 4 |
| 2 | Operário | 10 | 5 | 3 | 1 | 1 | 7 | 7 | 0 |
| 3 | Londrina | 8 | 5 | 2 | 2 | 1 | 10 | 7 | 3 |
| 4 | Athletico | 6 | 5 | 1 | 3 | 1 | 4 | 4 | 0 |
| 5 | Maringá | 4 | 5 | 1 | 1 | 3 | 10 | 11 | -1 |
| 6 | Paraná | 2 | 5 | 0 | 2 | 3 | 3 | 9 | -6 |

### Depois da 3ª rodada

| Pos | Time | Pts | J | V | E | D | GP | GC | SG |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | Londrina | 6 | 3 | 2 | 0 | 1 | 7 | 4 | 3 |
| 2 | Coritiba | 6 | 3 | 2 | 0 | 1 | 5 | 3 | 2 |
| 3 | Athletico | 5 | 3 | 1 | 2 | 0 | 4 | 2 | 2 |
| 4 | Operário | 4 | 3 | 1 | 1 | 1 | 3 | 5 | -2 |
| 5 | Maringá | 3 | 3 | 1 | 0 | 2 | 6 | 6 | 0 |
| 6 | Paraná | 1 | 3 | 0 | 1 | 2 | 0 | 5 | -5 |

Na 3ª rodada o líder é o Londrina, e no fim é o Coritiba. Londrina e Coritiba têm 6 pontos e 2 vitórias, e o saldo (3 contra 2) decide.

As 15 partidas somam 43 gols, uma média de 43 / 15 ≈ 2,9 por jogo. A maior diferença é de 3 gols, e a primeira partida com essa diferença é Coritiba 3 x 0 Operário, na 1ª rodada.

## Limitações

- Os nomes são comparados como aparecem nos dados depois de retirar os espaços nas pontas. `Paraná` e `Parana` representam times distintos. O ponto e vírgula é reservado para separar campos.
- O programa aceita campeonatos parciais e não confere se o calendário tem todos os jogos da Série A. A entrada de resultados mantém cinco campos. Cartões acumulados e ordem de sorteio, quando disponíveis, são informados como dados Haskell na chamada à classificação.
- A validação consulta as partidas anteriores para conferir repetições e limites. Essa busca é suficiente para o campeonato de exemplo e cresce com a quantidade de linhas.
- Para executar em terminal local, use a codificação UTF-8 para exibir os acentos.
