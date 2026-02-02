# 🌍 myOS: All-in-One GIS Stack (PostGIS 18 + QGIS 3.28 + pgAdmin4)

Dieses Projekt bietet einen vollständig vorkonfigurierten, leistungsstarken GIS-Arbeitsplatz in einem Docker-Container. Er ist speziell für **macOS Apple Silicon (M1/M2/M3)** optimiert und vereint Datenbank, Management-Tools und Desktop-GIS.

## 🚀 Features
- **PostgreSQL 18 & PostGIS 3.6:** Die neueste Datenbank-Technologie für Geodaten.
- **QGIS 3.28 LTR:** Stabil isoliert in einer Micromamba-Umgebung (Deutsch).
- **pgAdmin 4:** Komfortable Weboberfläche zur Datenbankverwaltung.
- **noVNC:** QGIS direkt im Webbrowser bedienen – ohne VNC-Client Installation.
- **Kiosk-Mode:** Automatischer Vollbildstart von QGIS.
- **Full Persistence:** Alle Daten bleiben beim Neustart auf deinem Mac erhalten.

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
cd myOS
docker-compose up -d --build
```

### 2. Zugriff
- **QGIS Desktop:** [http://localhost:8081/vnc.html?resize=scale&autoconnect=1](http://localhost:8081/vnc.html?resize=scale&autoconnect=1)
- **pgAdmin4:** [http://localhost:5050](http://localhost:5050)
  - Login: `admin@admin.com` (oder wie in `.env` gesetzt)
  - PW: `adminpass`
- **Datenbank-Connect:**
  - Host: `localhost`, Port: `5432`, DB: `myos_gis`
- **SSH-Zugriff (Terminal):**
  - Befehl: `ssh root@localhost -p 2225`
  - Passwort: `ospass` (oder wie in `ROOT_PASSWORD` gesetzt)

### 3. Ordnerstruktur
- `qgis/`: Deine Profile, Plugins und lokalen GIS-Layer.
- `postgres_data/`: PostGIS Datenbankdateien.
- `pgadmin_data/`: Einstellungen von pgAdmin.
- `root/`: Linux System-Konfigurationen.

---

## 👥 Mehrbenutzer (Multisession)
Docker-Container sind primär für einen Desktop-Prozess ausgelegt. Um QGIS mit **2 oder mehr Usern** gleichzeitig zu nutzen:
1. Erstelle eine Kopie des `myOS` Ordners.
2. Ändere in der `.env` den `CONTAINER_NAME` (z.B. `myOS_User2`) und die Ports (z.B. `VNC_PORT=8082`).
3. Starte den zweiten Container.
So hat jeder User eine eigene, performante Instanz ohne Profil-Konflikte.