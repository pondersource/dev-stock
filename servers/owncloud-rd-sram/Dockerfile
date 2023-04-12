FROM owncloud-opencloudmesh
USER www-data
RUN cd apps && git clone https://github.com/SURFnet/rd-sram-integration
RUN cd apps && ln -s rd-sram-integration/federatedgroups
USER root
