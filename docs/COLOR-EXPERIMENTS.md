# Cores trocadas (vermelho/azul): experimento do patch 0028

**Status: não testado em console.** Quem escreveu isto não tem acesso ao PS4; o patch não foi
compilado nem executado. Ele só adiciona duas chaves no `settings.txt` (sem mudar nada por padrão).

## Por que os auto-testes anteriores passavam e o jogo continuava errado

O auto-teste `A2B10G10R10` (patch 0022) usa só `vkCmdBlitImage`. No RADV, um blit passa por um
shader de blit do próprio driver. Ele **nunca** passa pelos fragment shaders traduzidos pelo Eden,
que são os que escrevem os render targets A2B10G10R10 do MK8D (cenas 3D e conversão YUV->RGB dos
vídeos, segundo o log de testes 17/18). Resultado: driver "correto" nos testes, jogo errado.

Além disso, o workaround existente só ligava se o auto-teste falhasse (`a2b10=auto|off`), então
nunca dava para forçá-lo no jogo real. E o ramo "render target como A2R10G10B10" (`rt_use_a2r10`)
só troca o formato da *view*; o render pass continua com o formato antigo (`vk_render_pass_cache.cpp`
usa o PixelFormat), então ele não funcionaria se algum dia fosse ativado.

## As duas chaves (`/data/edenps4/settings.txt`)

```
a2b10=write    # vermelho<->azul trocados no que os shaders ESCREVEM em render targets A2B10G10R10
a2b10=sample   # vermelho<->azul trocados quando imagens A2B10G10R10 são LIDAS (amostradas)
```

- `write`: o shader troca as componentes 0 e 2 na saída; o `colorWriteMask` troca R<->B junto.
  (Constantes de blend não são trocadas: para o teste não deveria importar.)
- `sample`: a view de amostragem ganha o swizzle R<->B.
- As duas juntas se cancelam, então só uma por vez. Sem nenhuma, tudo igual à v0.1.0.

## Como testar (2 execuções)

1. Reconstrua com o patch 0028 (`scripts/fetch-eden.sh` aplica `patches/eden/*.patch` em ordem;
   apague `deps/eden` antes) e o `frontend/main.cpp` atualizado.
2. Execução A: `a2b10=write` -> abra o título/vídeo do MK8D e uma corrida. Anote como ficam:
   (a) vídeo, (b) modelos 3D, (c) UI/logo.
3. Execução B: `a2b10=sample` -> mesmas anotações.
4. Mande `boot.log` e `log/eden_log.txt` de cada execução (as linhas `PS4 view:` e a linha do
   settings mostram o que foi aplicado).

## Como ler o resultado

| Resultado | Significa |
|---|---|
| `write` conserta vídeo e 3D, UI continua certa | O erro está na escrita (shaders do jogo -> A2B10G10R10 no RADV/GFX7). Dá para manter como workaround e depois investigar a causa. |
| `sample` conserta e `write` não | O erro está na leitura de A2B10G10R10 pelos shaders do jogo. |
| Só o vídeo ou só o 3D melhora | Há mais de um caminho; me diga qual, e o `PS4 view:` do que ficou errado. |
| Nenhum muda nada | A troca não vem do formato de 10 bits. Próximos passos abaixo. |
| A UI quebra | A UI também passa por A2B10G10R10 (improvável); me mande o log. |

## Se nenhum funcionar

1. Um auto-teste com **draw real** (pipeline + fragment shader próprio escrevendo vermelho em
   A2B10G10R10, A8B8G8R8 e B8G8R8A8), para cobrir o caminho que os blits não cobrem.
2. Ler de volta 1 pixel do render target 3D logo após o primeiro passe real e comparar com o
   que o shader do jogo escreveu (precisa do valor no lado do shader).
3. Comparar o SPIR-V do shader de YUV->RGB do vídeo (`spirv-dis`) com o gerado num PC.

## Avisos

- O firmware 13.52 não foi testado pelo autor original (só 12.02). Se algo novo quebrar, isso
  entra na lista de suspeitos.
- O Eden proíbe contribuições e discussões geradas com IA. Este trabalho fica neste projeto
  separado; não reporte nada disso ao Eden.

## Patch 0029 (estabilidade, independente do 0028)

Duas mudanças pequenas, também **não testadas em console**:

1. **Stream buffer de 128 MiB no PS4** (era 256 MiB). É uma alocação GARLIC fora da arena do driver;
   a corrida estourava a memória direta ao carregar (sobravam ~100 MiB). O próprio Eden já usa
   128 MiB em FreeBSD, mas o port compila com `-U__FreeBSD__` e nunca pegava esse ramo. Efeito
   esperado: ~128 MiB a mais de folga. Custo possível: uploads maiores que 8 MiB passam pelo pool
   de staging comum (um pouco mais de trabalho, não de memória fixa).
2. **Override de render target A2R10G10B10 desativado.** Ele só mudava a *view*; o render pass e
   os pipelines continuavam com o formato original, o que geraria framebuffer inválido se o
   auto-teste algum dia o ativasse. Agora não é aplicado.

Se a corrida piorar (mais tirões ou travamentos de upload), reverta só o 0029: apague
`patches/eden/0029-*.patch` e refaça o `fetch-eden.sh`.
