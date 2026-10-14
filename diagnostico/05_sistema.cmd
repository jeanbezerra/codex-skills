@echo off
setlocal EnableExtensions DisableDelayedExpansion
if not defined DGN_DIR (
 call "%~dp0executar.cmd" --somente sistema
 exit /b
)
echo WINDOWS, RELOGIO, FIREWALL E EVENTOS TLS
echo Consultas somente leitura. Erros de permissao sao registrados, sem elevacao automatica.
echo.
ver
date /t
time /t
tzutil /g
echo.
w32tm /query /status
echo codigo_saida=%errorlevel%
echo Hora incorreta pode invalidar certificados e autenticacao.
echo.
netsh advfirewall show allprofiles
echo codigo_saida=%errorlevel%
echo Firewall local e apenas uma camada. Estado ativo nao prova bloqueio de um destino.
echo Antimalware, VPN, EDR e firewalls externos podem filtrar conexoes sem aparecer aqui.
echo.
echo Ultimos eventos Schannel - podem ser de outros aplicativos:
wevtutil qe System /q:"*[System[Provider[@Name='Schannel']]]" /c:12 /rd:true /f:text
echo codigo_saida=%errorlevel%
if not "%DGN_COMPLETO%"=="1" exit /b 0
echo.
echo Conexoes TCP locais:
netstat -ano -p tcp
echo codigo_saida=%errorlevel%
echo.
echo Regras de firewall de saida - arquivo separado:
netsh advfirewall firewall show rule name=all dir=out > "%DGN_DIR%\firewall_saida.txt" 2>&1
echo codigo_saida=%errorlevel%
echo Regras habilitadas, perfil e programa devem ser correlacionados manualmente.
exit /b 0
