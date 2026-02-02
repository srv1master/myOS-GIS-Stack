FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

# 1. Basis-System & Repositories
# bzip2 wird für micromamba install benötigt.
# procps für Prozess-Management.
RUN apt-get update && apt-get install -y \
    curl ca-certificates gnupg lsb-release sudo wget bzip2 \
    tzdata locales procps \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && sed -i 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen

# 2. Installation aller Komponenten (inkl. GUI Libs für QGIS/Qt in Slim)
# Slim-Images fehlen wichtige X11/GL Libraries, die wir hier nachrüsten (libgl1, libxkbcommon, etc.)
RUN apt-get update && apt-get install -y \
    postgresql \
    postgis \
    openssh-server \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    openbox \
    devilspie2 \
    python3-pip \
    dbus-x11 \
    fonts-open-sans \
    fonts-dejavu \
    fonts-liberation \
    fontconfig \
    libgl1 \
    libglib2.0-0 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxkbcommon-x11-0 \
    libdbus-1-3 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. pgAdmin4 & Gunicorn via PIP
RUN pip3 install pgadmin4 gunicorn --break-system-packages --ignore-installed --no-cache-dir

# 4. Micromamba für QGIS 3.28
# Download & Install Micromamba (braucht bzip2)
RUN curl -Ls https://micro.mamba.pm/api/micromamba/linux-aarch64/latest | tar -xj -C /usr/local/bin --strip-components=1 bin/micromamba

# Create Env (mit --always-copy gegen Symlink Errors auf OverlayFS/Mac)
RUN micromamba create -y -p /opt/qgis_env -c conda-forge qgis=3.28 python=3.10 --always-copy && \
    micromamba clean --all -y

# BACKUP: Wir verschieben das Env, damit wir es im Entrypoint in das persistente Volume kopieren können
RUN mv /opt/qgis_env /opt/qgis_env_backup && mkdir -p /opt/qgis_env

# 5. Konfiguration
ENV PATH="/opt/qgis_env/bin:$PATH"
ENV LANG=de_DE.UTF-8
ENV LANGUAGE=de_DE:de
ENV LC_ALL=de_DE.UTF-8
ENV DISPLAY=:1

RUN echo 'root:ospass' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    ssh-keygen -A && \
    mkdir -p /run/sshd

WORKDIR /root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /root/.config/openbox /root/.config/devilspie2 /root/.local/share/QGIS /var/lib/postgresql/data /var/lib/pgadmin /var/run/postgresql && \
    chown -R postgres:postgres /var/run/postgresql

EXPOSE 22 8081 5050 5432
ENTRYPOINT ["/entrypoint.sh"]