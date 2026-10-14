@echo off
setlocal EnableExtensions DisableDelayedExpansion
if not defined DGN_DIR (
 call "%~dp0executar.cmd" --somente https
 exit /b
)
echo HTTPS - DNS, TCP 443, TLS e HTTP
echo GET sem credenciais, sem salvar corpo, cookies ou cabecalhos de resposta.
echo curl usa seu backend TLS e o ambiente herdado; arquivo .curlrc e ignorado.
echo Redirecionamentos nao sao seguidos. Uma resposta 3xx ja comprova resposta HTTP.
echo HTTP 401/403/404 em endpoints protegidos nao identifica sozinho a causa.
echo.
where curl.exe >nul 2>&1
if errorlevel 1 (
 echo ERRO: curl.exe indisponivel. Use Windows 10/11 com curl no PATH.
 > "%DGN_DIR%\sinal_curl_ausente.txt" echo curl indisponivel
 exit /b 1
)
curl.exe --version
> "%DGN_DIR%\https.csv" echo destino,modo,curl_exit,http_code,remote_ip,connect_s,tls_s,total_s,ssl_verify_result,proxy_connect
call :teste chatgpt automatico https://chatgpt.com/
call :teste codex_backend automatico https://chatgpt.com/backend-api/codex/models
call :teste api automatico https://api.openai.com/v1/models
call :teste auth automatico https://auth.openai.com/
call :teste auth0 automatico https://auth0.openai.com/
call :teste platform automatico https://platform.openai.com/
call :teste estaticos automatico https://cdn.oaistatic.com/
call :teste arquivos automatico https://files.oaiusercontent.com/
call :teste status automatico https://status.openai.com/api/v2/status.json
call :teste controle automatico https://www.microsoft.com/
call :teste chatgpt ipv4 https://chatgpt.com/
call :teste api ipv4 https://api.openai.com/v1/models
call :teste auth ipv4 https://auth.openai.com/
if not "%DGN_COMPLETO%"=="1" goto direto
call :teste chatgpt ipv6 https://chatgpt.com/
call :teste api ipv6 https://api.openai.com/v1/models
call :teste auth ipv6 https://auth.openai.com/
:direto
if not "%DGN_DIRETO%"=="1" exit /b 0
call :teste chatgpt direto https://chatgpt.com/
call :teste api direto https://api.openai.com/v1/models
call :teste auth direto https://auth.openai.com/
exit /b 0
:teste
set "DGN_FLAGS="
if "%~2"=="ipv4" set "DGN_FLAGS=--ipv4"
if "%~2"=="ipv6" set "DGN_FLAGS=--ipv6"
if "%~2"=="direto" set DGN_FLAGS=--noproxy "*"
set "DGN_HTTP=000"
set "DGN_IP=indisponivel"
set "DGN_CONNECT=0"
set "DGN_TLS=0"
set "DGN_TOTAL=0"
set "DGN_VERIFY=indisponivel"
set "DGN_PROXY=000"
echo --- %~1 / %~2 ---
curl.exe --disable --silent --output NUL --connect-timeout 6 --max-time 15 --proto "=https" --user-agent "OpenAI-connectivity-diagnostic/1.0" %DGN_FLAGS% --write-out "http=%%{http_code}\nremote_ip=%%{remote_ip}\nconnect_s=%%{time_connect}\ntls_s=%%{time_appconnect}\ntotal_s=%%{time_total}\nssl_verify_result=%%{ssl_verify_result}\nproxy_connect=%%{http_connect}\n" "%~3" > "%DGN_DIR%\http_%~1_%~2.txt" 2>nul
set "DGN_CURL_RC=%errorlevel%"
>> "%DGN_DIR%\http_%~1_%~2.txt" echo curl_exit=%DGN_CURL_RC%
for /f "usebackq tokens=1,* delims==" %%A in ("%DGN_DIR%\http_%~1_%~2.txt") do (
 if "%%A"=="http" set "DGN_HTTP=%%B"
 if "%%A"=="remote_ip" if not "%%B"=="" set "DGN_IP=%%B"
 if "%%A"=="connect_s" set "DGN_CONNECT=%%B"
 if "%%A"=="tls_s" set "DGN_TLS=%%B"
 if "%%A"=="total_s" set "DGN_TOTAL=%%B"
 if "%%A"=="ssl_verify_result" set "DGN_VERIFY=%%B"
 if "%%A"=="proxy_connect" set "DGN_PROXY=%%B"
)
type "%DGN_DIR%\http_%~1_%~2.txt"
>> "%DGN_DIR%\https.csv" echo %~1,%~2,%DGN_CURL_RC%,%DGN_HTTP%,%DGN_IP%,%DGN_CONNECT%,%DGN_TLS%,%DGN_TOTAL%,%DGN_VERIFY%,%DGN_PROXY%
call :interpretar %DGN_CURL_RC% %DGN_HTTP% %DGN_PROXY%
echo.
exit /b
:interpretar
if "%~3"=="407" echo ATENCAO: proxy exige autenticacao para o tunel CONNECT.
if "%~1"=="0" (
 echo Transporte HTTPS concluido. Avalie o codigo HTTP separadamente.
 exit /b
)
if "%~1"=="5" echo FALHA: nao foi possivel resolver o nome do proxy.
if "%~1"=="6" echo FALHA: nao foi possivel resolver o nome do destino.
if "%~1"=="7" echo FALHA: conexao TCP recusada ou inacessivel; confira proxy, rota e firewall.
if "%~1"=="28" echo FALHA: timeout; pode ocorrer em DNS, TCP, proxy, TLS ou leitura da resposta.
if "%~1"=="35" echo FALHA: negociacao TLS; pode envolver inspecao HTTPS, certificado ou protocolo.
if "%~1"=="60" echo FALHA: certificado nao validado; confira cadeia de confianca e relogio.
if "%~1"=="77" echo FALHA: arquivo/repositorio de certificados indisponivel ou mal configurado.
if "%~1"=="56" echo FALHA: recepcao interrompida; confira encerramento pelo proxy ou servidor.
if "%~1"=="97" echo FALHA: negociacao do proxy.
echo Veja a tabela de codigos no README. Erro nao implica necessariamente bloqueio intencional.
exit /b
