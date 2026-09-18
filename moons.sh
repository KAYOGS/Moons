#!/usr/bin/env bash
set -e

if [ ! -f "main.lua" ]; then
    echo "========================================================================"
    echo " 🌙 Inicializando o Moons Framework"
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

    echo "✅ Projeto '$PROJECT_NAME' estruturado com sucesso!"
    echo "🚀 Construindo a fundação e ambiente isolado..."
    echo "------------------------------------------------------------------------"
fi

DIR="$PWD"

IMAGE_NAME="lua-pallene:latest"

echo "🔑 Solicitação de acesso de superusuário para o Docker:"
sudo -v </dev/tty

echo "🔍 Verificando imagem Docker '$IMAGE_NAME'..."

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
else
    echo "⚡ Ambiente pronto! Inicializando..."
fi

echo "🚀 Entrando no container..."
echo ""
if [ ! -t 0 ]; then
    exec < /dev/tty
fi

sudo docker run -it --rm -v "$DIR:/app" "$IMAGE_NAME" bash -c "
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
"
