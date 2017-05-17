FROM docker-hdp/centos-base:1.0
MAINTAINER Arturo Bayo <arturo.bayo@gmail.com>
USER root

ENV HADOOP_CONF_DIR /etc/hadoop/conf

# Configure environment variables for hdfs
ENV DFS_NAME_DIR /grid/hadoop/hdfs/nn
ENV FS_CHECKPOINT_DIR /grid/hadoop/hdfs/snn
ENV DFS_DATA_DIR /grid/hadoop/hdfs/dn
ENV HDFS_USER hdfs
ENV HDFS_LOG_DIR /var/log/hadoop/$HDFS_USER
ENV HDFS_PID_DIR /var/run/hadoop/$HDFS_USER

# Configure environment variables for yarn
ENV YARN_LOCAL_DIR /grid/hadoop/yarn/local
ENV YARN_USER yarn
ENV MAPRED_USER mapred
ENV YARN_LOG_DIR /var/log/hadoop/$YARN_USER
ENV YARN_PID_DIR /var/run/hadoop/$YARN_USER
ENV MAPRED_LOG_DIR /var/log/hadoop/$MAPRED_USER
ENV MAPRED_PID_DIR /var/run/hadoop/$MAPRED_USER

# Install software
RUN yum clean all
RUN yum -y install hadoop hadoop-hdfs hadoop-libhdfs hadoop-yarn hadoop-mapreduce hadoop-client openssl

# Install compression libraries
RUN yum -y install snappy snappy-devel lzo lzo-devel hadooplzo hadooplzo-native

# Configure hadoop directories

# Namenode
RUN mkdir -p $DFS_NAME_DIR && chown -R $HDFS_USER:$HADOOP_GROUP $DFS_NAME_DIR && chmod -R 755 $DFS_NAME_DIR

# Secondary namenode
RUN mkdir -p $FS_CHECKPOINT_DIR && chown -R $HDFS_USER:$HADOOP_GROUP $FS_CHECKPOINT_DIR && chmod -R 755 $FS_CHECKPOINT_DIR

# HDFS Logs
RUN mkdir -p $HDFS_LOG_DIR && chown -R $HDFS_USER:$HADOOP_GROUP $HDFS_LOG_DIR && chmod -R 755 $HDFS_LOG_DIR

# HDFS Process
RUN mkdir -p $HDFS_PID_DIR && chown -R $HDFS_USER:$HADOOP_GROUP $HDFS_PID_DIR && chmod -R 755 $HDFS_PID_DIR

# YARN Logs
RUN mkdir -p $YARN_LOG_DIR && chown -R $YARN_USER:$HADOOP_GROUP $YARN_LOG_DIR && chmod -R 755 $YARN_LOG_DIR

# YARN Process
RUN mkdir -p $YARN_PID_DIR && chown -R $YARN_USER:$HADOOP_GROUP $YARN_PID_DIR && chmod -R 755 $YARN_PID_DIR

# JobHistoryServer Logs
RUN mkdir -p $MAPRED_LOG_DIR && chown -R $MAPRED_USER:$HADOOP_GROUP $MAPRED_LOG_DIR && chmod -R 755 $MAPRED_LOG_DIR

# JobHistoryServer Process
RUN mkdir -p $MAPRED_PID_DIR && chown -R $MAPRED_USER:$HADOOP_GROUP $MAPRED_PID_DIR && chmod -R 755 $MAPRED_PID_DIR

# Symlinks directories to hdp-current and modifies paths for configuration directories running hdp-select
RUN hdp-select set all $HDP_VERSION

# Copy configuration files
RUN mkdir -p $HADOOP_CONF_DIR
COPY tmp/conf/ $HADOOP_CONF_DIR/
RUN chown -R $HDFS_USER:$HADOOP_GROUP $HADOOP_CONF_DIR/../ && chmod -R 755 $HADOOP_CONF_DIR/../

RUN echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile
RUN echo "export HADOOP_CONF_DIR=$HADOOP_CONF_DIR" >> /etc/profile
RUN echo "export PATH=$PATH:$JAVA_HOME:$HADOOP_CONF_DIR" >> /etc/profile

# Expose volumes
VOLUME $HDFS_LOG_DIR
VOLUME $YARN_LOG_DIR
VOLUME $MAPRED_LOG_DIR

# Expose ports
EXPOSE 9000
EXPOSE 14000
EXPOSE 50070
# Secondary
EXPOSE 50090

# Deploy entrypoint
COPY files/configure-namenode.sh /opt/run/00_hadoop-namenode.sh
COPY files/configure-resourcemanager.sh /opt/run/01_hadoop-resourcemanager.sh
COPY files/configure-secondarynamenode.sh /opt/run/02_hadoop-secondarynamenode.sh
RUN chmod +x /opt/run/*.sh

# Determine running user
#USER $ZOO_USER

# Execute entrypoint
ENTRYPOINT ["/opt/bin/run_all.sh"]

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=5 \
  CMD curl -f http://localhost:50070/ || exit 1