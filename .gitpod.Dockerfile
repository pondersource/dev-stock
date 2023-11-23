FROM gitpod/workspace-full:latest

RUN sudo install-packages php-xdebug
RUN sudo apt install act
