terraform {
    required_providers {
        docker = {
            source = "kreuzwerker/docker"
            version = "~> 3.0"
        }
    }
}

provider "docker" {}

# ==================================================
# TODO 1 : Créer un réseau Docker
# Doc : https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/network
# Nom requis : ia-network
# Driver requis : bridge
# ==================================================
resource "docker_network" "ia_network" {
    name = "ia-network"
    driver = "bridge"
}

# ==================================================
# TODO 2 : Créer les 2 volumes persistants
# Doc : https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/volume
# Noms :
#   - ollama_storage
#   - webui_storage
# ==================================================
resource "docker_volume" "ollama_storage" {
    name = "ollama_storage"
}

resource "docker_volume" "webui_storage" {
    name = "webui_storage"
}

# ==================================================
# TODO 3 : Conteneur Ollama
# Doc : https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/container
# Contraintes :
#   - image : ollama/ollama:latest
#   - port 11434 -> 11434
#   - volume -> monté dans /root/.ollama
#   - réseau -> ia-network
#   - restart = "always"
# ==================================================

resource "docker_container" "ollama" {
    name = "ollama"
    image = "ollama/ollama:latest"

    ports {
        internal = 11434
        external = 11434
        ip = "127.0.0.1"
    }

    volumes {
        container_path = "/root/.ollama"
        volume_name = "ollama_storage"
        read_only = "false"
    }

    networks_advanced {
        name = "ia-network"
    }

    restart = "always"
}

# ==================================================
# TODO 4 : Conteneur Open WebUI
# Contraintes :
#   - image : ghcr.io/open-webui/open-webui:main
#   - port 3000 -> 8080
#   - env : OLLAMA_BASE_URL=http://ollama:11434
#   - volume -> monté dans /app/backend/data
#   - dépend du conteneur Ollama
#   - réseau -> ia-network
# ==================================================

resource "docker_container" "webui" {
    name = "webui"
    image = "ghcr.io/open-webui/open-webui:main"

    ports {
        internal = "8080"
        external = "3000"
        ip = "127.0.0.1"
    }

    env = [
        "OLLAMA_BASE_URL=http://ollama:11434"
    ]

    volumes {
        container_path = "/app/backend/data"
        volume_name = "webui_storage"
        read_only = "false"
    }
    networks_advanced {
        name = "ia-network"
    }

    depends_on = [
        docker_container.ollama
    ] 

    restart = "always"
}