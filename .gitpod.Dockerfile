FROM gitpod/workspace-full:latest

RUN sudo install-packages php-xdebug

# add binary directory to path.
ENV PATH="/workspace/dev-stock/bin:${PATH}"

# initialize act rc with medium images.
RUN echo "-P ubuntu-latest=catthehacker/ubuntu:act-latest" >> /home/gitpod/.actrc
RUN echo "-P ubuntu-22.04=catthehacker/ubuntu:act-22.04" >> /home/gitpod/.actrc
RUN echo "-P ubuntu-20.04=catthehacker/ubuntu:act-20.04" >> /home/gitpod/.actrc
RUN echo "-P ubuntu-18.04=catthehacker/ubuntu:act-18.04" >> /home/gitpod/.actrc
