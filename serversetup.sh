#!/bin/sh

GREEN='\e[0;32m'
RED='\e[0;31m'
NC='\e[0m'

clear
echo "${GREEN}Updating Package Repositories${NC}"
apt -q update
apt -y -q upgrade

while true; do
  echo -n "${GREEN}Do you want to set up Wireguard? (${RED}Y${GREEN}/${RED}N${GREEN})${NC} "
  read WGSETUP
  case $WGSETUP in
    [Yy]* )
      echo "${GREEN}Installing Wireguard${NC}"
      apt install -y -q wireguard

      clear
      echo "${GREEN}Setting Up Wireguard${NC}"
      dest_file="/etc/wireguard/wg0.conf"
      while true; do
        echo "${GREEN}Do you want to:${NC}"
        echo "${GREEN}(${RED}1${GREEN}) Input a file path to the Wireguard configuration file${NC}"
        echo -n "${GREEN}(${RED}2${GREEN}) Paste the configuration file contents${NC} "
        read WGCOPY

        case $WGCOPY in
          1 )
            while true; do
              clear
              echo -n "${GREEN}Enter the configuration file's path: ${NC}"
              read src_path

              if [ -f "$src_path" ]; then
                sudo cp "$src_path" "$dest_file"
                echo "${GREEN}File copied successfully to $dest_file.${NC}"
                break 2
              else
                clear
                echo "${RED}Invalid file path.${NC}"
              fi
            done
            ;;
          2 )
            clear
            echo "${GREEN}Enter the text you want to save (type '${RED}EOF${GREEN}' on a new line to finish):${NC}"
            user_text=""
            while IFS= read -r line; do
              if [ "$line" = "EOF" ]; then
                break
              fi
              user_text="${user_text}${line}"$'\n'
            done

            echo "$user_text" | sudo tee "$dest_file" > /dev/null
            echo "${GREEN}Configuration file saved to $dest_file successfully.${NC}"
            break
            ;;
          * )
            echo "${RED}Invalid choice. Please select either 1 or 2.${NC}"
            ;;
        esac
        systemctl enable wg-quick@wg0.service
        systemctl daemon-reload
        sudo systemctl start wg-quick@wg0
      done
      break
      ;;
    [Nn]* )
      echo "${GREEN}Skipping Setup.${NC}"
      break
      ;;
    * )
      echo "${RED}Please answer with yes or no.${NC}"
      ;;
  esac
done

clear
echo "${GREEN}Setting Up Docker Containers${NC}"
docker network create $HOSTNAME
docker volume create portainer
docker volume create npm
docker volume create letsencrypt
docker volume create organizr
docker volume create overseerr
docker volume create tautulli
docker volume create cloudflared
docker create --name=portainer -v /var/run/docker.sock:/var/run/docker.sock -v portainer:/data -p 8000:8000 -p 9443:9443 --restart=always --network=$HOSTNAME portainer/portainer-ce:latest
docker create --name=npm -v npm:/data -p 80:80 -p 443:443 -p 81:81 --restart=always --network=$HOSTNAME -v letsencrypt:/etc/letsencrypt jc21/nginx-proxy-manager:latest
docker create --name=organizr -v organizr:/config -p 3245:80 --restart unless-stopped --network=$HOSTNAME -e PUID=1000 -e PGID=998 -e fpm="false" -e branch="v2-master" organizr/organizr
docker create --name=overseerr -v overseerr:/app/config -p 5055:5055 --restart unless-stopped --network=$HOSTNAME -e LOG_LEVEL=debug -e TZ=America/Los_Angeles -e PORT=5055 sctx/overseerr
docker create --name=tautulli -v tautulli:/config -p 8181:8181 --restart=unless-stopped --network=$HOSTNAME -e PUID=1000 -e PGID=998 -e TZ=America/Los_Angeles ghcr.io/tautulli/tautulli
docker create --name=watchtower --network=$HOSTNAME -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower

