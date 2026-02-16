FROM debian:bookworm-slim

ARG USERNAME=dev
ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND=noninteractive

# Paquetes base necesarios para ghcup y GHC
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    build-essential \
    git \
    libffi-dev \
    libgmp-dev \
    libncurses-dev \
    libtinfo-dev \
    zlib1g-dev \
    pkg-config \
    xz-utils \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Crear grupo y usuario con UID/GID del host
RUN groupadd -g ${GID} ${USERNAME} \
 && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME} \
 && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Instalar ghcup como usuario normal
RUN curl https://get-ghcup.haskell.org -sSf | bash -s -- -y

ENV PATH="/home/${USERNAME}/.ghcup/bin:/home/${USERNAME}/.cabal/bin:${PATH}"

# Instalar herramientas Haskell
RUN ghcup install ghc recommended \
 && ghcup install cabal recommended \
 && ghcup install hls recommended \
 && ghcup set ghc recommended \
 && ghcup set cabal recommended \
 && ghcup set hls recommended

WORKDIR /workspace

CMD ["bash"]
