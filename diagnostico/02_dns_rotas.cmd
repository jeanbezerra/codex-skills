@echo off
setlocal EnableExtensions DisableDelayedExpansion
if not defined DGN_DIR (
 call "%~dp0executar.cmd" --somente dns
 exit /b
)
echo DNS, INTERFACES E ROTAS
echo DNS usa os servidores configurados no Windows. Nao consulta resolvers externos.
echo IPs, nomes internos e enderecos fisicos podem aparecer neste arquivo.
echo.
ipconfig /all
echo codigo_saida=%errorlevel%
echo.
route print -4
echo codigo_saida=%errorlevel%
route print -6
echo codigo_saida=%errorlevel%
echo.
echo Entradas do arquivo hosts relacionadas a OpenAI:
findstr /i /c:"openai" /c:"chatgpt" /c:"oaistatic" /c:"oaiusercontent" "%SystemRoot%\System32\drivers\etc\hosts"
echo Linhas comentadas nao afetam DNS. Ausencia de correspondencia nao e erro.
echo.
where nslookup.exe >nul 2>&1
if errorlevel 1 (
 echo nslookup indisponivel.
 exit /b 1
)
for %%H in (chatgpt.com api.openai.com auth.openai.com auth0.openai.com platform.openai.com cdn.oaistatic.com files.oaiusercontent.com status.openai.com www.microsoft.com) do call :dns %%H
if not "%DGN_COMPLETO%"=="1" exit /b 0
echo.
echo ICMP - falha no ping nao prova bloqueio HTTPS:
ping -n 2 -w 1000 chatgpt.com
echo codigo_saida=%errorlevel%
echo.
echo Rota parcial, ate 8 saltos; roteadores podem ignorar ICMP:
tracert -d -h 8 -w 400 chatgpt.com
echo codigo_saida=%errorlevel%
exit /b 0
:dns
echo --- DNS %~1 ---
nslookup -timeout=2 -retry=1 -type=A %~1 > "%DGN_DIR%\dns_%~1_A.txt" 2>&1
set "DGN_DNS_RC=%errorlevel%"
type "%DGN_DIR%\dns_%~1_A.txt"
echo codigo_saida_A=%DGN_DNS_RC%
nslookup -timeout=2 -retry=1 -type=AAAA %~1 > "%DGN_DIR%\dns_%~1_AAAA.txt" 2>&1
set "DGN_DNS_RC=%errorlevel%"
type "%DGN_DIR%\dns_%~1_AAAA.txt"
echo codigo_saida_AAAA=%DGN_DNS_RC%
echo NXDOMAIN, timeout ou falta de resposta devem ser avaliados no texto acima.
echo Sem registro AAAA pode ser normal; nao implica falha de IPv4.
echo DNS local pode falhar enquanto um proxy resolve o destino remotamente.
echo.
exit /b
