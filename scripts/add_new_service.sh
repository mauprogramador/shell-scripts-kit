#!/bin/bash

PROJECTS_FOLDER="/home/magic-lab-server-01/Projects"
SERVICES_FOLDER="/home/magic-lab-server-01/Services"
SYSTEM_SERVICES_FOLDER="/etc/systemd/system"
SERVICE_STATUS_FILE="status.sh"

echo "- Start New Service"
repository_name=""

# Repository
echo -ne "\033[35;1m>\033[37;1m Clone\033[m \033[37;1mRepository\033[m from \033[37;1mGitHub URL\033[m [\033[32my\033[m/\033[31mn\033[m]: "
read answer

if [[ "$answer" = "y" || "$answer" = "Y" ]]; then
  echo -ne "- \033[37;1mGitHub Repository URL\033[m (https://github.com/user/repo.git): \033[96m"
  read repository_url

  cd "$PROJECTS_FOLDER"
  git clone "$repository_url" 2>/dev/null

  if [ $? -ne 0 ]; then
    echo -e "\033[m-\033[91m Failed clone ✘\033[m"
    exit 1
  fi
  repository_name=$(echo "$repository_url" | sed -E 's/^.*\/([^/]+)(\.git)?$/\1/')
  echo -e "-\033[92m Done ✔\033[m"
fi

if [[ -z "$repository_name" ]]; then
  echo -ne "- \033[37;1mRepository Folder Name\033[m (book-store-back): \033[m"
  read repository_name

  if [[ -z "$repository_name" ]]; then
    echo -e "\033[m-\033[91m Invalid Repository Name ✘\033[m"
    exit 1
  fi
fi

# Service name and description
echo -ne "- \033[37;1mService Name\033[m (book-store-back): \033[m"
read service_name

echo -ne "- \033[37;1mService Description\033[m (Book Store Backend): \033[m"
read service_description

if [[ -z "$service_name" || -z "$service_description" ]]; then
  echo -e "\033[m-\033[91m Invalid Service Name or Description ✘\033[m"
  exit 1
else

# Service config file
service_file="$service_name.service"
cd "$SYSTEM_SERVICES_FOLDER"

sudo touch "$service_file"
sudo chmod 664 "$service_file"

service_config="
[Unit]
Description=$service_description
After=network.target
# For Docker:
# After=docker.service
# Requires=docker.service

[Service]
Type=simple
User=magic-lab-server-01
WorkingDirectory=$PROJECTS_FOLDER/$service_name
ExecStart=$PROJECTS_FOLDER/$repository_name/.venv/bin/uvicorn 'app:app'
ExecStop=...
# For Docker:
# ExecStartPre=/usr/bin/docker pull image:tag
# ExecStart=/usr/bin/docker run ...
# ExecStop=/usr/bin/docker stop container_name
# For Docker Compose:
# ExecStart=/bin/bash -c 'cd $PROJECTS_FOLDER/$repository_name && docker compose up'
# ExecStop=/bin/bash -c 'cd $PROJECTS_FOLDER/$repository_name && docker compose down'
Environment=VARIABLE=value
EnvironmentFile=$PROJECTS_FOLDER/$repository_name/.env
Restart=always
StandardOutput=file:$SERVICES_FOLDER/$service_name/records.log
StandardError=file:$SERVICES_FOLDER/$service_name/errors.log

[Install]
WantedBy=multi-user.target
"

echo $service_config > "$service_file"
echo -e "Base \033[93m$service_file \033[92mgenerated ✔\033[m"

echo -e "\033[33mPlease edit the content\033[m"
sudo gedit "$service_file"
echo -e "-\033[92m Done ✔\033[m"

# Start service
sudo systemclt daemon-reload 2>/dev/null
sudo systemclt enable "$service_file" 2>/dev/null
sudo systemclt start "$service_file" 2>/dev/null

if [ $? -ne 0 ]; then
  echo -e "\033[m-\033[91m Service start failed ✘\033[m"
  exit 1
else
  echo -e "-\033[92m Service $service_name running ✔\033[m"
fi

# Create Symbolic link file
mkdir "$SERVICES_FOLDER/$service_name"
ln -s "$SYSTEM_SERVICES_FOLDER/$service_file" "$SERVICES_FOLDER/$service_name/$service_file"
echo -e "-\033[92m Symbolic link to config file created ✔\033[m"

# Create service status file
cd "$SERVICES_FOLDER/$service_name"
touch $SERVICE_STATUS_FILE
chmod 777 $SERVICE_STATUS_FILE
echo -e "-\033[92m Service status file created ✔\033[m"

echo "#!/bin/bash" >> $SERVICE_STATUS_FILE
echo -e "\n" >> $SERVICE_STATUS_FILE
echo "gnome-terminal --tab --title='$service_name' --command='bash -c "systemctl status $service_file"'" >> $SERVICE_STATUS_FILE






# When updating xxx.service, always reload:
- Reload Daemon:   sudo systemclt daemon-reload
- Restart:         sudo systemclt restart xxx.service

# Disable and stop:
- Disable:        sudo systemclt disable xxx.service
- Stop:           sudo systemclt stop xxx.service
