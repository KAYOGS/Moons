#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

IMAGE_NAME="lua-pallene:latest"

echo "🔑 Solicitação de acesso de superusuário para o Docker:"
sudo -v

echo "🔍 Verificando imagem Docker '$IMAGE_NAME'..."

if ! sudo docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
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
