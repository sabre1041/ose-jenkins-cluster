Jenkins Cluster for OpenShift
===============

This repository contains the resources necessary to provision a Jenkins master (Based on the official Red Hat OpenShift Docker image) and run jobs on a dynamic set of slaves using the [Jenkins Swarm plugin](https://wiki.jenkins-ci.org/display/JENKINS/Swarm+Plugin) within OpenShift. 

## Components

* Jenkins Master
	* Extension of the Red Hat OpenShift Docker image to include plugins and configurations to support dynamic auto discovery of Jenkins slaves
* Jenkins Slave
	* Container running the Jenkins Swarm client (Based on the work from [csanchez/jenkins-slave/](https://hub.docker.com/r/csanchez/jenkins-slave/))
* Templates
	* The [jenkins-cluster-ephemeral](jenkins-cluster-ephemeral-template.json) and [jenkins-cluster-persistent](jenkins-cluster-persistent-template.json) OpenShift templates are available for rapidly building and provisioning a Jenkins master and slave pods. 

	
## Create a Jenkins Environment

The following steps describe how to configure and provision a master and slave using one of the provided templates within OpenShift.

1. Clone the repository locally
2. Create a new project or use an existing project to contain the resources
3. Add the templates to the OpenShift project 

```
oc create -f jenkins-cluster-persistent-template.json,jenkins-cluster-ephemeral-template.json
``` 

4. Instantiate the template

```
oc new-app --template=jenkins-cluster-ephemeral
```

By default, this will create a new application containing a master and slave and expose a route for the Jenkins UI at `jenkins.<project>.<default-domain-suffix>`. A new build of both Docker images will begin and once complete, containers will be deployed.

By default, the following credentials can be used to log into the Jenkins UI

```
Username: admin
Password: password
```

The slaves which are connected can be seen under the *Build Executor Status* section on the left side of the page. Additional slaves can be created by scaling the slave

```
oc scale dc jenkins-slave --replicas=2
```