# moons.ps1
$ErrorActionPreference = "Continue"

# Verifica se é um projeto inicializado
if (-Not (Test-Path "main.lua")) {
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host " 🌙 Inicializando o Moons Framework" -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Cyan

    $PROJECT_NAME = Read-Host "📦 Qual o nome do seu novo projeto?"

    if ([string]::IsNullOrWhiteSpace($PROJECT_NAME)) {
        Write-Host "❌ Nome inválido. Operação cancelada." -ForegroundColor Red
        exit 1
    }

    Write-Host "📥 Baixando a fundação do repositório oficial..."
    git clone --depth 1 https://github.com/KAYOGS/Moons.git $PROJECT_NAME

    Set-Location -Path $PROJECT_NAME

    Write-Host "🧹 Desvinculando histórico original e iniciando um novo repositório Git..."
    Remove-Item -Recurse -Force ".git" -ErrorAction SilentlyContinue
    git init

    Write-Host "✅ Projeto '$PROJECT_NAME' estruturado com sucesso!" -ForegroundColor Green
    Write-Host "🚀 Construindo a fundação e ambiente isolado..."
    Write-Host "------------------------------------------------------------------------"
}

$DIR = (Get-Location).Path
$IMAGE_NAME = "lua-pallene:latest"

Write-Host "🔍 Verificando imagem Docker '$IMAGE_NAME'..."

# Tenta encontrar o ID da imagem (funciona silenciosamente)
$imageExists = docker images -q $IMAGE_NAME

if ([string]::IsNullOrWhiteSpace($imageExists)) {
    Write-Host "📦 Imagem não encontrada."
    Write-Host "🔨 Baixando dependências e compilando o ambiente (Lua + Pallene)..."

    # Usando string literal (@' ... '@) para evitar conflitos com o $PATH do Linux
    $dockerfile = @'
FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    lua5.4 \
    liblua5.4-dev \
    luarocks \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN git clone --depth 1 https://github.com/pallene-lang/pallene.git
WORKDIR /opt/pallene
RUN luarocks make --local || true

ENV PATH="/root/.luarocks/bin:${PATH}"

WORKDIR /app
'@

    # Processo seguro no Windows para injetar o Dockerfile via stdin
    $tempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_.FullName }
    $dockerfile | Out-File -FilePath (Join-Path $tempDir "Dockerfile") -Encoding utf8

    # Realiza o build da imagem
    docker build -t $IMAGE_NAME $tempDir

    # Limpa os temporários
    Remove-Item -Recurse -Force $tempDir

    Write-Host "✅ Ambiente Docker construído com sucesso!" -ForegroundColor Green
} else {
    Write-Host "⚡ Ambiente pronto! Inicializando..." -ForegroundColor Green
}

Write-Host "🚀 Entrando no container..."
Write-Host ""

$bashCommand = @'
cat << 'BANNER'
========================================================================
 🌙 Moons Framework - Simple as a script. Fast as a binary.
========================================================================
 Agradecimento especial à equipe do LabLua / PUC-Rio pelo desenvolvimento
 incrível do Lua e do Pallene!

 🔗 Repositório Pallene: https://github.com/pallene-lang/pallene
 🔗 Site Oficial Lua:    https://www.lua.org/
========================================================================

BANNER
exec bash
'@

# O Windows mapeia caminhos C:\ perfeitamente usando o Docker nativo
docker run -it --rm -v "${DIR}:/app" $IMAGE_NAME bash -c $bashCommand
