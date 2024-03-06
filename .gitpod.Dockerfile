FROM gitpod/workspace-full:latest

RUN sudo install-packages php-xdebug

# install act.
RUN sudo mkdir -p /dev-stock/bin/act
RUN wget -qO- https://github.com/nektos/act/releases/download/$(curl -I https://github.com/nektos/act/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}')/act_Linux_x86_64.tar.gz | sudo tar xvz -C /dev-stock/bin/act

# add binary directory to path.
ENV PATH="/dev-stock/bin:${PATH}"

# initialize act rc with medium images.
RUN echo "-P ubuntu-latest=catthehacker/ubuntu:act-latest" >> /home/gitpod/.actrc
RUN echo "-P ubuntu-22.04=catthehacker/ubuntu:act-22.04" >> /home/gitpod/.actrc
RUN echo "-P ubuntu-20.04=catthehacker/ubuntu:act-20.04" >> /home/gitpod/.actrc
RUN echo "-P ubuntu-18.04=catthehacker/ubuntu:act-18.04" >> /home/gitpod/.actrc
