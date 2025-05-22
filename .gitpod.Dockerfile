FROM gitpod/workspace-full:latest

RUN sudo install-packages php-xdebug

# install act.

RUN wget -qO- https://github.com/nektos/act/releases/download/$(curl -I https://github.com/nektos/act/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}')/act_Linux_x86_64.tar.gz | sudo tar xvz -C /dev-stock/bin/act && sudo cp /dev-stock/bin/act/act /usr/local/bin/act
RUN wget -qO- https://github.com/mikefarah/yq/releases/download/$(curl -I https://github.com/mikefarah/yq/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}')/yq_linux_amd64.tar.gz -O - | tar xz && sudo mv yq_linux_amd64 /usr/local/bin/yq

# initialize act rc with medium images.
RUN echo "-P ubuntu-latest=catthehacker/ubuntu:act-latest" >> /home/gitpod/.actrc
RUN echo "-P ubuntu-24.04=catthehacker/ubuntu:act-24.04" >> /home/gitpod/.actrc
RUN echo "-P ubuntu-22.04=catthehacker/ubuntu:act-22.04" >> /home/gitpod/.actrc
