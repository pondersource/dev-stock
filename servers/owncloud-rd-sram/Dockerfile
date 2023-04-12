FROM owncloud-opencloudmesh
USER www-data
# overwrite the init.sh from owncloud-opencloudmesh:
ADD init.sh /init.sh
RUN cd apps && git clone https://github.com/SURFnet/rd-sram-integration
RUN cd apps && ln -s rd-sram-integration/federatedgroups
USER root
