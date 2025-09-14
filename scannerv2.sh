#!/bin/bash

# Скрипт для сканирования подсети интерфейса через arping
# Использование: sudo ./scanerv2.sh <INTERFACE>

INTERFACE="$1"

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
    echo "Запуск только из под root запускай через sudo"
    exit 1
fi

# Проверка переданного интерфейса
if [[ -z "$INTERFACE" ]]; then
    echo "Usage: $0 <network_interface>"
    exit 1
fi

if ! ip link show "$INTERFACE" > /dev/null 2>&1; then
    echo "Interface '$INTERFACE' does not exist."
    exit 1
fi

# Получаем IP и маску подсети
IP_ADDR=$(ip -4 addr show "$INTERFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+')
if [[ -z "$IP_ADDR" ]]; then
    echo "No IPv4 address found for interface '$INTERFACE'."
    exit 1
fi

# Разбираем IP и маску
IFS='/' read -r IP PREFIXLEN <<< "$IP_ADDR"
IFS='.' read -r A B C _ <<< "$IP"

# Определяем диапазон подсети (для маски /24)
if [[ "$PREFIXLEN" -ne 24 ]]; then
    echo "This script currently supports only /24 subnets. Detected /$PREFIXLEN"
    exit 1
fi

SUBNET="$A.$B.$C"

# Функция для сканирования одного IP
scan_ip() {
    local H=$1
    local IP_SCAN="${SUBNET}.${H}"
    echo "[*] Scanning IP: $IP_SCAN"
    arping -c 2 -i "$INTERFACE" "$IP_SCAN" 2>/dev/null
}

# Сканируем все хосты в подсети (1-254)
for HOST in {1..254}; do
    scan_ip "$HOST"
done
