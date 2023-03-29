# Server Setup Script.

This repository contains a shell script to quickly set up an all-in-one media server with Docker containers. The script installs Wireguard (optional), sets up Docker containers for various media server applications, and creates a Cloudflare tunnel (optional). I made this script to easily and quickly set up a new VPS. I switch between different VPSs sometimes, so I wanted an easy way to get everything going again. This script assumes you have a separate server that has all of the "Main stuff" on another, likely local, server. The script automatically configures and starts the Docker containers for the following services:

- Portainer
- NGINX Proxy Manager
- Organizr
- Overseerr
- Tautulli
- Watchtower

## Prerequisites

- A Linux system with root access
- Docker and Docker Compose installed
- A Cloudflare account with an active domain (if using the Cloudflare tunnel)

## Installation

1. Clone this repository to your local machine:

git clone https://github.com/bitnotfound/VPS-All-in-One-Setup.git


2. Change directory to the repository:

cd serversetup

3. Make the script executable:

chmod +x serversetup.sh

4. Run the script with sudo or as root:

sudo ./serversetup.sh

5. Follow the on-screen prompts to install Wireguard (optional), set up Docker containers, and create a Cloudflare tunnel (optional).

6. Once the script is complete, you will receive the web UI URLs for each container and your public IP address.

7. If you have set up a Cloudflare tunnel, add the provided CNAME to your Cloudflare DNS settings.

## Usage

After running the script, you can access the web UIs for each container using the URLs provided. To manage your Docker containers, use Portainer, which is accessible via the provided URL.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[AGPLv3](https://choosealicense.com/licenses/agpl-3.0/)