FROM registry.access.redhat.com/openshift3/jenkins-1-rhel7

# Install additional plugins and modify files
RUN mkdir -p /opt/openshift/plugins && \
          curl -sSL -f https://updates.jenkins-ci.org/download/plugins/swarm/2.0/swarm.hpi \
	      -o /opt/openshift/plugins/swarm.jpi && \
		  sed -i "s|<slaveAgentPort>.*</slaveAgentPort>|<slaveAgentPort>50000</slaveAgentPort>|" "/opt/openshift/configuration/config.xml" && \
		  sed -i "s|<numExecutors>.*</numExecutors>|<numExecutors>0</numExecutors>|" "/opt/openshift/configuration/config.xml" && \
		  chmod -R og+rw /opt/openshift/plugins 