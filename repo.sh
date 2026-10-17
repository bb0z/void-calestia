sudo xbps-install -S void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree

sleep(1)


sudo cp /usr/share/xbps.d/00-repository-main.conf /etc/xbps.d/
sudo sed -i "1i repository=https://mirror.black-hole.dev/x86_64" /etc/xbps.d/00-repository-main.conf

