FROM unicon/simplesamlphp
RUN yum update -y
RUN yum install -y \
  php-mysqlnd \
  vim-enhanced

ADD config var/simplesamlphp/config/
ADD metadata var/simplesamlphp/metadata/
ADD cert var/simplesamlphp/cert/
