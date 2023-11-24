FROM gitpod/workspace-full:latest

RUN sudo install-packages php-xdebug

ENV PATH="/workspace/dev-stock/bin:${PATH}"
