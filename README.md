Jenkins Cluster for OpenShift
===============

This repository contains the resources necessary to provision a Jenkins master (Based on the official Red Hat OpenShift Docker image) and run jobs on a dynamic set of slaves using the [Jenkins Swarm plugin](https://wiki.jenkins-ci.org/display/JENKINS/Swarm+Plugin) or to dynamically provision slaves using the [Kubernetes plugin](https://wiki.jenkins-ci.org/display/JENKINS/Kubernetes+Plugin) within OpenShift. 

## Components

* Jenkins Master
	* Extension of the Red Hat OpenShift Docker image to include plugins and configurations to support auto discovery and dynamic provisioning of Jenkins slaves
* Jenkins Slave
	* Container running either the Jenkins Swarm client (Based on the work from [csanchez/jenkins-slave/](https://hub.docker.com/r/csanchez/jenkins-slave/) when auto discovering slaves) or the [jnlp agent](https://wiki.jenkins-ci.org/display/JENKINS/Distributed+builds) when dynamically provisioning slave instances 
* Templates
	* The [jenkins-cluster-ephemeral](jenkins-cluster-ephemeral-template.json) and [jenkins-cluster-persistent](jenkins-cluster-persistent-template.json) OpenShift templates are available for rapidly building and provisioning a Jenkins master and slave pods. 

	
## Setting up the Jenkins Environment

The following steps describe how to create a project within OpenShift and add the templates using the OpenShift client tool *oc* which will be used to provision a Jenkins master and slave instances. 

1. Clone the repository locally
2. Create a new project or use an existing project that will contain the Jenkins master and slaves
.
```
oc new-project jenkins
```

3. Add the templates from the *support* folder to the OpenShift project that provide 
.
```
oc create -f support/jenkins-cluster-persistent-template.json,support/jenkins-cluster-ephemeral-template.json
``` 


## Provisioning the Jenkins Master and Slaves

The templates added to OpenShift in the previous section provide the OpenShift components necessary to build and deploy Docker images containing the Jenkins master and slaves. Both the *jenkins-cluster-persistent-template.json* and *jenkins-cluster-ephemeral-template.json* templates provision both the master and slave Jenkins instances. The *jenkins-cluster-persistent-template.json* allows for a [PersistentVolume](https://docs.openshift.com/enterprise/3.1/dev_guide/persistent_volumes.html) to be used to save the state of the Jenkins to disk. The using the *jenkins-cluster-ephemeral-template.json* template, once the [pod](https://docs.openshift.com/enterprise/3.1/architecture/core_concepts/pods_and_services.html) dies, all configuration will be lost. 

Each template contains several parameters that can be modified to modify and tailor the instances to the particular environment. The table below details the parameters available in the templates

|Name|Description|Default Value|
|--------|---------------|------------------|
|APPLICATION_NAME|Name of the application. The slave will be suffixed with *-slave*|jenkins|
|APPLICATION_HOSTNAME|Hostname to access Jenkins|&lt;application-name&gt;.&lt;project&gt;.&lt;default-domain-suffix&gt;|
|password|Password securing the admin account of Jenkins|password|
|JENKINS_SERVICE_ACCOUNT|OpenShift service account injected into the Jenkins master|default|
|GIT_URI|Url of this Git repository|https://github.com/sabre1041/ose-jenkins-cluster.git|
|GIT_REF|Git Branch|master|
|EXECUTORS|Number of executors for each Jenkins Swarm slave|1|
|SLAVE_RECCURENCE_PERIOD|Interval of time to check whether to provision additional slave nodes|500|
|VOLUME_CAPACITY|Available in the *jenkins-cluster-persistent-template.json* template. The amount space to allocate for data|512MB|

### Configuring the OpenShift Project

One of the methods running Jenkins jobs in this project is to dynamically provision slave instances in OpenShift using the Kubernetes plugin. Jenkins communicates with OpenShift using a secured value stored as [Credentials](https://wiki.jenkins-ci.org/display/JENKINS/Credentials+Plugin). By default, the Jenkins instance is configured to leverage the API token from a service account that is injected into pods by default. The default service account for a pod does not have the adequate permissions necessary to fully provision a slave instance. 

Add the **edit** role to the default service account

     oc policy add-role-to-user edit system:serviceaccount:jenkins:default

Alternatively, you can choose to utilize a separate service account to run the Jenkins master. The *support* folder contains a service account called **jenkins** that can be added to the project. To instantiate the service account, execute the following command from within the support folder:

    oc create -f jenkins.json
   
The jenkins service account will be created. Now add the *edit* role to this account as shown previously for the default service account:

     oc policy add-role-to-user edit system:serviceaccount:jenkins:jenkins

Subsequent sections will illustrate how to leverage this account


### Instantiate the template

Using either the OpenShift web console or the *oc* tool, instantiate one of the provided templates. An array of parameters can be specified using the `--param=` option

```
oc new-app --template=jenkins-cluster-ephemeral
```

By default, this will create a new application containing a master,  swarm based slave and expose a route for the Jenkins UI at `jenkins.<project>.<default-domain-suffix>`. A new build of both Docker images will begin and once complete, containers will be deployed. This can be confirmed in the Jenkins web console be not

By default, the following credentials can be used to log into the Jenkins UI

```
Username: admin
Password: password
```

The slaves which are connected can be seen under the *Build Executor Status* section on the left side of the page. Additional slaves can be created by scaling the slave (2 replicas for example)

```
oc scale dc jenkins-slave --replicas=2
```

### Configuring dynamic slave provisioning

The Jenkins master and slave docker images contain the majority of the functionality preconfigured. When leveraging dynamic slave provisioning using the Kubernetes plugin, there are several values that must either be manually configured or confirmed. 

#### Configuring the Kubernetes Plugin

Settings for the Kubernetes plugin can be configured in the Jenkins global system configuration by logging into the Jenkins master and selecting **Manage Jenkins** on the left side and then selecting **Configure System**.

Under the *Cloud* section is a section for **Kubernetes**. A base configuration has been provided with the majority of the configuration necessary to dynamically provision slaves. Addressing to OpenShift components leverages the built in [SkyDNS](https://docs.openshift.com/enterprise/3.1/architecture/additional_concepts/networking.html#openshift-dns) functionality. The Kubernetes plugin communicates with the OpenShift api at *https://openshift.default.svc.cluster.local* using the service account injected into the pod. When using this credential, the additional prerequisite steps described above must have been completed to give the service account the requisite permissions. Alternatively, a user name and password based credential can be used instead of a service account. 

Next, verify the name the Kubernetes namespace (OpenShift project) is correct. *jenkins* is used by default. Then validate and modify as necessary the Jenkins URL and Jenkins tunnel addresses. These addresses map to the two services that have been defined for the project (jenkins pointing at port 8080 for API and 50000 for slave connections) These URL's take the following form:

    <app_name>.<namespace>.svc.cluster.local:<port>
    
When the Kubernetes plugin attempts to allocate a new slave dynamically, it will leverage a docker image that was built when the template was instantiated. Since the image is stored in the OpenShift integrated repository, the image name is specific to each OpenShift cluster which is configured in the **Docker image** textbook underneath the *Kubernetes Pod Template* section. The value from the Jenkins slave [ImageStream] can be used and can be found by navigating to the ImageStream's after highlighting the *Browse* button:


Or by executing the following command using the OpenShit cli

    oc get is jenkins-slave --no-headers | awk '{ print $2 }'
    
Hit **Save** to apply the changes


