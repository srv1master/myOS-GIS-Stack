FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

# 1. Basis-System & Repositories (PostgreSQL 18)
RUN apt-get update && apt-get install -y \
    curl ca-certificates gnupg lsb-release sudo software-properties-common wget \
    tzdata locales language-pack-de language-pack-de-base \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && locale-gen de_DE.UTF-8

# PostgreSQL 18 Repo
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/keyrings/postgresql.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# 2. Installation aller Komponenten
RUN apt-get update && apt-get install -y \
    postgresql-18 \
    postgresql-18-postgis-3 \
    openssh-server \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    openbox \
    devilspie2 \
    python3-pip \
    dbus-x11 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. pgAdmin4 & Gunicorn via PIP
RUN pip3 install pgadmin4 gunicorn

# 4. Micromamba für QGIS 3.28
RUN curl -Ls https://micro.mamba.pm/api/micromamba/linux-aarch64/latest | tar -xj bin/micromamba && \
    mv bin/micromamba /usr/local/bin/ && \
    micromamba create -y -p /opt/qgis_env -c conda-forge qgis=3.28 python=3.10

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