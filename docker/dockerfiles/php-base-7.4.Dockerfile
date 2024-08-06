FROM php:7.4.33-zts-alpine3.16

# Setup apache and php
RUN apk --no-cache --update add                         \
	git                                                 \
    curl                                                \    
    apache2                                             \
    apache2-ssl