while true; do
  echo -n "${GREEN}Do you want to set up a cloudflare tunnel? (${RED}Y${GREEN}/${RED}N${GREEN})${NC} "
  read cftun

  case $cftun in
    [Yy]* )
      clear
      echo "${GREEN}Setting up Cloudflare tunnel${NC}"
      chmod -R 777 /var/lib/docker/volumes/cloudflared
      docker run -it --rm -v cloudflared:/home/nonroot/.cloudflared/ cloudflare/cloudflared:latest tunnel login
      docker run -it --rm -v cloudflared:/home/nonroot/.cloudflared/ cloudflare/cloudflared:latest tunnel create $HOSTNAME
      echo -n "${GREEN}Copy the UUID here and hit enter: ${NC}"
      read UUID
      echo -n "${GREEN}Enter the reverse proxy URL: ${NC}"
      read RPURL
      echo -n "${GREEN}Enter the origin server URL: ${NC}"
      read OSURL
      echo "tunnel: $UUID
credentials-file: /home/nonroot/.cloudflared/$UUID.json

ingress:
  - service: $RPURL
    originRequest:
      originServerName: $OSURL" > /var/lib/docker/volumes/cloudflared/_data/config.yml
      docker run -d --name=cloudflared --network=$HOSTNAME -v cloudflared:/home/nonroot/.cloudflared/ cloudflare/cloudflared:latest tunnel run $UUID
      break;;
    [Nn]* )
      echo "${GREEN}Skipping Cloudflare tunnel creation.${NC}"
      break;;
    * ) echo "${GREEN}Please answer with yes or no.${NC}";;
  esac
done

clear
echo "${GREEN}Setting up Cloudflare tunnel${NC}"
chmod -R 777 /var/lib/docker/volumes/cloudflared
docker run -it --rm -v cloudflared:/home/nonroot/.cloudflared/ cloudflare/cloudflared:latest tunnel login
docker run -it --rm -v cloudflared:/home/nonroot/.cloudflared/ cloudflare/cloudflared:latest tunnel create $HOSTNAME
echo -n "${GREEN}Copy the UUID here and hit enter: ${NC}"
read UUID
echo -n "${GREEN}Enter the reverse proxy URL: ${NC}"
read RPURL
echo -n "${GREEN}Enter the origin server URL: ${NC}"
read OSURL
echo "tunnel: $UUID
credentials-file: /home/nonroot/.cloudflared/$UUID.json

ingress:
  - service: $RPURL
    originRequest:
      originServerName: $OSURL" > /var/lib/docker/volumes/cloudflared/_data/config.yml
#nano /var/lib/docker/volumes/cloudflared/_data/config.yml
docker run -d --name=cloudflared -v cloudflared:/home/nonroot/.cloudflared/ cloudflare/cloudflared:latest tunnel run $UUID

clear
echo -n "${GREEN}Copy data from Warthog. Press enter when you're done.${NC}"
read null

clear
echo -n "${GREEN}Press enter to start containers.${NC}"
read null
docker start portainer
docker start npm
docker start organizr
docker start overseerr
docker start tautulli
docker start watchtower

clear
publicip=$(curl ifconfig.io)
echo "Setup should be complete. Your public IP is: ${GREEN}$publicip${NC}"
echo ""
echo "Here are the web UIs for each container:"
echo "Portainer:           ${GREEN}https://$publicip:9443${NC}"
echo "NGINX Proxy Manager: ${GREEN}http://$publicip:81${NC}"
echo "Organizr:            ${GREEN}http://$publicip:3245${NC}"
echo "Overseerr:           ${GREEN}http://$publicip:5055${NC}"
echo "Tautulli:            ${GREEN}http://$publicip:8181${NC}"
echo ""
echo "Add this CNAME to Cloudflare:"
echo "Name: ${GREEN}$HOSTNAME${NC}"
echo "Target: ${GREEN}$UUID.cfargotunnel.com${NC}"
