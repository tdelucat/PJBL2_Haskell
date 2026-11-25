# PjBL2 — Tabela de Classificação de Campeonato (Haskell)

Programação Lógica e Funcional — PUCPR

**Grupo 1:** Carlos Eduardo do Rosario Paulino, Davi Prestes Miessa, Gustavo Hideaki Simabuco e Tales Deluca Tareszkiewicz Rezende

## Ambiente

O projeto foi preparado para o [Haskell Playground](https://play.haskell.org/) com **GHC 9.10.3**. O `Main.hs` contém as seções Tipos, Classificação, Leitura, Dados e Main e usa apenas a biblioteca padrão.

## Como executar

**No Playground:** cole o conteúdo de `Main.hs` no editor e clique em **Run**.

**Com o GHC instalado:**

```text
ghc -Wall Main.hs -o campeonato
./campeonato
```

No Windows, execute `.\campeonato.exe`.

A demonstração mostra os jogos do Coritiba, a tabela final, a tabela depois da 3ª rodada e as estatísticas. No fim, mostra o primeiro erro de uma entrada inválida e a lista completa de erros.

## Testes

**Com o GHC instalado:**

```text
ghc -Wall Testes.hs -main-is Testes -o testes
./testes
```

**No Playground:** cole `Main.hs`, cole embaixo o trecho de `Testes.hs` que começa em `-- ===== Testes` e acrescente a linha `  testes` no fim do `main`. Ao rodar, a demonstração aparece primeiro e depois os testes.

Cada teste imprime `OK` ou `FALHOU`, com o valor obtido. São 66 testes, separados por camada.

## Formato da entrada

Uma partida por linha, com os campos separados por ponto e vírgula. Linhas em branco e linhas que começam com `#` são ignoradas.

```text
# rodada;mandante;gols mandante;gols visitante;visitante
1;Athletico;0;0;Paraná
1;Coritiba;3;0;Operário
```

Os dados ficam no próprio código (`dadosCampeonato` e `dadosComErros`), porque o Playground não tem entrada pelo teclado.

## Classificação

Os 15 jogos de exemplo são fictícios. O desempate segue o art. 15 do regulamento da Série A de 2026. `classificacaoComDesempate` recebe, além dos jogos, os cartões acumulados por time e a ordem apurada em eventual sorteio. Se os dados disponíveis não resolverem um empate, os times dividem a posição na tabela. Nenhum empate do campeonato de exemplo chega aos cartões.

## Arquivos

- `Main.hs` reúne as três camadas, os dados e a demonstração.
- `Testes.hs` reúne os casos de teste e os resultados esperados.
- `docs/decisoes.md` explica as decisões, os limites e a conferência da tabela.
