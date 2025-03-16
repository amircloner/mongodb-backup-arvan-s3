FROM mongo:8

RUN rm /etc/apt/sources.list.d/mongodb-org.list
RUN apt-get update && apt-get -y install cron s3cmd
RUN apt-get install dos2unix

ENV CRON_TIME="0 3 * * *" \
  TZ=Asia/Tehran \
  CRON_TZ=Asia/Tehran

ADD run.sh ./run.sh
RUN chmod +x ./run.sh
RUN dos2unix ./run.sh
CMD ["/bin/bash", "-c", "source ./run.sh"]
