#!/usr/bin/env bash
set -e

echo "🌙 Instalando Moons..."
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~$REAL_USER)

SUDO=""
if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" && "$ID_LIKE" != *"ubuntu"* && "$ID_LIKE" != *"debian"* ]]; then
        echo "❌ SO não suportado. Este instalador foi otimizado para Debian/Ubuntu e derivados."
        exit 1
    fi
fi

echo "📦 Preparando infraestrutura..."
$SUDO apt-get update -qq

command -v curl >/dev/null 2>&1 || $SUDO apt-get install -y -qq curl >/dev/null
command -v git >/dev/null 2>&1 || $SUDO apt-get install -y -qq git >/dev/null

if ! command -v docker >/dev/null 2>&1; then
    echo "🐳 Instalando Motor Docker Oficial..."
    $SUDO apt-get install -y -qq ca-certificates gnupg >/dev/null
    $SUDO install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$ID/gpg | $SUDO gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
    $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null

    $SUDO apt-get update -qq
    $SUDO apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin >/dev/null
else
    echo "✅ Docker já detectado."
fi

if ! getent group docker > /dev/null; then
    $SUDO groupadd docker
fi
$SUDO usermod -aG docker "$REAL_USER"
$SUDO systemctl enable --now docker >/dev/null 2>&1 || true

echo "📥 Configurando o ambiente de execução..."

$SUDO -u "$REAL_USER" mkdir -p "$USER_HOME/.moons"
curl -fsSL https://raw.githubusercontent.com/KAYOGS/Moons/main/moons.sh -o "$USER_HOME/.moons/core.sh"
$SUDO chmod +x "$USER_HOME/.moons/core.sh"

$SUDO mkdir -p /usr/local/bin

$SUDO tee /usr/local/bin/moons > /dev/null << EOF
#!/usr/bin/env bash
if ! docker ps >/dev/null 2>&1; then
    exec sg docker -c "$USER_HOME/.moons/core.sh \$*"
else
    exec $USER_HOME/.moons/core.sh "\$@"
fi
EOF

$SUDO chmod +x /usr/local/bin/moons

echo "✅ Instalação concluída! Abra um novo terminal ou apenas digite 'moons' em qualquer lugar para começar."
