@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "DGN_DIR="
set "DGN_COMPLETO=0"
set "DGN_DIRETO=0"
set "DGN_SOMENTE="
:argumentos
if "%~1"=="" goto iniciar
if /i "%~1"=="--help" goto ajuda
if /i "%~1"=="--ajuda" goto ajuda
if /i "%~1"=="--completo" (
 set "DGN_COMPLETO=1"
 shift /1
 goto argumentos
)
if /i "%~1"=="--direto" (
 set "DGN_DIRETO=1"
 shift /1
 goto argumentos
)
if /i "%~1"=="--somente" (
 if "%~2"=="" (
  echo Informe o modulo depois de --somente.
  exit /b 2
 )
 set "DGN_SOMENTE=%~2"
 shift /1
 shift /1
 goto argumentos
)
echo Opcao desconhecida. Use executar.cmd --help
exit /b 2
:iniciar
if not defined DGN_SOMENTE goto criar
for %%M in (proxy dns https codex sistema) do if /i "%DGN_SOMENTE%"=="%%M" goto criar
echo Modulo invalido. Use proxy, dns, https, codex ou sistema.
exit /b 2
:criar
set "DGN_STAMP=%DATE%_%TIME%"
set "DGN_STAMP=%DGN_STAMP:/=-%"
set "DGN_STAMP=%DGN_STAMP:\=-%"
set "DGN_STAMP=%DGN_STAMP::=-%"
set "DGN_STAMP=%DGN_STAMP: =_%"
set "DGN_STAMP=%DGN_STAMP:.=-%"
set "DGN_STAMP=%DGN_STAMP:,=-%"
set "DGN_DIR=%~dp0relatorios\exec_%DGN_STAMP%_%RANDOM%"
mkdir "%DGN_DIR%" >nul 2>&1
if not exist "%DGN_DIR%\" (
 echo Nao foi possivel criar o diretorio de relatorios.
 exit /b 1
)
> "%DGN_DIR%\execucao.txt" echo Diagnostico de conectividade OpenAI - somente leitura
>> "%DGN_DIR%\execucao.txt" echo Data local: %DATE% %TIME%
>> "%DGN_DIR%\execucao.txt" echo Completo=%DGN_COMPLETO% Direto=%DGN_DIRETO%
>> "%DGN_DIR%\execucao.txt" echo Nenhuma chave, token, cookie ou auth.json e coletado.
echo Relatorio: "%DGN_DIR%"
echo As consultas HTTPS nao enviam credenciais e possuem limite de tempo.
echo.
if not defined DGN_SOMENTE goto todos
if /i "%DGN_SOMENTE%"=="proxy" call :modulo 01_proxy.cmd 01_proxy.txt
if /i "%DGN_SOMENTE%"=="dns" call :modulo 02_dns_rotas.cmd 02_dns_rotas.txt
if /i "%DGN_SOMENTE%"=="https" call :modulo 03_https.cmd 03_https.txt
if /i "%DGN_SOMENTE%"=="codex" call :modulo 04_codex.cmd 04_codex.txt
if /i "%DGN_SOMENTE%"=="sistema" call :modulo 05_sistema.cmd 05_sistema.txt
goto concluir
:todos
call :modulo 01_proxy.cmd 01_proxy.txt
call :modulo 02_dns_rotas.cmd 02_dns_rotas.txt
call :modulo 03_https.cmd 03_https.txt
call :modulo 04_codex.cmd 04_codex.txt
call :modulo 05_sistema.cmd 05_sistema.txt
:concluir
call "%~dp006_resumo.cmd" > "%DGN_DIR%\RESUMO.txt" 2>&1
type "%DGN_DIR%\RESUMO.txt"
echo.
echo Arquivos gravados em: "%DGN_DIR%"
endlocal
exit /b 0
:modulo
echo Executando %~1 ...
call "%~dp0%~1" > "%DGN_DIR%\%~2" 2>&1
set "DGN_MOD_RC=%errorlevel%"
>> "%DGN_DIR%\execucao.txt" echo %~1: codigo_saida=%DGN_MOD_RC%
exit /b
:ajuda
echo Uso: executar.cmd [--completo] [--direto] [--somente modulo]
echo.
echo Padrao: proxy, DNS, HTTPS automatico/IPv4, Codex e sistema.
echo --completo: acrescenta IPv6, ping, tracert e regras de firewall de saida.
echo --direto: compara HTTPS sem proxy em tres destinos. Use somente se autorizado na sua rede.
echo --somente: proxy, dns, https, codex ou sistema.
echo Nenhuma configuracao de rede, certificado ou firewall e alterada.
exit /b 0
