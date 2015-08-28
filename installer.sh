#!/bin/bash

# ARCH: x32_64

# Project Fedena Auto Installation Script
# ========================================
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# echo -e "\E[1;40m" && clear;
clear;

if [ $UID -ne 0 ]; then
		printf "\nInstallation halted!\nYou must launch this installer with elevated privileges\nPrepend the installation command with 'sudo' and try again.\n\n"
    exit 1
fi

SO="Supported Operating System & Version Detected"
PR="Proceeding with Installation";

sleep 1; echo -e "Project Fedena 2.3 CE Auto-installer"
sleep 2; echo "Source: https://n3rve.com"; sleep 3;

sleep 1; echo -e "\nDetecting OS";
echo -ne '#####                     (33%)\r'
sleep 1
echo -ne '#############             (66%)\r'
sleep 1
echo -ne '#######################   (100%)\r'
echo -ne '\n'

BITS=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
if [ -f /etc/lsb-release ]; then
  OS=$(cat /etc/lsb-release | grep DISTRIB_ID | sed 's/^.*=//')
  VER=$(cat /etc/lsb-release | grep DISTRIB_RELEASE | sed 's/^.*=//')
else
  OS=$(uname -s)
  VER=$(uname -r)
fi
echo "Detected : $OS  $VER - $BITS bit architecture"; sleep 1;
if [ "$OS" = "Ubuntu" ] && [ "$VER" = "12.04" ]; then
  echo -e "$SO" && sleep 4 && echo -e "$PR";
  
elif [ "$OS" = "Ubuntu" ] && [ "$VER" = "14.04" ]; then
  echo -e "$SO" && sleep 4 && echo -e "$PR"; 

elif [ "$OS" = "Ubuntu" ] && [ "$VER" = "15.04" ]; then
  echo -e "$SO" && sleep 4 && echo -e "$PR\n";
  
else
  sleep 3;
  echo -e "Error: Unsupported operating system detected.\n";
  sleep 1;
  exit 1;
fi

sleep 4;

echo -e ""
echo -e "##############################################################"
echo -e "# Welcome to the Fedena 2.3 Auto Installer for Ubuntu        #"
echo -e "#							     #"
echo -e "# Please make sure your VPS provider hasn't pre-installed    #"
echo -e "# any Ruby or MySQL packages.                                #"
echo -e "#                                                            #"
echo -e "# If you are installing on a physical machine where the OS   #"
echo -e "# has been installed by yourself please make sure you only   #"
echo -e "# installed Ubuntu (Server) with no extra packages.          #"
echo -e "#                                                            #"
echo -e "# If you selected additional options during the Ubuntu       #"
echo -e "# install please consider reinstalling without them.         #"
echo -e "#                                                            #"
echo -e "# For support, e-mail: n3rve@n3rve.com                       #"
echo -e "#                                                            #"
echo -e "##############################################################"
echo -e ""

sleep 20

# Upgrade Ubuntu
apt-get update && apt-get upgrade -y

# Install Dependencies
apt-get install -y gawk g++ gcc make libc6-dev libreadline6-dev zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 autoconf libgdbm-dev libncurses5-dev automake libtool bison pkg-config libffi-dev unzip git

apt-get install -y gcc-4.4 g++-4.4


# Install Ruby 1.8
cd /tmp && wget http://cache.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p374.tar.gz
tar -xzvf ruby-1.8.7-p374.tar.gz
cd ruby-1.8.7-p374
./configure
make CC=gcc-4.4
make install 

# Install Rubygems 1.3.7 
cd /tmp && wget http://production.cf.rubygems.org/rubygems/rubygems-1.3.7.tgz
tar -xzvf rubygems-1.3.7.tgz
cd rubygems-1.3.7
ruby setup.rb

cd $home
# Install MySQL Server / Adapter
echo "Installing the MySQL server ..."
sleep 2
export DEBIAN_FRONTEND=noninteractive
apt-get -q -y install  mysql-server mysql-client libmysqlclient-dev
sleep 3
mysqladmin -u root password foradian
echo "MySQL password set as 'foradian'"
sleep 2

echo "Updating GEMs:"
gem install rails -v=2.3.5 --no-ri --no-rdoc
gem uninstall rake -Iax
gem install rake -v=0.8.7 --no-ri --no-rdoc
gem install mysql --no-ri --no-rdoc
gem install i18n -v 0.4.2 --no-ri --no-rdoc
gem install rush -v 0.6.8 --no-ri --no-rdoc
gem install mongrel -v=1.1.5 --no-ri --no-rdoc

echo "Downloading Source Code"
sleep 2
git clone https://github.com/projectfedena/fedena.git
sleep 3 && cd fedena && sleep 1
rake gems:install

echo "Creating Database & migrating schemas"
rake db:create && sleep 1;
rake db:migrate && rake fedena:plugins:install_all
sleep 2 && chmod +x *

fuser -k 80/tcp
mongrel_rails start -e production -p 80 -d

function ProgressBar {
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

# 1.2.1.1 Progress : [########################################] 100%
printf "\rStarting Fedena : [${_fill// /#}${_empty// /-}] ${_progress}%%"

}

_start=1

_end=100

for number in $(seq ${_start} ${_end})
do
    sleep 0.1
    ProgressBar ${number} ${_end}
done

PUBLIC_IP=$(curl ident.me)
echo -e "\nInstallation completed. Visit http://$PUBLIC_IP"
sleep 2;
echo "Login with -- u: admin & p: admin123."
sleep 2;
echo -e "Considering Fedena Pro? Send a mail: n3rve@n3rve.com"

