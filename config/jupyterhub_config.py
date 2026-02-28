# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Configuration file for JupyterHub
import os

c = get_config()  # noqa: F821

# Spawn single-user servers as Docker containers
c.JupyterHub.spawner_class = "dockerspawner.DockerSpawner"

# Spawn containers from this image
c.DockerSpawner.image = os.environ["DOCKER_NOTEBOOK_IMAGE"]

# Connect containers to this Docker network
network_name = os.environ["DOCKER_NETWORK_NAME"]
c.DockerSpawner.use_internal_ip = True
c.DockerSpawner.network_name = network_name

# Explicitly set notebook directory because we mount a volume to it
notebook_dir = os.environ.get("DOCKER_NOTEBOOK_DIR", "/home/jovyan/work")
c.DockerSpawner.notebook_dir = notebook_dir

# Mount the user's Docker volume into the notebook directory
c.DockerSpawner.volumes = {"jupyterhub-user-{username}": notebook_dir}

# --------------------------------------------------
# Timezone: keep containers 100% consistent with host
# --------------------------------------------------

# Bind-mount host timezone files for system-level consistency
c.DockerSpawner.volumes.update({
    "/etc/localtime": {
        "bind": "/etc/localtime",
        "mode": "ro",
    },
    "/etc/timezone": {
        "bind": "/etc/timezone",
        "mode": "ro",
    },
})

# Remove containers once they are stopped
c.DockerSpawner.remove = True

# Enable debug logging for spawned containers
c.DockerSpawner.debug = True

# Environment variables passed into notebook containers
c.DockerSpawner.environment = {
    # --------------------------------------------------
    # Timezone fallback (some applications only read TZ)
    # --------------------------------------------------
    "TZ": os.environ.get("TZ", "Asia/Shanghai"),

    # --------------------------------------------------
    # Notebook user identity
    # --------------------------------------------------
    "NB_UID": "1000",
    "NB_GID": "1000",

    # --------------------------------------------------
    # GaussDB configuration
    # --------------------------------------------------
    "GAUSSDB_HOST": os.environ.get("GAUSSDB_HOST", "localhost"),
    "GAUSSDB_PORT": os.environ.get("GAUSSDB_PORT", "5432"),
    "GAUSSDB_DBNAME": os.environ.get("GAUSSDB_DBNAME", "gaussdb"),
    "GAUSSDB_USER": os.environ.get("GAUSSDB_USER", "gaussdb"),
    "GAUSSDB_PASSWORD": os.environ.get("GAUSSDB_PASSWORD", "P@ssw1rd"),

    # --------------------------------------------------
    # Vertica configuration
    # --------------------------------------------------
    "VERTICA_HOST": os.environ.get("VERTICA_HOST", "localhost"),
    "VERTICA_PORT": os.environ.get("VERTICA_PORT", "5433"),
    "VERTICA_DBNAME": os.environ.get("VERTICA_DBNAME", "vertica"),
    "VERTICA_USER": os.environ.get("VERTICA_USER", "vertica"),
    "VERTICA_PASSWORD": os.environ.get("VERTICA_PASSWORD", "P@ssw1rd"),
    
    # --------------------------------------------------
    # ODPS configuration
    # --------------------------------------------------
    "ODPS_ACCESS_ID": os.environ.get("ODPS_ACCESS_ID", "<your-access-id>"),
    "ODPS_ACCESS_KEY": os.environ.get("ODPS_ACCESS_KEY", "<your-access-key>"),
    "ODPS_PROJECT": os.environ.get("ODPS_PROJECT", "<your-project>"),
    "ODPS_ENDPOINT": os.environ.get("ODPS_ENDPOINT", "<your-endpoint>"),
}

# User containers access the Hub via container name on the Docker network
c.JupyterHub.hub_ip = "jupyterhub"
c.JupyterHub.hub_port = 8080

# Persist Hub state on a mounted volume
c.JupyterHub.cookie_secret_file = "/data/jupyterhub_cookie_secret"
c.JupyterHub.db_url = "sqlite:////data/jupyterhub.sqlite"

# Allow all users to log in
c.Authenticator.allow_all = True

# Use Native Authenticator
c.JupyterHub.authenticator_class = "nativeauthenticator.NativeAuthenticator"

# Allow open user signup
c.NativeAuthenticator.open_signup = True

# Configure admin users
admin = os.environ.get("JUPYTERHUB_ADMIN")
if admin:
    c.Authenticator.admin_users = [admin]
