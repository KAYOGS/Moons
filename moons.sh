#!/usr/bin/env bash
set -e

# Função para extrair um nome seguro e único para o container baseado na pasta
get_container_name() {
    local DIR="$PWD"
    local SAFE_DIR_NAME=$(basename "$DIR" | sed 's/[^a-zA-Z0-9_]/-/g' | tr '[:upper:]' '[:lower:]')
    echo "moons_${SAFE_DIR_NAME}"
}

# Captura o primeiro argumento. Se não houver nenhum, assume "create"
COMMAND="${1:-create}"

# ==========================================
# 🛑 MOONS STOP - Encerra o ambiente
# ==========================================
if [ "$COMMAND" == "stop" ]; then
    CONTAINER_NAME=$(get_container_name)
    echo "🛑 Parando o ambiente do projeto..."
    if sudo docker ps -q -f name="^/${CONTAINER_NAME}$" | grep -q .; then
        sudo docker stop "$CONTAINER_NAME" > /dev/null 2>&1 || true
        echo "✅ Ambiente encerrado com sucesso!"
    else
        echo "⚠️ Nenhum ambiente ativo encontrado para este diretório."
    fi
    exit 0
fi

# ==========================================
# 🚀 MOONS INIT - Inicia ou conecta ao ambiente
# ==========================================
if [ "$COMMAND" == "init" ] || [ "$COMMAND" == "start" ]; then
    if [ ! -f "main.lua" ]; then
        echo "❌ Erro: Nenhum projeto Moons detectado neste diretório (main.lua ausente)."
        echo "👉 Digite apenas 'moons' para criar um novo projeto."
        exit 1
    fi

    DIR="$PWD"
    CONTAINER_NAME=$(get_container_name)
    IMAGE_NAME="lua-pallene:latest"

    echo "🔑 Solicitação de acesso de superusuário para o Docker:"
    sudo -v </dev/tty

    echo "🔍 Verificando imagem Docker '$IMAGE_NAME'..."

    # Garante que a imagem base existe na máquina
    if ! sudo docker image inspect "$IMAGE_NAME">/dev/null 2>&1; then
        echo "📦 Imagem não encontrada."
        echo "🔨 Baixando dependências e compilando o ambiente (Lua + Pallene)..."

        sudo docker build -t "$IMAGE_NAME" - << 'EOF'
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
EOF
        echo "✅ Ambiente Docker construído com sucesso!"
    fi

    echo "🔍 Verificando status do ambiente para o projeto..."

    # Se o container não estiver rodando, sobe ele em background (daemon)
    if ! sudo docker ps -q -f name="^/${CONTAINER_NAME}$" | grep -q .; then
        echo "🚀 Iniciando ambiente em background..."
        sudo docker run -d --rm --name "$CONTAINER_NAME" -v "$DIR:/app" "$IMAGE_NAME" sleep infinity > /dev/null

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
    else
        echo "⚡ Ambiente já está ativo! Conectando nova aba ao terminal existente..."
    fi

    if [ ! -t 0 ]; then
        exec < /dev/tty
    fi

    # Executa o bash interativo no container que já está de pé
    sudo docker exec -it "$CONTAINER_NAME" bash
    exit 0
fi

# ==========================================
# 📦 MOONS CREATE (Comando vazio "moons")
# ==========================================
if [ "$COMMAND" == "create" ] || [ "$COMMAND" == "new" ]; then
    # Proteção: Se o dev digitar apenas 'moons' numa pasta que JÁ É um projeto
    if [ -f "main.lua" ]; then
        echo "⚠️ Você já está dentro de um projeto Moons!"
        echo "👉 Digite 'moons init' para inicializar o ambiente deste projeto."
        exit 1
    fi

    echo "========================================================================"
    echo " 🌙 Criando um novo projeto Moons"
    echo "========================================================================"

    read -p "📦 Qual o nome do seu novo projeto? " PROJECT_NAME </dev/tty

    if [ -z "$PROJECT_NAME" ]; then
        echo "❌ Nome inválido. Operação cancelada."
        exit 1
    fi

    echo "📥 Baixando a fundação do repositório oficial..."
    git clone --depth 1 https://github.com/KAYOGS/Moons.git "$PROJECT_NAME"

    cd "$PROJECT_NAME" || exit

    echo "🧹 Desvinculando histórico original e iniciando um novo repositório Git..."
    rm -rf .git
    git init

    echo "✅ Projeto '$PROJECT_NAME' criado com sucesso!"
    echo "------------------------------------------------------------------------"
    echo "👉 Próximos passos:"
    echo "   cd $PROJECT_NAME"
    echo "   moons init"
    echo "------------------------------------------------------------------------"
    exit 0
fi

# ==========================================
# ❌ FALLBACK - Comando inválido
# ==========================================
echo "❌ Comando desconhecido: moons $COMMAND"
echo "Uso:"
echo "  moons        - Cria um novo projeto"
echo "  moons init   - Inicia ou conecta ao ambiente de desenvolvimento"
echo "  moons stop   - Encerra o ambiente ativo"
exit 1
