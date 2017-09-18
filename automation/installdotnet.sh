#!/bin/bash

# from https://www.microsoft.com/net/core#linuxcentos

# this line produce an error, so commenting out
#sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[packages-microsoft-com-prod]\nname=packages-microsoft-com-prod \nbaseurl=https://packages.microsoft.com/yumrepos/microsoft-rhel7.3-prod\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/dotnetdev.repo' 

# TODO : comment out the following line if you want to update your system
#sudo yum -y update
sudo yum -y install libunwind libicu
sudo yum -y install dotnet-sdk-2.0.0
