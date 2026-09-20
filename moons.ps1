# moons.ps1
$ErrorActionPreference = "Continue"

# Função embutida para criar um nome de container seguro baseado na pasta
$DIR = (Get-Location).Path
$SAFE_DIR_NAME = (Split-Path $DIR -Leaf) -replace '[^a-zA-Z0-9_]','-'
$CONTAINER_NAME = "moons_$($SAFE_DIR_NAME.ToLower())"

# Captura o primeiro argumento, assumindo 'create' se não houver
$COMMAND = "create"
if ($args.Count -gt 0) {
    $COMMAND = $args[0].ToLower()
}

# ==========================================
# 🛑 MOONS STOP - Encerra o ambiente
# ==========================================
if ($COMMAND -eq "stop") {
    Write-Host "🛑 Parando o ambiente do projeto..." -ForegroundColor Yellow
    $isRunning = docker ps -q -f name="^/${CONTAINER_NAME}$"
    if (-Not [string]::IsNullOrWhiteSpace($isRunning)) {
        docker stop $CONTAINER_NAME | Out-Null
        Write-Host "✅ Ambiente encerrado com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Nenhum ambiente ativo encontrado para este diretório." -ForegroundColor DarkYellow
    }
    exit 0
}

# ==========================================
# 🚀 MOONS INIT - Inicia ou conecta ao ambiente
# ==========================================
if ($COMMAND -eq "init" -or $COMMAND -eq "start") {
    if (-Not (Test-Path "main.lua")) {
        Write-Host "❌ Erro: Nenhum projeto Moons detectado neste diretório (main.lua ausente)." -ForegroundColor Red
        Write-Host "👉 Digite apenas 'moons' para criar um novo projeto."
        exit 1
    }

    $IMAGE_NAME = "lua-pallene:latest"
    Write-Host "🔍 Verificando imagem Docker '$IMAGE_NAME'..."

    # Garante que a imagem base existe[cite: 8]
    $imageExists = docker images -q $IMAGE_NAME
    if ([string]::IsNullOrWhiteSpace($imageExists)) {
        Write-Host "📦 Imagem não encontrada."
        Write-Host "🔨 Baixando dependências e compilando o ambiente (Lua + Pallene)..." -ForegroundColor Cyan

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
        $tempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_.FullName }
        $dockerfile | Out-File -FilePath (Join-Path $tempDir "Dockerfile") -Encoding utf8
        docker build -t $IMAGE_NAME $tempDir
        Remove-Item -Recurse -Force $tempDir
        Write-Host "✅ Ambiente Docker construído com sucesso!" -ForegroundColor Green
    }

    Write-Host "🔍 Verificando status do ambiente para o projeto..."

    $isRunning = docker ps -q -f name="^/${CONTAINER_NAME}$"
    if ([string]::IsNullOrWhiteSpace($isRunning)) {
        Write-Host "🚀 Iniciando ambiente em background..." -ForegroundColor Cyan
        # Roda em background e amarra o volume do Windows[cite: 8, 9]
        docker run -d --rm --name $CONTAINER_NAME -v "${DIR}:/app" $IMAGE_NAME sleep infinity | Out-Null

        Write-Host @"

========================================================================
 🌙 Moons Framework - Simple as a script. Fast as a binary.
========================================================================
 Agradecimento especial à equipe do LabLua / PUC-Rio pelo desenvolvimento
 incrível do Lua e do Pallene!

 🔗 Repositório Pallene: https://github.com/pallene-lang/pallene
 🔗 Site Oficial Lua:    https://www.lua.org/
========================================================================

"@ -ForegroundColor Cyan
    } else {
        Write-Host "⚡ Ambiente já está ativo! Conectando nova aba ao terminal existente..." -ForegroundColor Green
    }

    # Conecta interativamente
    docker exec -it $CONTAINER_NAME bash
    exit 0
}

# ==========================================
# 📦 MOONS CREATE (Comando vazio "moons")
# ==========================================
if ($COMMAND -eq "create" -or $COMMAND -eq "new") {
    if (Test-Path "main.lua") {
        Write-Host "⚠️ Você já está dentro de um projeto Moons!" -ForegroundColor DarkYellow
        Write-Host "👉 Digite 'moons init' para inicializar o ambiente deste projeto."
        exit 1
    }

    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host " 🌙 Criando um novo projeto Moons" -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Cyan

    $PROJECT_NAME = Read-Host "📦 Qual o nome do seu novo projeto?"

    if ([string]::IsNullOrWhiteSpace($PROJECT_NAME)) {
        Write-Host "❌ Nome inválido. Operação cancelada." -ForegroundColor Red
        exit 1
    }

    Write-Host "📥 Baixando a fundação do repositório oficial..."
    git clone --depth 1 https://github.com/KAYOGS/Moons.git $PROJECT_NAME

    Set-Location -Path $PROJECT_NAME

    Write-Host "🧹 Limpando arquivos internos de instalação do framework..."
    Remove-Item -Force "install.sh", "install.ps1", "moons.sh", "moons.ps1", "MoonsIcon.png" -ErrorAction SilentlyContinue

    Write-Host "🧹 Desvinculando histórico original e iniciando um novo repositório Git..."
    Remove-Item -Recurse -Force ".git" -ErrorAction SilentlyContinue
    git init

    Write-Host "✅ Projeto '$PROJECT_NAME' criado com sucesso!" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------------"
    Write-Host "👉 Próximos passos:"
    Write-Host "   cd $PROJECT_NAME"
    Write-Host "   moons init"
    Write-Host "------------------------------------------------------------------------"
    exit 0
}

# ==========================================
# ❌ FALLBACK - Comando inválido
# ==========================================
Write-Host "❌ Comando desconhecido: moons $COMMAND" -ForegroundColor Red
Write-Host "Uso:"
Write-Host "  moons        - Cria um novo projeto"
Write-Host "  moons init   - Inicia ou conecta ao ambiente de desenvolvimento"
Write-Host "  moons stop   - Encerra o ambiente ativo"
exit 1
