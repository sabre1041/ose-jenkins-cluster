#!/bin/bash

master_username=${JENKINS_USERNAME:-"admin"}
master_password=${JENKINS_PASSWORD:-"password"}
slave_executors=${EXECUTORS:-"1"}



# If JENKINS_SECRET and JENKINS_JNLP_URL are present, run JNLP slave
if [ ! -z $JENKINS_SECRET ] && [ ! -z $JENKINS_JNLP_URL ]; then

    echo "Running Jenkins JNLP Slave...."
	JAR=`ls -1 /opt/jenkins-slave/bin/slave.jar | tail -n 1`

	# if -tunnel is not provided try env vars
	if [[ "$@" != *"-tunnel "* ]]; then
		if [[ ! -z "$JENKINS_TUNNEL" ]]; then
			TUNNEL="-tunnel $JENKINS_TUNNEL"
		fi
	fi

	if [[ ! -z "$JENKINS_URL" ]]; then
		URL="-url $JENKINS_URL"
	fi

	exec java $JAVA_OPTS -cp $JAR hudson.remoting.jnlp.Main -headless $TUNNEL $URL -jar-cache $HOME "$@"

elif [[ $# -lt 1 ]] || [[ "$1" == "-"* ]]; then

  echo "Running Jenkins Swarm Plugin...."

  # jenkins swarm slave
  JAR=`ls -1 /opt/jenkins-slave/bin/swarm-client-*.jar | tail -n 1`

  if [[ "$@" != *"-master "* ]] && [ ! -z "$JENKINS_PORT_8080_TCP_ADDR" ]; then
	PARAMS="-master http://${JENKINS_SERVICE_HOST}:${JENKINS_SERVICE_PORT}${JENKINS_CONTEXT_PATH} -tunnel ${JENKINS_SLAVE_SERVICE_HOST}:${JENKINS_SLAVE_SERVICE_PORT}${JENKINS_SLAVE_CONTEXT_PATH} -username ${master_username} -password ${master_password} -executors ${slave_executors}"
  fi

  echo Running java $JAVA_OPTS -jar $JAR -fsroot $HOME $PARAMS "$@"
  exec java $JAVA_OPTS -jar $JAR -fsroot $HOME $PARAMS "$@"

fi