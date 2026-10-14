@echo off
setlocal EnableExtensions DisableDelayedExpansion
if not defined DGN_DIR (
 echo Este modulo e chamado por executar.cmd.
 exit /b 2
)
echo RESUMO DO DIAGNOSTICO
echo Data local: %DATE% %TIME%
echo.
if exist "%DGN_DIR%\sinal_proxy_env.txt" echo PROXY: proxy HTTPS/ALL definido no ambiente. Confira 01_proxy.txt.
if exist "%DGN_DIR%\sinal_pac.txt" echo PAC: configuracao encontrada. curl nao interpreta PAC automaticamente.
if exist "%DGN_DIR%\sinal_tls_env.txt" echo TLS: NODE_TLS_REJECT_UNAUTHORIZED definida. Valor omitido; confira localmente.
if exist "%DGN_DIR%\sinal_curl_ausente.txt" echo HTTPS: curl.exe indisponivel; testes nao executados.
if exist "%DGN_DIR%\sinal_codex_ausente.txt" echo CODEX: nao encontrado no PATH deste CMD.
if exist "%DGN_DIR%\sinal_codex_versao.txt" echo CODEX: falha na execucao local de --version.
if exist "%DGN_DIR%\sinal_codex_auth.txt" echo CODEX: login local nao confirmado; ausencia de credenciais ou erro de configuracao.
if exist "%DGN_DIR%\sinal_codex_auth_ok.txt" echo CODEX: credenciais locais presentes; validade remota nao foi testada.
echo.
if not exist "%DGN_DIR%\https.csv" goto limites
set "DGN_AUTO_OK=0"
set "DGN_AUTO_FAIL=0"
echo Destino / modo: resultado de transporte e resposta HTTP
for /f "usebackq skip=1 tokens=1-4,10 delims=," %%A in ("%DGN_DIR%\https.csv") do call :resultado %%A %%B %%C %%D %%E
if "%DGN_AUTO_FAIL%"=="0" if not "%DGN_AUTO_OK%"=="0" echo Nenhuma falha de transporte HTTPS nos destinos em modo automatico.
if not "%DGN_AUTO_FAIL%"=="0" echo Falhas de transporte em modo automatico: %DGN_AUTO_FAIL%. Confira os detalhes.
:limites
echo.
echo COMO IDENTIFICAR A CAUSA
echo - curl 5/6: DNS do proxy/destino. Compare com dns_*.txt e o arquivo hosts.
echo - curl 7/28: conexao/timeout. Compare controle, rotas, proxy e firewall.
echo - curl 35/60/77: TLS/confianca. Confira relogio, CA e eventual inspecao HTTPS.
echo - CONNECT 407: autenticacao exigida pelo proxy.
echo - HTTP 403: acesso negado/challenge. Pode ser servidor, WAF, proxy ou politica de conta.
echo - HTTP 401 na API: esperado sem chave; comprova resposta HTTP, nao valida sua conta.
echo - HTTP 429: limite/capacidade; nao prova bloqueio de rede.
echo - HTTP 5xx: erro no servidor/intermediario. Compare com status e controle.
echo - Automatico falha e IPv4 funciona: investigue IPv6/DNS, sem assumir causa unica.
echo - Direto funciona e automatico falha: investigue proxy; automatico funciona e direto
echo   falha pode indicar rede que exige proxy. Compare destinos equivalentes.
echo - Todos respondem mas o aplicativo falha: investigue login, plano, politicas da
echo   empresa, VPN/EDR, cookies/extensoes do navegador e transporte do aplicativo.
echo.
echo Os testes nao executam uma conversa, nem validam streaming, WebSocket, upload,
echo modelo, assinatura ou permissao da conta. Nao afirmam uma causa sem evidencia.
echo HTTP/HTTPS de controle tambem pode ser restringido pela empresa.
echo Relatorios contem metadados de rede. Revise antes de compartilhar.
echo Detalhes: 01_proxy.txt, 02_dns_rotas.txt, 03_https.txt, 04_codex.txt, 05_sistema.txt.
exit /b 0
:resultado
if "%~2"=="automatico" (
 if "%~3"=="0" (set /a DGN_AUTO_OK+=1 >nul) else (set /a DGN_AUTO_FAIL+=1 >nul)
)
if "%~3"=="0" (
 echo %~1 / %~2: HTTPS respondeu; HTTP %~4.
) else (
 echo %~1 / %~2: falha curl %~3; HTTP %~4; CONNECT %~5.
)
exit /b
