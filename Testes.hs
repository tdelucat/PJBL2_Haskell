{-# OPTIONS_GHC -Wall #-}
-- Testes do PjBL2. Com o GHC local, na pasta do projeto:
--   ghc -Wall Testes.hs -main-is Testes -o testes
module Testes where

import Main hiding (main)

main :: IO ()
main = testes

-- ===== Testes (no Playground, cole a partir daqui no fim do Main.hs) =====

testar :: (Eq a, Show a) => String -> a -> a -> IO ()
testar nome obtido esperado
  | obtido == esperado = putStrLn ("OK      " ++ nome)
  | otherwise          = putStrLn ("FALHOU  " ++ nome ++ ": " ++ show obtido)

-- O campeonato de teste já lido. Se a leitura falhar, fica vazio
-- e os testes que dependem dele falham (a leitura é testada na Camada 3).
campeonato :: [Partida]
campeonato = case lerCampeonato dadosCampeonato of
  Right ps -> ps
  Left _   -> []

jogo :: Partida
jogo = Partida 1 "Coritiba" 3 0 "Operário"

-- Conferidas à mão (ver docs/decisoes.md).
-- Campos: time, jogos, vitórias, empates, derrotas, gols pró, gols contra.
tabelaFinal :: [Linha]
tabelaFinal =
  [ Linha "Coritiba"  5 3 1 1 9 5
  , Linha "Operário"  5 3 1 1 7 7
  , Linha "Londrina"  5 2 2 1 10 7
  , Linha "Athletico" 5 1 3 1 4 4
  , Linha "Maringá"   5 1 1 3 10 11
  , Linha "Paraná"    5 0 2 3 3 9
  ]

tabelaRodada3 :: [Linha]
tabelaRodada3 =
  [ Linha "Londrina"  3 2 0 1 7 4
  , Linha "Coritiba"  3 2 0 1 5 3
  , Linha "Athletico" 3 1 2 0 4 2
  , Linha "Operário"  3 1 1 1 3 5
  , Linha "Maringá"   3 1 0 2 6 6
  , Linha "Paraná"    3 0 1 2 0 5
  ]

nomesNaOrdem :: [Partida] -> [Time]
nomesNaOrdem ps = map time (classificacao ps)

posicoesDosTimes :: [(Time, Cartoes)] -> [Time] -> [Partida] -> [(Int, Time)]
posicoesDosTimes cartoes sorteio = map (\(pos, l) -> (pos, time l)) . classificacaoComDesempate cartoes sorteio

doisEmpatados :: [Partida]
doisEmpatados = [Partida 1 "A" 1 1 "Z", Partida 2 "Z" 0 0 "A"]

tresEmpatados :: [Partida]
tresEmpatados =
  [ Partida 1 "A" 0 1 "Z", Partida 2 "Z" 0 0 "A"
  , Partida 3 "B" 0 1 "A", Partida 4 "A" 0 0 "B"
  , Partida 5 "Z" 0 1 "B", Partida 6 "B" 0 0 "Z" ]

testes :: IO ()
testes = do
  putStrLn "--- Camada 1 ---"
  testar "resultadoPara do mandante" (resultadoPara "Coritiba" jogo) (Just Vitoria)
  testar "resultadoPara do visitante" (resultadoPara "Operário" jogo) (Just Derrota)
  testar "resultadoPara de quem não jogou" (resultadoPara "Paraná" jogo) Nothing
  testar "empate vale para os dois lados"
    (map (\t -> resultadoPara t (Partida 1 "A" 0 0 "B")) ["A", "B"]) [Just Empate, Just Empate]
  testar "visitante também vence" (resultadoPara "B" (Partida 1 "A" 0 1 "B")) (Just Vitoria)
  testar "participou" (map (\t -> participou t jogo) ["Coritiba", "Operário", "Paraná"]) [True, True, False]
  testar "times sem repetição e em ordem" (times campeonato)
    ["Athletico", "Coritiba", "Londrina", "Maringá", "Operário", "Paraná"]
  testar "times de lista vazia" (times []) []
  testar "15 partidas em 5 rodadas, 3 por rodada" (map rodada campeonato)
    [1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5]

  putStrLn "--- Camada 2 ---"
  testar "pontos por resultado" (map pontos [Vitoria, Empate, Derrota]) [3, 1, 0]
  testar "linhaDoTime do Coritiba" (linhaDoTime campeonato "Coritiba") (Linha "Coritiba" 5 3 1 1 9 5)
  testar "pontos e saldo do Coritiba"
    (pontosLinha (linhaDoTime campeonato "Coritiba"), saldo (linhaDoTime campeonato "Coritiba")) (10, 4)
  testar "aproveitamento: 3 de 9 pontos" (aproveitamento (Linha "A" 3 1 0 2 2 3)) (100 / 3)
  testar "aproveitamento de quem não jogou" (aproveitamento (linhaDoTime campeonato "Ausente")) 0
  testar "classificação final" (classificacao campeonato) tabelaFinal
  testar "desempate: Coritiba e Operário com 10 pontos e 3 vitórias, saldo decide"
    [ (time l, pontosLinha l, vitorias l, saldo l) | l <- take 2 (classificacao campeonato) ]
    [("Coritiba", 10, 3, 4), ("Operário", 10, 3, 0)]
  testar "desempate por vitórias, mesmo com saldo pior"
    (filter (`elem` ["A", "Z"]) (nomesNaOrdem
      [ Partida 1 "Z" 1 0 "D", Partida 2 "Z" 0 5 "F"
      , Partida 1 "A" 0 0 "E", Partida 2 "A" 0 0 "E", Partida 3 "A" 0 0 "E" ]))
    ["Z", "A"]
  testar "desempate por gols pró"
    (nomesNaOrdem [Partida 1 "Z" 2 2 "A", Partida 2 "Z" 2 2 "D", Partida 2 "A" 1 1 "E"])
    ["Z", "A", "D", "E"]
  testar "empate sem dados adicionais mantém a mesma posição"
    (posicoesDosTimes [] [] doisEmpatados) [(1, "A"), (1, "Z")]
  testar "confronto direto por pontos dos dois jogos"
    (filter (`elem` ["A", "Z"]) (nomesNaOrdem
      [ Partida 1 "Z" 1 0 "A", Partida 2 "A" 0 0 "Z"
      , Partida 3 "A" 1 0 "B", Partida 3 "Z" 0 1 "C" ]))
    ["Z", "A"]
  testar "confronto direto por saldo quando seus pontos empatam"
    (filter (`elem` ["A", "Z"]) (nomesNaOrdem
      [ Partida 1 "Z" 3 0 "A", Partida 2 "A" 1 0 "Z"
      , Partida 3 "Z" 0 5 "C", Partida 3 "A" 2 3 "B" ]))
    ["Z", "A"]
  testar "um jogo direto sozinho deixa o empate aberto"
    (filter ((`elem` ["A", "Z"]) . snd) (posicoesDosTimes [] []
      [ Partida 1 "Z" 1 0 "A", Partida 2 "A" 1 0 "B", Partida 2 "Z" 0 1 "C" ]))
    [(2, "A"), (2, "Z")]
  testar "três times empatados pulam o confronto direto"
    (posicoesDosTimes [] [] tresEmpatados) [(1, "A"), (1, "B"), (1, "Z")]
  testar "cartões vermelhos decidem antes dos amarelos"
    (posicoesDosTimes [("A", Cartoes 2 0), ("B", Cartoes 0 20), ("Z", Cartoes 1 0)] [] tresEmpatados)
    [(1, "B"), (2, "Z"), (3, "A")]
  testar "cartões amarelos decidem quando os vermelhos são iguais"
    (posicoesDosTimes [("A", Cartoes 2 5), ("Z", Cartoes 2 3)] [] doisEmpatados)
    [(1, "Z"), (2, "A")]
  testar "classificação aplica o resultado do sorteio informado"
    (posicoesDosTimes [("A", Cartoes 1 2), ("Z", Cartoes 1 2)] ["Z", "A"] doisEmpatados)
    [(1, "Z"), (2, "A")]
  testar "cartões incompletos mantêm o empate"
    (posicoesDosTimes [("Z", Cartoes 0 0)] ["Z", "A"] doisEmpatados)
    [(1, "A"), (1, "Z")]
  testar "classificação após a rodada 3" (classificacao (ateRodada 3 campeonato)) tabelaRodada3
  testar "rodada 3 é diferente da final" (classificacao (ateRodada 3 campeonato) /= tabelaFinal) True
  testar "ateRodada 0" (ateRodada 0 campeonato) []
  testar "classificação sem partidas" (classificacao []) []
  testar "maior goleada fica com a primeira diferença de 3" (maiorGoleada campeonato) (Just jogo)
  testar "maior goleada de lista vazia" (maiorGoleada []) Nothing
  testar "média de gols: 43 gols em 15 jogos" (mediaGols campeonato) (Just (43 / 15))
  testar "média de lista vazia" (mediaGols []) Nothing
  testar "média soma placares grandes sem estourar Int"
    (mediaGols [Partida 1 "A" maxBound maxBound "B"]) (Just (2 * fromIntegral (maxBound :: Int)))

  putStrLn "--- Camada 3 ---"
  testar "campeonato de teste é válido" (fmap length (lerCampeonato dadosCampeonato)) (Right 15)
  testar "lerPartida com espaços nos campos"
    (lerPartida 1 " 2 ; Paraná ; 0 ; 3 ; Maringá ") (Right (Partida 2 "Paraná" 0 3 "Maringá"))
  testar "comentário, linha vazia e \\r\\n"
    (fmap length (lerCampeonato "# comentário\r\n\r\n1;A;0;0;B\r\n")) (Right 1)
  testar "texto vazio é um campeonato sem partidas" (lerCampeonato "") (Right [])
  testar "CamposInvalidos: campo faltando" (lerPartida 8 "1;A;1;0") (Left (CamposInvalidos 8))
  testar "CamposInvalidos: nome vazio" (lerPartida 8 "1;A;1;0; ") (Left (CamposInvalidos 8))
  testar "NumeroInvalido: placar \"dois\"" (lerPartida 9 "1;A;dois;0;B") (Left (NumeroInvalido 9 "dois"))
  testar "NumeroInvalido: placar \"2a\"" (lerPartida 9 "1;A;0;2a;B") (Left (NumeroInvalido 9 "2a"))
  testar "placar acima de maxBound é rejeitado"
    (lerPartida 1 "1;A;18446744073709551616;0;B") (Left (NumeroInvalido 1 "18446744073709551616"))
  let abaixo = show (toInteger (minBound :: Int) - 1)
      limite = show (maxBound :: Int)
  testar "rodada abaixo de minBound é rejeitada"
    (lerPartida 1 (abaixo ++ ";A;0;0;B")) (Left (NumeroInvalido 1 abaixo))
  testar "o maior placar que cabe em Int é preservado"
    (lerPartida 1 ("1;A;" ++ limite ++ ";0;B")) (Right (Partida 1 "A" maxBound 0 "B"))
  testar "TotalDeGolsInvalido aparece na linha em que a soma passa do limite"
    (lerCampeonato ("1;A;" ++ limite ++ ";0;B\n2;A;1;0;C")) (Left (TotalDeGolsInvalido 2 "A"))
  testar "PlacarNegativo" (lerPartida 9 "1;A;0;-2;B") (Left (PlacarNegativo 9))
  testar "MesmoTime" (lerPartida 9 "1;A;1;1;A") (Left (MesmoTime 9 "A"))
  testar "RodadaInvalida" (lerPartida 9 "0;A;1;1;B") (Left (RodadaInvalida 9))
  testar "TimeRepetidoNaRodada" (lerCampeonato "1;A;0;0;B\n1;C;1;2;A") (Left (TimeRepetidoNaRodada 2 1 "A"))
  testar "mesmo time em outra rodada pode" (fmap length (lerCampeonato "1;A;0;0;B\n2;C;1;2;A")) (Right 2)
  testar "lerCampeonato para no primeiro erro" (lerCampeonato dadosComErros) (Left (NumeroInvalido 4 "dois"))
  testar "time repetido na linha 2 vem antes do placar inválido na linha 3"
    (lerCampeonato "1;A;0;0;B\n1;C;0;0;A\n2;C;dois;0;A") (Left (TimeRepetidoNaRodada 2 1 "A"))
  testar "lerPartida mostra o primeiro de vários problemas"
    (lerPartida 1 "1;A;-1;-2;A") (Left (PlacarNegativo 1))
  testar "todosOsErros lista placar negativo e mesmo time na mesma linha"
    (todosOsErros "1;A;-1;-2;A") [PlacarNegativo 1, MesmoTime 1 "A"]
  testar "todosOsErros lista falhas de conversão e validações independentes"
    (todosOsErros "0;A;dois;-1;A\n4;;x;y;B")
    [ NumeroInvalido 1 "dois", RodadaInvalida 1, PlacarNegativo 1, MesmoTime 1 "A"
    , NumeroInvalido 2 "x", NumeroInvalido 2 "y", CamposInvalidos 2 ]
  testar "dois times repetidos são reportados mesmo com placar inválido"
    (todosOsErros "1;A;0;0;B\n1;B;dois;0;A")
    [NumeroInvalido 2 "dois", TimeRepetidoNaRodada 2 1 "B", TimeRepetidoNaRodada 2 1 "A"]
  testar "todosOsErros lista os 5 erros, em ordem de linha" (todosOsErros dadosComErros)
    [ NumeroInvalido 4 "dois", PlacarNegativo 5, TimeRepetidoNaRodada 6 1 "Paraná"
    , MesmoTime 7 "Londrina", CamposInvalidos 8 ]
  testar "todosOsErros de entrada válida" (todosOsErros dadosCampeonato) []
  testar "separar mantém campos vazios" (separar ';' "a;;b;") ["a", "", "b", ""]
  testar "tabela vazia" (tabelaFormatada []) "Nenhuma partida para classificar.\n"
  testar "tabela mostra posição compartilhada"
    (map (take 2 . words) (drop 2 (lines (tabelaComPosicoes (classificacaoComDesempate [] [] doisEmpatados)))))
    [["1", "A"], ["1", "Z"]]
  testar "tabela mantém separado um saldo que ocupa mais de cinco colunas"
    (map words (drop 2 (lines (tabelaFormatada [Linha "A" 1 1 0 0 maxBound 0]))))
    [["1", "A", "3", "1", "1", "0", "0", limite]]
  testar "tabela com saldo negativo"
    (map words (lines (tabelaFormatada [Linha "Paraná" 1 0 0 1 0 2])))
    [ ["Pos", "Time", "Pts", "J", "V", "E", "D", "SG"]
    , [replicate 41 '-']
    , ["1", "Paraná", "0", "1", "0", "0", "1", "-2"] ]
