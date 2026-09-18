#!/usr/bin/env bash
echo "🌙 Instalando Moons Framework..."
SUDO=""
if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
fi

$SUDO mkdir -p /usr/local/bin
$SUDO curl -fsSL https://raw.githubusercontent.com/KAYOGS/Moons/main/moons.sh -o /usr/local/bin/moons
$SUDO chmod +x /usr/local/bin/moons

echo "✅ Instalação concluída! Abra um novo terminal e digite 'moons' para começar."
