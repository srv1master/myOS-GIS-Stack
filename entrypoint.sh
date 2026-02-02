#!/bin/bash

# ==============================================================================
# 🚀 myOS ALL-IN-ONE ENTRYPOINT (Auto-Detect PostgreSQL Version)
# ==============================================================================

# --- 1. SYSTEM-INITIALISIERUNG ---
# Zeitzone setzen
ln -snf /usr/share/zoneinfo/${TZ:-Europe/Berlin} /etc/localtime
echo ${TZ:-Europe/Berlin} > /etc/timezone

# Lokalisierung
export LANG=de_DE.UTF-8
export LANGUAGE=de_DE:de
export LC_ALL=de_DE.UTF-8

# SSH Passwort setzen
echo "root:${ROOT_PASSWORD:-ospass}" | chpasswd

# D-Bus vorbereiten (Wichtig für QGIS)
mkdir -p /var/run/dbus
dbus-uuidgen > /var/lib/dbus/machine-id
dbus-daemon --system --fork --allow-anonymous 2>/dev/null
export DBUS_SESSION_BUS_ADDRESS=unix:path=/var/run/dbus/system_bus_socket

# --- 1.1 QGIS ENVIRONMENT WIEDERHERSTELLUNG (Persistence Fix) ---
# Wenn der externe Ordner gemountet ist, ist er anfangs leer. Wir füllen ihn aus dem Backup im Image.
if [ ! -f "/opt/qgis_env/bin/qgis" ] && [ -d "/opt/qgis_env_backup" ]; then
    echo "[myOS] Erster Start erkannt: Installiere QGIS Environment in persistentes Volume..."
    echo "[myOS] Kopiere Dateien (das kann einen Moment dauern)..."
    cp -a /opt/qgis_env_backup/. /opt/qgis_env/
    echo "[myOS] Environment erfolgreich wiederhergestellt."
fi

# --- 2. DATENBANK (PostgreSQL Auto-Detect) ---
PG_DATA="/var/lib/postgresql/data"
mkdir -p /var/run/postgresql && chown -R postgres:postgres /var/run/postgresql
mkdir -p /var/log/postgresql && chown -R postgres:postgres /var/log/postgresql

# Finde PostgreSQL Binaries (höchste Version)
PG_BIN=$(ls -d /usr/lib/postgresql/*/bin | sort -V | tail -n 1)
echo "[myOS] PostgreSQL Binaries gefunden in: $PG_BIN"

if [ ! -s "$PG_DATA/PG_VERSION" ]; then
    echo "[myOS] Initialisiere neue Datenbank..."
    rm -rf "$PG_DATA"/*
    chown -R postgres:postgres "$PG_DATA"
    sudo -u postgres "$PG_BIN/initdb" -D "$PG_DATA"
    echo "host all all 0.0.0.0/0 md5" >> "$PG_DATA/pg_hba.conf"
    echo "listen_addresses='*'" >> "$PG_DATA/postgresql.conf"
fi
chown -R postgres:postgres "$PG_DATA"
sudo -u postgres "$PG_BIN/pg_ctl" -D "$PG_DATA" -l /var/log/postgresql/main.log start

# User & GIS Datenbank anlegen
sleep 3
sudo -u postgres psql -c "CREATE USER ${DB_USER:-admin} WITH PASSWORD '${DB_PASSWORD:-adminpass}' SUPERUSER;" 2>/dev/null
sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME:-myos_gis} OWNER ${DB_USER:-admin};" 2>/dev/null
sudo -u postgres psql -d ${DB_NAME:-myos_gis} -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2>/dev/null

# --- 3. PGADMIN4 (Web-Interface) ---
export PGADMIN_SETUP_EMAIL=${PGADMIN_DEFAULT_EMAIL:-admin@admin.com}
export PGADMIN_SETUP_PASSWORD=${PGADMIN_DEFAULT_PASSWORD:-adminpass}
export PGADMIN_CONFIG_SERVER_MODE=True
export PGADMIN_CONFIG_DATA_DIR=/var/lib/pgadmin
export PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION=False

mkdir -p /var/lib/pgadmin && chown -R root:root /var/lib/pgadmin
# In Debian 12+ (PEP 668) müssen wir aufpassen, aber wir haben mit --break-system-packages installiert
python3 -m pgadmin4.setup setup-db >/dev/null 2>&1

echo "[myOS] Starte pgAdmin4 Web-Interface..."
gunicorn --bind 0.0.0.0:80 --workers 1 --timeout 120 pgadmin4.pgAdmin4:app &

# --- 4. GRAFIK & KIOSK (QGIS) ---
rm -f /tmp/.X*-lock /tmp/.X11-unix/X*
Xvfb :1 -screen 0 ${RESOLUTION:-2560x1440x24} &
sleep 2
export DISPLAY=:1

openbox &
devilspie2 --folder /root/.config/devilspie2 &
x11vnc -display :1 -nopw -forever -shared -bg -rfbport 5900 -noxdamage

# noVNC Web-Proxy
/usr/bin/python3 -m websockify --web /usr/share/novnc/ --wrap-mode=ignore 8081 localhost:5900 &

# --- 5. QGIS WATCHDOG ---
(
    export PATH="/opt/qgis_env/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/qgis_env/lib:$LD_LIBRARY_PATH"
    export QT_SCALE_FACTOR=${UI_SCALE:-1.0}
    while true; do
        echo "[myOS] Starte QGIS..."
        qgis --lang ${SYSTEM_LANG:-de} --nologo --nocustomization
        sleep 2
    done
) &

# --- 6. SSH ---
mkdir -p /run/sshd
echo "[myOS] System vollständig bereit."
/usr/sbin/sshd -D