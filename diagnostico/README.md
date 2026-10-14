# Diagnóstico do Codex CLI e ChatGPT pelo CMD

Os scripts usam somente `cmd.exe` e comandos do Windows: `curl.exe`, `nslookup`, `ipconfig`, `route`, `netsh`, `reg`, `wevtutil`, `w32tm`, `findstr` e, quando instalados, Codex, Git e Node/npm. Não executam PowerShell, Python, WSL ou JavaScript.

Execute no CMD, com o mesmo usuário e ambiente em que ocorre o problema:

```bat
cd /d C:\DEVELOPMENT\workspaces\workspace-default\codex-skills\diagnostico
executar.cmd
```

Também é possível chamar de qualquer diretório:

```bat
"C:\DEVELOPMENT\workspaces\workspace-default\codex-skills\diagnostico\executar.cmd"
```

A execução normalmente leva de alguns segundos a alguns minutos. Cada requisição HTTPS tem limite de 6 segundos para conectar e 15 segundos no total. Em uma rede que descarta conexões, os testes padrão podem levar mais de 3 minutos. DNS, comandos locais e execução do Codex possuem seus próprios tempos; não existe um timeout global do processo.

Os relatórios ficam em `diagnostico\relatorios\exec_<data_hora>_<aleatório>\`. Comece por `RESUMO.txt`. Cada execução cria uma pasta nova. O código de saída 0 do executor significa que terminou de coletar o diagnóstico; **não significa que todos os destinos funcionam**.

## Opções

```bat
executar.cmd --help
executar.cmd --completo
executar.cmd --somente proxy
executar.cmd --somente dns
executar.cmd --somente https
executar.cmd --somente codex
executar.cmd --somente sistema
executar.cmd --completo --somente https
```

`--completo` acrescenta testes HTTPS IPv6 nos destinos principais, ping e uma rota limitada a oito saltos, conexões TCP e regras de firewall de saída. Ping/rota não são provas de bloqueio HTTPS; ICMP pode ser filtrado normalmente.

Se a política da sua rede permitir testar conexão sem proxy, compare as duas rotas:

```bat
executar.cmd --direto
executar.cmd --completo --direto
```

`--direto` aplica `curl --noproxy "*"` somente a três requisições: ChatGPT, API e autenticação. Ele não altera nenhuma configuração. Por padrão, essa comparação está desativada. As outras requisições continuam usando o ambiente herdado. A opção não remove VPN, filtros de rede ou EDR.

Cada script numerado de 01 a 05 também pode ser executado diretamente; ele chama o executor para seu próprio módulo. Para acrescentar opções, use `executar.cmd --somente <módulo>`.

## O que cada script verifica

| Arquivo | Verificações |
| --- | --- |
| `executar.cmd` | Opções, pasta de saída, execução dos módulos e resumo. |
| `01_proxy.cmd` | Presença de variáveis de proxy/CA, WinHTTP, proxy/PAC do usuário, políticas e configuração de proxy do Git. Valores de variáveis, PAC e registro de proxy não são exportados. |
| `02_dns_rotas.cmd` | Interfaces, DNS configurado, rotas IPv4/IPv6, arquivo hosts e consultas A/AAAA. |
| `03_https.cmd` | DNS/TCP/TLS/HTTP por curl, IP remoto, tempos, resultado de validação TLS e resposta CONNECT do proxy. |
| `04_codex.cmd` | Localização, versão, status local de login e presença de chaves relevantes em arquivos candidatos de configuração. |
| `05_sistema.cmd` | Relógio, fuso, sincronização, perfis de firewall e eventos Schannel. |
| `06_resumo.cmd` | Evidências e hipóteses de investigação; chamado pelo executor. |

Os destinos testados são ChatGPT, seu caminho de backend do Codex, API OpenAI, autenticação, plataforma, CDN, arquivos e status. `www.microsoft.com` serve como comparação com outro domínio. Essa lista é uma amostra para diagnóstico, **não uma lista completa de liberação de firewall**.

As requisições são GET sem credenciais. Não iniciam conversa nem usam a API de modelos com uma chave. Não seguem redirecionamentos, para manter o teste restrito ao destino original. Uma resposta de redirecionamento já comprova que houve uma resposta HTTP naquele destino.

## Como interpretar

| Evidência | O que significa / próximo passo |
| --- | --- |
| curl 0 e HTTP 2xx/3xx | O transporte HTTPS respondeu. Não confirma login, modelo, streaming ou acesso a todas as funções. |
| HTTP 401 na API | Esperado sem chave. O endpoint respondeu; a conta não foi testada. |
| HTTP 403 | Acesso negado ou desafio. Pode vir de WAF, proteção contra automação, proxy ou política do serviço. Não identifica sozinho um bloqueio corporativo. |
| HTTP 404 em raiz/CDN/backend | Caminho não encontrado; houve resposta HTTP. Não prova falha de rede nem valida uso do produto. |
| HTTP 407 ou CONNECT 407 | Proxy exige autenticação. Confira ambiente, proxy configurado e método de autenticação da empresa. |
| HTTP 429 | Limite de uso, capacidade ou política. A resposta não prova bloqueio de rede. |
| HTTP 5xx | Falha do serviço ou intermediário. Compare outro destino e consulte o status público. |
| curl 5 | DNS do proxy falhou. |
| curl 6 | DNS do destino falhou. |
| curl 7 | TCP inacessível/recusado. Pode envolver destino, rota, proxy ou firewall. |
| curl 28 | Timeout em alguma etapa. Os tempos coletados ajudam a localizar onde parou. |
| curl 35 | Falha de negociação TLS. Investigue inspeção HTTPS, protocolos e cadeia de confiança. |
| curl 60 | Certificado não validado. Confira relógio, confiança, revogação e inspeção HTTPS. |
| curl 77 | Problema com arquivo/repositório de certificados. |
| curl 56 | Recepção encerrada/interrompida. Pode envolver proxy, TLS ou servidor. |
| curl 97 | Falha na negociação do proxy. |
| HTTP 000 | Nenhuma resposta HTTP final recebida; consulte também curl_exit e proxy_connect. |
| Automático falha, IPv4 funciona | Investigue DNS/IPv6 e a seleção de rota. Não é uma prova isolada. |
| Automático falha, direto funciona | Investigue configuração/autenticação do proxy. |
| Automático funciona, direto falha | A rede pode exigir proxy. |
| Controle também falha | Pode haver problema geral de rede/proxy/TLS. O controle também pode ser filtrado. |
| Apenas OpenAI falha | Sugere investigar tratamento específico desses destinos; não identifica a camada responsável. |

No CSV, `remote_ip` pode ser o IP do **proxy**, em vez do servidor OpenAI. `connect_s`, `tls_s` e `total_s` são tempos cumulativos desde o início; não são durações independentes. `ssl_verify_result=0` sozinho não confirma TLS: avalie o código de saída, o tempo TLS e a resposta HTTP. Alguns backends TLS não fornecem todos os detalhes.

DNS usa os servidores configurados no Windows, sem trocar resolvers nem consultar DNS público externo. Confira o texto de `dns_*.txt`, pois NXDOMAIN/timeout nem sempre são representados de forma uniforme pelo código de saída do nslookup. A ausência de AAAA pode ser normal. Com proxy, a resolução do destino pode ocorrer remotamente, apesar de uma falha do DNS local.

## Diferenças entre navegador, curl e Codex

WinHTTP, proxy do navegador, PAC/WPAD e variáveis de ambiente são mecanismos diferentes. O curl não interpreta PAC nem importa automaticamente o proxy WinHTTP/do navegador. Ter navegação funcionando não garante que um CLI esteja configurado corretamente, e o inverso também vale.

O relatório informa a presença de `HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY` e `NO_PROXY`, sem seus valores. A presença de uma variável não confirma sua correção. Em particular, curl normalmente ignora `HTTP_PROXY` em maiúsculas para destinos HTTP por segurança; os testes deste pacote usam HTTPS.

Curl/Schannel, Node, navegador e Codex podem usar repositórios de confiança diferentes. Uma CA corporativa precisa ser validada para a pilha usada pelo aplicativo. Os scripts mantêm a validação TLS e não usam `--insecure`, não desativam revogação nem mudam certificados.

`codex login status` só verifica credenciais locais. Sua saída é descartada e apenas o código de saída é registrado. Retorno 0 não garante token válido, assinatura, autorização da organização ou conectividade remota. Retorno diferente de 0 também pode ser causado por erro local de configuração.

A configuração é inspecionada por presença de chaves, sem exportar valores. Os caminhos de requisitos de máquina são candidatos, não uma descoberta completa das políticas aplicadas. Comentários, perfis, arquivos ancestrais e configurações gerenciadas podem exigir revisão manual. O proxy dos comandos em sandbox não necessariamente controla a conexão do próprio Codex ao serviço.

Se os testes respondem mas o aplicativo falha, investigue a mensagem exata do aplicativo, login, plano/permissões, VPN/EDR, cookies, extensões do navegador e transporte usado. Este pacote não valida WebSocket, SSE/streaming, upload, modelo ou uma conversa autenticada.

## Privacidade e operação

- Nenhuma configuração de rede/firewall/proxy é alterada; não há login/logout, instalação, limpeza de DNS ou reinício de serviços.
- Os scripts não abrem nem exportam o conteúdo de `auth.json`, conversas ou logs do Codex, e não exportam chaves de API, tokens ou cookies. O comando `codex login status` consulta as credenciais internamente pelo próprio CLI.
- Variáveis potencialmente sensíveis e valores de configuração são omitidos. Corpos e cabeçalhos HTTP não são salvos; mensagens brutas de erro do curl são descartadas para evitar expor credenciais de proxy.
- Os relatórios **ainda contêm metadados locais**: usuário em caminhos, IPs, MACs, servidores DNS, proxy WinHTTP, nomes internos, rotas, políticas, regras e eventos. Revise antes de compartilhar. A saída de ferramentas nativas como netsh é registrada como fornecida pelo Windows.
- Normalmente basta um CMD comum. Consultas a eventos, sincronização ou firewall podem falhar por permissão; os erros ficam no relatório. Se precisar repetir como administrador, faça isso conforme a política da sua empresa.
- Compare uma execução no ambiente afetado com outra rede autorizada ou outro computador, usando as mesmas opções. Não use os resultados para contornar políticas.
- Não use `set`, `type auth.json`, `curl -v` ou exportação indiscriminada de configuração para complementar um relatório que será compartilhado.

Fontes consultadas na implementação: [referência oficial do CLI Codex](https://developers.openai.com/codex/cli/reference/) para `codex login status` e [referência de configuração do Codex](https://developers.openai.com/codex/config-reference/) para chaves de URL/proxy/rede. Para indisponibilidade do serviço, consulte [OpenAI Status](https://status.openai.com/).
