@echo off
setlocal EnableExtensions DisableDelayedExpansion
if not defined DGN_DIR (
 call "%~dp0executar.cmd" --somente proxy
 exit /b
)
echo PROXY E VARIAVEIS DE AMBIENTE
echo Valores de proxy, PAC e certificados sao omitidos para proteger credenciais.
echo A presenca da variavel nao prova que seu valor esteja correto.
echo.
for %%V in (HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY OPENAI_BASE_URL CHATGPT_BASE_URL CURL_CA_BUNDLE REQUESTS_CA_BUNDLE SSL_CERT_FILE SSL_CERT_DIR NODE_EXTRA_CA_CERTS NODE_TLS_REJECT_UNAUTHORIZED OPENAI_API_KEY CODEX_HOME) do call :variavel %%V
echo.
echo Proxy WinHTTP:
netsh winhttp show proxy
echo codigo_saida=%errorlevel%
echo.
echo Proxy do usuario - HKCU Internet Settings:
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable
echo codigo_saida=%errorlevel%
for %%V in (ProxyServer ProxyOverride AutoConfigURL AutoDetect) do call :registro "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" %%V
echo.
echo Politicas de proxy - usuario e maquina:
for %%K in ("HKCU\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings" "HKLM\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings") do (
 reg query "%%~K" /v ProxySettingsPerUser
 for %%V in (ProxyServer ProxyEnable AutoConfigURL) do call :registro "%%~K" %%V
)
echo.
where git.exe >nul 2>&1
if errorlevel 1 goto observacoes
git config --get-regexp "http.*\.proxy" >nul 2>&1
if errorlevel 1 (
 echo Git: nenhuma configuracao http.*.proxy encontrada, ou consulta indisponivel.
) else (
 echo Git: configuracao de proxy encontrada. Valor omitido.
)
:observacoes
echo.
echo WinHTTP, proxy do navegador/PAC e variaveis de ambiente sao mecanismos distintos.
echo curl nao executa PAC/WPAD nem importa automaticamente o proxy do navegador/WinHTTP.
echo NO_PROXY pode mudar quais destinos usam o proxy. HTTPS_PROXY pode conter credenciais.
echo O resultado curl descreve este processo; navegador, Node e Codex podem usar outra pilha.
exit /b 0
:variavel
if defined %~1 (
 echo %~1=DEFINIDA [valor omitido]
 if /i "%~1"=="HTTPS_PROXY" > "%DGN_DIR%\sinal_proxy_env.txt" echo HTTPS_PROXY definida
 if /i "%~1"=="ALL_PROXY" >> "%DGN_DIR%\sinal_proxy_env.txt" echo ALL_PROXY definida
 if /i "%~1"=="NODE_TLS_REJECT_UNAUTHORIZED" > "%DGN_DIR%\sinal_tls_env.txt" echo NODE_TLS_REJECT_UNAUTHORIZED definida
) else (
 echo %~1=NAO DEFINIDA
)
exit /b
:registro
reg query "%~1" /v "%~2" >nul 2>&1
if errorlevel 1 (
 echo %~2: valor ausente ou consulta sem permissao.
) else (
 echo %~2: valor presente [conteudo omitido].
 if /i "%~2"=="AutoConfigURL" > "%DGN_DIR%\sinal_pac.txt" echo AutoConfigURL presente
)
exit /b
