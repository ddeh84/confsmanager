# confsmanager

confsmanager is a light and portable solution to deploy plain and templated files.

It targets Docker and Podman.

Features:
* Docker build copy plain files and template files to an input directory,
* Docker run copy plain files and execute template files to an output directory.

It only updates output files that have changed, making it efficient for development workflows.

Applications can consume configuration files from a Docker volume.


It aims to fill the gap with Kubernetes configmap for Docker and Podman.


[Demo](images/demo.gif)

## Installation

### Package confsmanager

1. Clone the repository:
   ```bash
   git clone https://gitlab.com/ddeh84/confsmanager.git
   ```

2. Copy confsmanager to the Docker project:
   ```bash
   rsync -av --cvs-exclude confsmanager/ myproject/confsmanager/
   ```
   Or update it:
   ```bash
   rsync -av --cvs-exclude --exclude='input/*' --delete confsmanager/ myproject/confsmanager/
   ```

3. Create a `input` directory for your configuration files:
   ```bash
   mkdir -p input
   ```

4. Place your plain configuration files and template scripts (`.sh` files) in the `input` directory.
   ```
   confsmanager/
   └── input/                          # Your configuration files
       ├── app.conf                    # Plain file → copied as-is
       ├── database.yml                # Plain file → copied as-is
       └── nginx.conf.sh               # Template → executed, output saved as nginx.conf
   ```

5. With a Docker Registry, build & push the Docker image:
   ```bash
   docker build -t myregistry:5000/myproject-confsmanager:latest myproject/confsmanager
   docker image push myregistry:5000/myproject-confsmanager:latest
   ```

## Usage

### Make confs

confsmanager processes files from an input directory and outputs them to a mounted volume. It handles two types of files:

**Plain Files**: Any file that is not a `.sh` script is copied directly to the output directory.

Just write plain files as it is.

**Template Files**: Files with `.sh` extension are executed as shell scripts, and their stdout output is saved to the output directory (without the `.sh` extension).

For example, create a template file `input/app.conf.sh`:

```bash
#!/bin/sh
# Template that generates app.conf
cat <<EOF
server_name = ${HOSTNAME:-localhost}
port = ${PORT:-8080}
debug = ${DEBUG:-false}
EOF
```

After starting confsmanager, the output volume will contain `app.conf` with the rendered content.

Check out [heredoc](https://tldp.org/LDP/abs/html/here-docs.html).

### Access confs

The processed configuration files are available in the Docker volume `confsmanager_output` at `/var/lib/confsmanager/output`.

To use these files in another container, mount the same volume:

```yaml
services:
  myapp:
    image: myapp:latest
    volumes:
      - confsmanager_output:/etc/myapp/config:ro
```

### Initialize confs

1. Without a Docker Registry, copy the whole Docker project directory to the server.

   With a Docker Registry, update `docker-compose-registry.yml` with the Docker Registry and the Docker Image:
   ```yaml
   ---
   services:
     confsmanager:
       images: "myregistry:5000/myproject-confsmanager"
   ```
   
2. Without a Docker Registry, build and run Docker project using Docker Compose:
   ```bash
   docker compose \
     -f myproject/confsmanager/docker-compose-build.yml \
     -f myproject/docker-compose.yml \
     -p myproject up -d
   ```

   With a Docker Registry, run Docker project using Docker Compose:
   ```bash
   docker compose \
     -f myproject/confsmanager/docker-compose.yml \
     -f myproject/docker-compose.yml \
     -p myproject up -d
   ```

### Update confs

1. Update files in `input` directory.
   ```
   confsmanager/
   └── input/                          # Your configuration files
       ├── app.conf                    # Plain file → copied as-is
       ├── database.yml                # Plain file → copied as-is
       └── nginx.conf.sh               # Template → executed, output saved as nginx.conf
   ```

2. Rebuild the `confsmanager` image and push to the Docker Registry.
   ```bash
   docker build -t myregistry:5000/myproject-confsmanager:latest .
   docker image push myregistry:5000/myproject-confsmanager:latest
   ```

1. Without a Docker Registry, remove old Docker image on the server:
   ```bash
   docker rmi localhost/myproject_confsmanager:latest
   ```

3. Without a Docker Registry, rebuild the `confsmanager` image and run it:
   ```bash
   docker compose \
     -f myproject/confsmanager/docker-compose-build.yml \
     -f myproject/docker-compose.yml \
     -p myproject up -d
   ```

  With a Docker Registry, pull the new Docker image and run it with Docker compose on the server:
  ```bash
  docker compose \
    -f confsmanager/docker-compose.yml \
    -f myproject/docker-compose.yml \
    -p myproject up -d
  ```

## Support
For support, please open an issue on the [GitLab issue tracker](https://gitlab.com/ddeh84/confsmanager/-/issues).

## Roadmap
- Support for additional templating engines (envsubst, Jinja2)
- Validation hooks for generated configurations
- Multi-stage template processing
- Reload triggers for updated configurations
- Handle secrets

## Contributing
Contributions are welcome! Please follow these steps:

1. Fork the repository on GitLab
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Merge Request

Please ensure your changes are well-tested and follow the existing code style.

## Authors and acknowledgment
This project was created by [ddeh84](https://gitlab.com/ddeh84).

Special thanks to all contributors who have helped improve this project.

## License
[GNU GPLv3](https://choosealicense.com/licenses/gpl-3.0/)

## Project status
This project is actively maintained in early stage. New features and bug fixes are released regularly.
