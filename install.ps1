# install.ps1
$ErrorActionPreference = "Stop"

Write-Host "🌙 Instalando Moons Framework..." -ForegroundColor Cyan

# 1. Verificação de Privilégios (UAC)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-Not $isAdmin) {
    Write-Host "❌ Este instalador precisa configurar o Docker e variáveis de sistema." -ForegroundColor Red
    Write-Host "👉 Por favor, feche este terminal, abra o PowerShell como Administrador e execute a instalação novamente." -ForegroundColor Yellow
    exit 1
}

Write-Host "📦 Preparando infraestrutura base..."

$requiresReboot =$false

# 2. Instalação Silenciosa do Git via Winget
if (-Not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    Write-Host "📥 Instalando Git..."
    winget install --id Git.Git -e --source winget --silent --accept-source-agreements --accept-package-agreements | Out-Null
    Write-Host "✅ Git instalado." -ForegroundColor Green
} else {
    Write-Host "✅ Git já detectado."
}

# 3. Instalação Silenciosa do Docker Desktop via Winget
if (-Not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Host "🐳 Instalando Motor Docker Desktop (Isso pode levar alguns minutos)..."
    winget install --id Docker.DockerDesktop -e --source winget --silent --accept-source-agreements --accept-package-agreements | Out-Null
    Write-Host "✅ Docker Desktop instalado." -ForegroundColor Green
    $requiresReboot =$true
} else {
    Write-Host "✅ Docker já detectado."
}

# 4. Configuração do Diretório Oculto e Core do Framework
Write-Host "📥 Configurando o ambiente de execução..."
$moonsDir = "$env:USERPROFILE\.moons"
$binDir = "$moonsDir\bin"

if (-Not (Test-Path $binDir)) { New-Item -ItemType Directory -Force -Path$binDir | Out-Null }

$corePath = "$moonsDir\core.ps1"
$repoUrl = "https://raw.githubusercontent.com/KAYOGS/Moons/main/moons.ps1"

try {
    Invoke-WebRequest -Uri $repoUrl -OutFile$corePath -UseBasicParsing
} catch {
    Write-Host "❌ Erro ao baixar o núcleo do Moons. Verifique a URL do repositório." -ForegroundColor Red
    exit 1
}

# 5. O Smart Wrapper (Arquivo .cmd)
# Isso permite rodar o Moons em qualquer terminal (CMD, PowerShell, Git Bash) sem erro de ExecutionPolicy
$cmdPath = "$binDir\moons.cmd"
$cmdContent = "@echo off`r`nPowerShell.exe -NoProfile -ExecutionPolicy Bypass -File `"%USERPROFILE%\.moons\core.ps1`" %*"
Set-Content -Path $cmdPath -Value$cmdContent -Encoding ASCII

# 6. Injeção no PATH do Sistema
$machinePath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($machinePath -notlike "*$binDir*") {
    $newPath = "$machinePath;$binDir"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
    $env:PATH = "$env:PATH;$binDir" # Injeta na sessão atual para uso imediato
}

# 7. Finalização e Tratamento do Reboot
Write-Host "========================================================================" -ForegroundColor Cyan
if ($requiresReboot) {
    Write-Host "✅ Instalação base concluída, MAS o Windows precisa ser reiniciado." -ForegroundColor Yellow
    Write-Host "O Docker Desktop requer que o WSL2/Hyper-V seja ativado na inicialização do sistema."
    Write-Host "👉 Por favor, reinicie seu computador manualmente."
    Write-Host "👉 Após reiniciar, abra um terminal, vá até sua pasta de projetos e digite 'moons'."
} else {
    Write-Host "✅ Instalação concluída com sucesso!" -ForegroundColor Green
    Write-Host "👉 Abra um novo terminal em sua pasta de projetos e digite 'moons' para começar."
}
Write-Host "========================================================================" -ForegroundColor Cyan
