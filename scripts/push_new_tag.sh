#!/bin/bash


GENERATE_RELEASES_PATH="/home/mauprogramador/Coding/Shell/generate_releases.sh"
REGEX="[0-9]+\.[0-9]+\.[0-9]+"

last_tag=$(git describe --tags --abbrev=0 2>/dev/null)

if [ -z "$last_tag" ]; then
  echo -e "-\033[91m No Tags found ✘\033[m"
else
  echo -e "- Last Tag: \033[92;1m$last_tag\033[m"
fi

echo -ne "- New Tag (vx.x.x): \033[92;1mv"
read new_tag

if [[ ! "$new_tag" =~ $REGEX ]]; then
  echo -e "\033[m-\033[91m Invalid version format ✘\033[m"
  exit 1
fi

origin_url=$(git remote get-url origin 2>/dev/null)

if [[ ! -z "$origin_url" ]]; then
  origin_url="$(echo "$origin_url" | sed "s/\.git$//")/releases/tag/v$new_tag"
fi

echo -ne "\033[35;1m>\033[37;1m Create\033[m a new \033[37;1mTag\033[m and \033[37;1mPush\033[m it to \033[37;1mOrigin\033[m [\033[32my\033[m/\033[31mn\033[m]: "
read answer

if ! [[ "$answer" = "Y" || "$answer" = "y" ]]; then
  echo -e "\033[m-\033[91m Ending here ✘\033[m"
  exit 1
fi

git tag v$new_tag -m "🔖 Release version $new_tag" 2>/dev/null
if [ $? -ne 0 ]; then
  echo -e "\033[m-\033[91m Failed to create Tag ✘\033[m"
  exit 1
fi

git push origin v$new_tag 2>/dev/null
if [ $? -ne 0 ]; then
  echo -e "\033[m-\033[91m Failed to Push to Origin ✘\033[m"
  exit 1
fi

echo -e "-\033[92m Done ✔\033[m"

echo -ne "\033[35;1m>\033[37;1m Generate Release\033[m [\033[32my\033[m/\033[31mn\033[m]: "
read answer

if [[ "$answer" = "Y" || "$answer" = "y" ]]; then
  bash $GENERATE_RELEASES_PATH
fi

echo -e "\033[35;1m>\033[m Please go and check it out at \033[37;1mOrigin\033[m"

if [[ -z "$origin_url" ]]; then
  echo -e "\n"
else
  echo -e "$origin_url\n"
fi
