{-# OPTIONS_GHC -Wall #-}
module Main where

import Data.Char (isSpace)
import Data.Either (lefts)
import Data.List (dropWhileEnd, elemIndex, groupBy, intercalate, nub, sort, sortBy, sortOn)
import Data.Ord (Down (..), comparing)
import Text.Read (readMaybe)

-- ===== Tipos (Camada 1) =====

type Time = String

data Resultado = Vitoria | Empate | Derrota
  deriving (Show, Eq)

data Partida = Partida
  { rodada        :: Int
  , mandante      :: Time
  , golsMandante  :: Int
  , golsVisitante :: Int
  , visitante     :: Time
  } deriving (Show, Eq)

data Linha = Linha
  { time       :: Time
  , jogos      :: Int
  , vitorias   :: Int
  , empates    :: Int
  , derrotas   :: Int
  , golsPro    :: Int
  , golsContra :: Int
  } deriving (Show, Eq)

data Cartoes = Cartoes
  { vermelhos :: Int
  , amarelos  :: Int
  } deriving (Show, Eq)

participou :: Time -> Partida -> Bool
participou t p = mandante p == t || visitante p == t

-- O time já deve ter sido encontrado na partida.
golsDoTime :: Time -> Partida -> (Int, Int)
golsDoTime t p
  | mandante p == t = (golsMandante p, golsVisitante p)
  | otherwise       = (golsVisitante p, golsMandante p)

resultadoDoPlacar :: Int -> Int -> Resultado
resultadoDoPlacar pro contra = case compare pro contra of
  GT -> Vitoria
  EQ -> Empate
  LT -> Derrota

resultadoPara :: Time -> Partida -> Maybe Resultado
resultadoPara t p
  | participou t p = Just (resultadoDoPlacar pro contra)
  | otherwise      = Nothing
  where
    (pro, contra) = golsDoTime t p

times :: [Partida] -> [Time]
times ps = sort (nub (map mandante ps ++ map visitante ps))

-- ===== Classificacao (Camada 2) =====

pontos :: Resultado -> Int
pontos Vitoria = 3
pontos Empate  = 1
pontos Derrota = 0

umSe :: Bool -> Int
umSe True  = 1
umSe False = 0

linhaDoTime :: [Partida] -> Time -> Linha
linhaDoTime partidas t = foldl somarPartida inicial (filter (participou t) partidas)
  where
    inicial = Linha t 0 0 0 0 0 0
    somarPartida linha p =
      let (pro, contra) = golsDoTime t p
          r             = resultadoDoPlacar pro contra
      in linha { jogos      = jogos linha + 1
               , vitorias   = vitorias linha + umSe (r == Vitoria)
               , empates    = empates linha + umSe (r == Empate)
               , derrotas   = derrotas linha + umSe (r == Derrota)
               , golsPro    = golsPro linha + pro
               , golsContra = golsContra linha + contra
               }

pontosLinha :: Linha -> Int
pontosLinha l = vitorias l * pontos Vitoria + empates l * pontos Empate

saldo :: Linha -> Int
saldo l = golsPro l - golsContra l

aproveitamento :: Linha -> Double
aproveitamento l
  | jogos l == 0 = 0
  | otherwise    = 100 * fromIntegral (pontosLinha l) / (3 * fromIntegral (jogos l))

criterios :: Linha -> Linha -> Ordering
criterios = comparing (Down . pontosLinha)
         <> comparing (Down . vitorias)
         <> comparing (Down . saldo)
         <> comparing (Down . golsPro)

classificacao :: [Partida] -> [Linha]
classificacao = map snd . classificacaoComDesempate [] []

agruparPor :: (a -> a -> Ordering) -> [a] -> [[a]]
agruparPor comparar = groupBy (\a b -> comparar a b == EQ) . sortBy comparar

confrontoDireto :: [Partida] -> [Linha] -> [[Linha]]
confrontoDireto partidas grupo@[a, b]
  | sort (map mandante jogosDiretos) == sort [time a, time b] =
      agruparPor (comparing (Down . desempenhoDireto)) grupo
  where
    jogosDiretos = filter (\p -> participou (time a) p && participou (time b) p) partidas
    desempenhoDireto l =
      let linha = linhaDoTime jogosDiretos (time l)
      in (pontosLinha linha, saldo linha)
confrontoDireto _ grupo = [grupo]

desempatarPorCartoes :: [(Time, Cartoes)] -> [Time] -> [Linha] -> [[Linha]]
desempatarPorCartoes cartoes sorteio grupo =
  case traverse comCartoes grupo of
    Nothing    -> [grupo]
    Just dados -> concatMap (desempatarPorSorteio . map fst) (agruparPor compararCartoes dados)
  where
    comCartoes l = (,) l <$> lookup (time l) cartoes
    compararCartoes = comparing (vermelhos . snd) <> comparing (amarelos . snd)
    desempatarPorSorteio ls
      | all ((`elem` sorteio) . time) ls =
          map (: []) (sortOn (\l -> elemIndex (time l) sorteio) ls)
      | otherwise = [ls]

-- Cada grupo ainda empatado divide a mesma posição na tabela.
classificacaoComDesempate :: [(Time, Cartoes)] -> [Time] -> [Partida] -> [(Int, Linha)]
classificacaoComDesempate cartoes sorteio partidas =
  concat (zipWith numerar posicoes grupos)
  where
    linhas = map (linhaDoTime partidas) (times partidas)
    porCampanha = agruparPor criterios linhas
    porConfronto = concatMap (confrontoDireto partidas) porCampanha
    grupos = concatMap (desempatarPorCartoes cartoes sorteio) porConfronto
    posicoes = scanl (+) 1 (map length grupos)
    numerar pos = map (\l -> (pos, l))

ateRodada :: Int -> [Partida] -> [Partida]
ateRodada n = filter (\p -> rodada p <= n)

diferenca :: Partida -> Int
diferenca p = abs (golsMandante p - golsVisitante p)

maiorGoleada :: [Partida] -> Maybe Partida
maiorGoleada []       = Nothing
maiorGoleada (p : ps) = Just (foldl maisGoleada p ps)
  where
    -- se a diferença empatar, fica a partida que apareceu primeiro
    maisGoleada atual outra
      | diferenca outra > diferenca atual = outra
      | otherwise                         = atual

mediaGols :: [Partida] -> Maybe Double
mediaGols [] = Nothing
mediaGols ps = Just (fromIntegral totalGols / fromIntegral (length ps))
  where
    totalGols = sum (map golsDaPartida ps)
    golsDaPartida p = toInteger (golsMandante p) + toInteger (golsVisitante p)

-- ===== Leitura (Camada 3) =====

data Erro
  = CamposInvalidos Int               -- linha
  | NumeroInvalido Int String         -- linha e o texto inválido
  | PlacarNegativo Int                -- linha
  | MesmoTime Int Time                -- linha e o time
  | TimeRepetidoNaRodada Int Int Time -- linha, rodada e o time
  | RodadaInvalida Int                -- linha (rodada zero ou negativa)
  | TotalDeGolsInvalido Int Time      -- linha e o time
  deriving (Show, Eq)

linhaDoErro :: Erro -> Int
linhaDoErro (CamposInvalidos n)          = n
linhaDoErro (NumeroInvalido n _)         = n
linhaDoErro (PlacarNegativo n)           = n
linhaDoErro (MesmoTime n _)              = n
linhaDoErro (TimeRepetidoNaRodada n _ _) = n
linhaDoErro (RodadaInvalida n)           = n
linhaDoErro (TotalDeGolsInvalido n _)    = n

mensagemErro :: Erro -> String
mensagemErro e = "Linha " ++ show (linhaDoErro e) ++ ": " ++ descricao e
  where
    descricao (CamposInvalidos _)          = "esperava 5 campos separados por ';' e dois nomes preenchidos"
    descricao (NumeroInvalido _ s)         = "\"" ++ s ++ "\" não é um inteiro válido no intervalo de Int"
    descricao (PlacarNegativo _)           = "placar negativo"
    descricao (MesmoTime _ t)              = t ++ " jogando contra ele mesmo"
    descricao (TimeRepetidoNaRodada _ r t) = t ++ " já jogou na rodada " ++ show r
    descricao (RodadaInvalida _)           = "a rodada deve ser maior que zero"
    descricao (TotalDeGolsInvalido _ t)    = "o total de gols de " ++ t ++ " ultrapassa o limite de Int"

separar :: Char -> String -> [String]
separar c texto = case break (== c) texto of
  (campo, [])        -> [campo]
  (campo, _ : resto) -> campo : separar c resto

aparar :: String -> String
aparar = dropWhileEnd isSpace . dropWhile isSpace

lerNumero :: Int -> String -> Either Erro Int
lerNumero n s = maybe invalido converter (readMaybe s :: Maybe Integer)
  where
    invalido = Left (NumeroInvalido n s)
    converter valor
      | valor < toInteger (minBound :: Int) || valor > toInteger (maxBound :: Int) = invalido
      | otherwise = Right (fromInteger valor)

data LeituraLinha = LeituraLinha
  { errosLocais   :: [Erro]
  , escalacoes    :: [(Int, Time)]
  , partidaLida   :: Either Erro Partida
  }

analisarLinha :: Int -> String -> LeituraLinha
analisarLinha n linha =
  case map aparar (separar ';' linha) of
    [r, casa, gm, gv, fora] ->
      let numRodada = lerNumero n r
          golsCasa = lerNumero n gm
          golsFora = lerNumero n gv
          nomes = filter (not . null) [casa, fora]
          jogosDaLinha = [(num, t) | Right num <- [numRodada], num > 0, t <- nub nomes]
          erros = lefts [numRodada, golsCasa, golsFora]
               ++ [RodadaInvalida n | Right num <- [numRodada], num <= 0]
               ++ [PlacarNegativo n | any negativo [golsCasa, golsFora]]
               ++ [CamposInvalidos n | length nomes < 2]
               ++ [MesmoTime n casa | not (null casa), casa == fora]
          partida = Partida <$> numRodada <*> pure casa <*> golsCasa <*> golsFora <*> pure fora
      in LeituraLinha erros jogosDaLinha partida
    _ -> LeituraLinha [CamposInvalidos n] [] (Left (CamposInvalidos n))
  where
    negativo = either (const False) (< 0)

semErros :: [Erro] -> Either Erro ()
semErros [] = Right ()
semErros (erro : _) = Left erro

lerPartida :: Int -> String -> Either Erro Partida
lerPartida n linha = do
  let leitura = analisarLinha n linha
  semErros (errosLocais leitura)
  partidaLida leitura

-- Numera as linhas antes de tirar comentários e linhas vazias,
-- para que o erro aponte a linha certa do texto original.
linhasNumeradas :: String -> [(Int, String)]
linhasNumeradas texto =
  [ (n, l) | (n, l) <- zip [1 ..] (map aparar (lines texto)), not (ignorar l) ]
  where
    ignorar l = null l || take 1 l == "#"

-- scanl fornece, para cada linha, os jogos válidos das linhas anteriores.
analisarCampeonato :: String -> [([Erro], Either Erro Partida)]
analisarCampeonato texto = zipWith conferir historicos lidas
  where
    lidas = [(n, analisarLinha n l) | (n, l) <- linhasNumeradas texto]
    historicos = scanl registrar [] lidas
    registrar anteriores (_, leitura) =
      case (errosLocais leitura, partidaLida leitura) of
        ([], Right p) -> p : anteriores
        _             -> anteriores
    conferir anteriores (n, leitura) =
      (errosLocais leitura ++ repetidos ++ totais, partidaLida leitura)
      where
        repetidos =
          [ TimeRepetidoNaRodada n r t
          | (r, t) <- escalacoes leitura
          , any (\p -> rodada p == r && participou t p) anteriores
          ]
        totais =
          [ TotalDeGolsInvalido n t
          | null (errosLocais leitura)
          , Right p <- [partidaLida leitura]
          , t <- [mandante p, visitante p]
          , totalExcede t (p : anteriores)
          ]

totalExcede :: Time -> [Partida] -> Bool
totalExcede t partidas = any (> toInteger (maxBound :: Int)) [total fst, total snd]
  where
    placares = map (golsDoTime t) (filter (participou t) partidas)
    total lado = sum (map (toInteger . lado) placares)

lerCampeonato :: String -> Either Erro [Partida]
lerCampeonato = traverse aceitar . analisarCampeonato
  where
    aceitar (erros, partida) = do
      semErros erros
      partida

todosOsErros :: String -> [Erro]
todosOsErros = concatMap fst . analisarCampeonato

tabelaFormatada :: [Linha] -> String
tabelaFormatada = tabelaComPosicoes . zip [1 ..]

tabelaComPosicoes :: [(Int, Linha)] -> String
tabelaComPosicoes [] = "Nenhuma partida para classificar.\n"
tabelaComPosicoes tabela = unlines (cabecalho : tracos : linhas)
  where
    largura   = foldr max 4 (map (length . time . snd) tabela)
    larguraPos = foldr max 3 (map (length . show . fst) tabela)
    cabecalho = formatar "Pos" "Time" ["Pts", "J", "V", "E", "D", "SG"]
    tracos    = replicate (length cabecalho) '-'
    linhas    = [formatar (show pos) (time l) (map show (numeros l)) | (pos, l) <- tabela]
    numeros l = [pontosLinha l, jogos l, vitorias l, empates l, derrotas l, saldo l]
    larguras  = foldl (zipWith max) (replicate 6 4) (map (map (length . show) . numeros . snd) tabela)
    formatar pos nome colunas =
      direita larguraPos pos ++ "  " ++ esquerda largura nome
        ++ concat (zipWith (\n s -> ' ' : direita n s) larguras colunas)
    esquerda n s = s ++ replicate (n - length s) ' '
    direita n s  = replicate (n - length s) ' ' ++ s

-- ===== Dados =====

-- Seis times e cinco rodadas de exemplo.
dadosCampeonato :: String
dadosCampeonato = unlines
  [ "# rodada;mandante;gols mandante;gols visitante;visitante"
  , "1;Athletico;0;0;Paraná"
  , "1;Coritiba;3;0;Operário"
  , "1;Londrina;3;2;Maringá"
  , "2;Athletico;1;1;Operário"
  , "2;Paraná;0;3;Maringá"
  , "2;Coritiba;0;3;Londrina"
  , "3;Athletico;3;1;Maringá"
  , "3;Operário;2;1;Londrina"
  , "3;Paraná;0;2;Coritiba"
  , "4;Athletico;0;0;Londrina"
  , "4;Maringá;2;2;Coritiba"
  , "4;Operário;1;0;Paraná"
  , "5;Athletico;0;2;Coritiba"
  , "5;Londrina;3;3;Paraná"
  , "5;Maringá;2;3;Operário"
  ]

-- Uma linha válida e cinco com problemas diferentes.
dadosComErros :: String
dadosComErros = unlines
  [ "# entrada com erros de digitação"
  , "1;Athletico;0;0;Paraná"
  , ""
  , "1;Coritiba;dois;0;Operário"
  , "1;Londrina;-1;2;Maringá"
  , "1;Paraná;2;0;Operário"
  , "2;Londrina;1;1;Londrina"
  , "3;Coritiba;1;0"
  ]

-- ===== Main =====

descreverPartida :: Partida -> String
descreverPartida p =
  "rodada " ++ show (rodada p) ++ ", " ++ mandante p ++ " " ++ show (golsMandante p)
    ++ " x " ++ show (golsVisitante p) ++ " " ++ visitante p

-- Mostra um Double com uma casa decimal.
umaCasa :: Double -> String
umaCasa x = show (fromIntegral (round (x * 10) :: Int) / 10 :: Double)

main :: IO ()
main = do
  case lerCampeonato dadosCampeonato of
    Left erro -> putStrLn ("Erro nos dados do campeonato: " ++ mensagemErro erro)
    Right partidas -> do
      putStrLn "=== Camada 1: times e resultados ==="
      putStrLn ("Times: " ++ intercalate ", " (times partidas))
      putStrLn "Jogos do Coritiba:"
      mapM_ putStrLn [ "  " ++ descreverPartida p ++ " -> " ++ maybe "-" show (resultadoPara "Coritiba" p)
                     | p <- partidas, participou "Coritiba" p ]

      putStrLn "\n=== Camada 2: classificação final ==="
      putStr (tabelaComPosicoes (classificacaoComDesempate [] [] partidas))

      putStrLn "\n=== Camada 2: classificação após a 3ª rodada ==="
      putStr (tabelaComPosicoes (classificacaoComDesempate [] [] (ateRodada 3 partidas)))

      putStrLn "\n=== Camada 2: estatísticas ==="
      putStrLn ("Maior goleada: " ++ maybe "nenhuma partida" descreverPartida (maiorGoleada partidas))
      putStrLn ("Média de gols por partida: " ++ maybe "nenhuma partida" umaCasa (mediaGols partidas))
      putStrLn "Aproveitamento:"
      mapM_ putStrLn [ "  " ++ time l ++ ": " ++ umaCasa (aproveitamento l) ++ "%"
                     | l <- classificacao partidas ]

  putStrLn "\n=== Camada 3: entrada com erros ==="
  case lerCampeonato dadosComErros of
    Left erro -> putStrLn ("lerCampeonato para no primeiro erro: " ++ mensagemErro erro)
    Right _   -> putStrLn "Nenhum erro encontrado."
  putStrLn "todosOsErros mostra todos:"
  mapM_ (\e -> putStrLn ("  " ++ mensagemErro e)) (todosOsErros dadosComErros)
