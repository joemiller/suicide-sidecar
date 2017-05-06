FROM quay.io/getpantheon/gcloud-kubectl:master

RUN apt-get update -q \
  && apt-get install -qy \
    inotify-tools \
  && apt-get -y autoremove \
  && apt-get -y clean \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/*

COPY ./run.sh /run.sh
RUN chmod 755 /run.sh

ENTRYPOINT ["/run.sh"]
