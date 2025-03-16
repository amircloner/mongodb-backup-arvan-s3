FROM mongo:8

# Remove obsolete MongoDB source list and update package lists
RUN rm /etc/apt/sources.list.d/mongodb-org.list && \
    apt-get update && \
    apt-get -y install cron s3cmd dos2unix && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV CRON_TIME="0 3 * * *" \
    TZ=Asia/Tehran \
    CRON_TZ=Asia/Tehran

# Add and prepare the run script
ADD run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh && \
    dos2unix /usr/local/bin/run.sh

# Set the entrypoint to the run script
CMD ["/bin/bash", "-c", "/usr/local/bin/run.sh"]
