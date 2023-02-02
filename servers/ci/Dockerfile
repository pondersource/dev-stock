FROM node
# From https://github.com/zenato/docker-puppeteer/blob/master/Dockerfile
RUN apt-get update \
    && apt-get install -y wget gnupg \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 libxshmfence1 libglu1 \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*
# Trust all the certificates:
ADD tls /tls
RUN cp /tls/*.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates
RUN git clone https://github.com/cs3org/ocm-test-suite
WORKDIR /ocm-test-suite
RUN git checkout main
RUN npm ci
ARG CACHE_BUST
RUN git pull
CMD HEADLESS=1 npm run debug
