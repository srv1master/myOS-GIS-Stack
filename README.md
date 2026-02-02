# 🌍 myOS: All-in-One GIS Stack (Debian 13 Slim + PostGIS + QGIS 3.28 + pgAdmin4)

Dieses Projekt bietet einen vollständig vorkonfigurierten, leistungsstarken GIS-Arbeitsplatz in einem Docker-Container. Er ist auf Basis von **Debian 13 (Trixie) Slim** aufgebaut, speziell für **macOS Apple Silicon (M1/M2/M3)** optimiert und vereint Datenbank, Management-Tools und Desktop-GIS.

## 🚀 Features
- **OS: Debian 13 (Trixie) Slim:** Schlankes, modernes Basissystem.
- **PostgreSQL & PostGIS:** Stabile Datenbank-Technologie für Geodaten (Auto-Detect Version).
- **QGIS 3.28 LTR:** Stabil isoliert in einer Micromamba-Umgebung mit automatischer Persistenz.
- **Full Environment Persistence:** Das gesamte QGIS-Environment (`/opt/qgis_env`) ist persistent. Du kannst Pakete nachinstallieren, und sie bleiben erhalten.
- **Auto-Initialization:** Bei der ersten Nutzung wird das Environment automatisch in dein lokales Volume kopiert.
- **pgAdmin 4:** Komfortable Weboberfläche zur Datenbankverwaltung.
- **noVNC:** QGIS direkt im Webbrowser bedienen – ohne VNC-Client Installation.
- **Kiosk-Mode:** Automatischer Vollbildstart von QGIS mit Watchdog-Funktion.

---

## ⚙️ Konfiguration (`.env`)

Du kannst das gesamte System über die Datei `.env` steuern. Hier sind die Parameter erklärt:

### 🏗️ System & Sicherheit
| Variable | Default | Beschreibung |
| :--- | :--- | :--- |
| `CONTAINER_NAME` | `myOS` | Name des Docker-Containers. |
| `ROOT_PASSWORD` | `ospass` | Passwort für SSH (User: root). |
| `TZ` | `Europe/Berlin` | Zeitzone für das gesamte System. |

### 🌐 Netzwerk (Ports auf deinem Mac)
| Variable | Default | Beschreibung |
| :--- | :--- | :--- |
| `VNC_PORT` | `8081` | **QGIS im Browser** unter `http://localhost:8081` |
| `PGADMIN_PORT` | `5050` | **pgAdmin Web** unter `http://localhost:5050` |
| `DB_PORT` | `5432` | Direkter Datenbank-Zugriff (PostgreSQL). |
| `SSH_PORT` | `2225` | SSH-Konsole. |

### 🐘 Datenbank (PostGIS)
| Variable | Default | Beschreibung |
| :--- | :--- | :--- |
| `DB_USER` | `admin` | Datenbank-Benutzername. |
| `DB_PASSWORD` | `adminpass` | Passwort für die Datenbank. |
| `DB_NAME` | `myos_gis` | Name der GIS-Datenbank. |

### 🖥️ Grafik & UI
| Variable | Default | Beschreibung |
| :--- | :--- | :--- |
| `RESOLUTION` | `2560x1440x24` | Desktop-Auflösung (Breite x Höhe x Tiefe). |
| `UI_SCALE` | `1.5` | Skalierung (wichtig für 4K/Retina Monitore). |
| `SYSTEM_LANG` | `de` | Sprache von QGIS und System (de, en). |

---

## 🛠 Start & Nutzung

### 1. System starten
```bash
docker-compose up -d --build
```
*Hinweis: Beim ersten Start wird das QGIS-Environment (~2GB) in den Ordner `./qgis_env_data` kopiert. Dies kann 1-2 Minuten dauern.*

### 2. Zugriff
- **QGIS Desktop:** [http://localhost:8081/vnc.html?resize=scale&autoconnect=1](http://localhost:8081/vnc.html?resize=scale&autoconnect=1)
- **pgAdmin4:** [http://localhost:5050](http://localhost:5050)
- **Datenbank-Connect:** `localhost:5432` (User: admin, DB: myos_gis)
- **SSH-Zugriff:** `ssh root@localhost -p 2225` (PW: ospass)

### 3. Ordnerstruktur (Persistenz)
- `qgis_data/`: Deine QGIS-Profile, Plugins und Einstellungen.
- `qgis_env_data/`: Das Micromamba Environment. Hier kannst du permanent Pakete nachinstallieren.
- `postgres_data/`: Die PostGIS Datenbankdateien.
- `pgadmin_data/`: Einstellungen von pgAdmin.
- `projekts/`: Ablageort für deine GIS-Projektdateien (`.qgz`).
- `root_data/`: Linux System-Konfigurationen (Home-Verzeichnis von root).

---

## 🔧 Pakete nachinstallieren
Um dauerhaft Pakete im QGIS-Environment zu installieren:
```bash
docker exec myOS micromamba install -p /opt/qgis_env -c conda-forge <paketname>
```

---

## 👥 Mehrbenutzer (Multisession)
Docker-Container sind primär für einen Desktop-Prozess ausgelegt. Um QGIS mit **2 oder mehr Usern** gleichzeitig zu nutzen:
1. Erstelle eine Kopie dieses Ordners.
2. Ändere in der `.env` den `CONTAINER_NAME` und die Ports.
3. Starte den neuen Stack.
So hat jeder User eine eigene Instanz ohne Konflikte.
