@echo off
setlocal EnableExtensions DisableDelayedExpansion
if not defined DGN_DIR (
 call "%~dp0executar.cmd" --somente codex
 exit /b
)
echo CODEX CLI E CONFIGURACAO LOCAL
echo Conteudos de auth.json, chaves, tokens e conversas nao sao exportados.
echo O comando login status consulta as credenciais pelo proprio CLI.
echo Apenas a presenca de algumas chaves de configuracao e registrada.
echo.
where codex > "%DGN_DIR%\codex_caminhos.txt" 2>nul
if errorlevel 1 (
 echo Codex nao encontrado no PATH deste CMD.
 > "%DGN_DIR%\sinal_codex_ausente.txt" echo Codex nao encontrado no PATH
 goto runtime
)
type "%DGN_DIR%\codex_caminhos.txt"
call codex --version
set "DGN_VERSION_RC=%errorlevel%"
echo codigo_saida_version=%DGN_VERSION_RC%
if not "%DGN_VERSION_RC%"=="0" > "%DGN_DIR%\sinal_codex_versao.txt" echo Falha ao executar codex --version
echo.
echo Consultando credenciais locais, com toda a saida omitida:
call codex login status >nul 2>&1
set "DGN_AUTH_RC=%errorlevel%"
echo codigo_saida_login_status=%DGN_AUTH_RC%
> "%DGN_DIR%\codex_login_status.txt" echo codigo_saida=%DGN_AUTH_RC%
if "%DGN_AUTH_RC%"=="0" (
 echo Credenciais locais presentes. Isto nao confirma validade, plano ou acesso remoto.
 > "%DGN_DIR%\sinal_codex_auth_ok.txt" echo Credenciais locais presentes
) else (
 echo Credenciais nao confirmadas; pode haver ausencia de login ou erro local de configuracao.
 > "%DGN_DIR%\sinal_codex_auth.txt" echo Login local nao confirmado
)
:runtime
echo.
where node.exe >nul 2>&1
if not errorlevel 1 node.exe --version
where npm >nul 2>&1
if not errorlevel 1 call npm --version
echo Node/npm podem usar uma cadeia de certificados diferente do curl/Schannel.
echo.
set "DGN_CODEX_DIR=%USERPROFILE%\.codex"
if defined CODEX_HOME set "DGN_CODEX_DIR=%CODEX_HOME%"
call :config "%DGN_CODEX_DIR%\config.toml" usuario
call :config "%~dp0..\.codex\config.toml" projeto
call :config "%DGN_CODEX_DIR%\requirements.toml" requisitos_usuario
call :config "%ProgramData%\OpenAI\Codex\requirements.toml" requisitos_maquina_candidato
echo.
echo Caminhos candidatos nao cobrem todas as politicas da empresa nem todos os perfis.
echo Configuracoes em ancestrais, perfis e registro gerenciado podem alterar o resultado.
echo Proxy de comandos sandbox nao necessariamente controla a conexao do proprio Codex.
echo Para inspecao manual no Codex, consulte /debug-config e /status.
exit /b 0
:config
echo --- Configuracao: %~2 ---
if not exist "%~1" (
 echo Arquivo candidato ausente.
 exit /b
)
echo Arquivo candidato presente. Conteudo e valores nao sao exportados.
for %%K in (openai_base_url chatgpt_base_url base_url model_provider network_access proxy_url socks_url allow_upstream_proxy allowed_domains denied_domains domains forced_login_method forced_chatgpt_workspace_id) do call :chave "%~1" %%K
findstr /i /c:"network_proxy" /c:"experimental_network" /c:"permissions." "%~1" >nul 2>&1
if not errorlevel 1 echo Referencia a proxy/restricao de rede encontrada; pode estar em comentario.
exit /b
:chave
findstr /r /i /c:"^[ ]*%~2[ ]*=" "%~1" >nul 2>&1
if not errorlevel 1 echo Chave %~2 presente [valor omitido].
exit /b
