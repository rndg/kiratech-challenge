# Kiratech challenge

## 1. Project description
This project aims to provision, configure and deploy a self-managed Kubernetes cluster (a master node and 2 workers node) 
and the underlying architecture.
The cluster must be configured to run a security benchmark and an application accessible from the browser composed by 3 services must be deployed in a specific namespace.

The software technologies used in this project are Ansible, Terraform and Helm, while the VMs are provisioned on AWS.

The next part of this section contains a description of the technologies used and the implementation details. 

### Virtual machines:
The virtual machines used are EC2 instances of AWS.
The decision of a cloud provider was based on the its easy and fast configuration, the low cost and my personal previous experionce.
The instances used are type t3.medium [1], running Ubuntu 22.04 and located in the Frankfurt region (eu-central-1).
These machines have been chosen because they are compliant with the minimum requisites in terms of OS, CPU and RAM of 
Kubernetes, as specified in [2].
The VM chosen to be the master node has been placed in a network security group called sg-kube-master, while the other 2 nodes 
have been placed in a network security group called sg-kube-worker.
The security groups are configured for allowing only the mandatory inbound traffic for 
Kubernetes, the CNI and the ssh port used for development while all the outbound traffic is allowed.
In the subsequent tables are listed the security groups inbound policies. 

sg-kube-master
![Alt text](./images/sg-kube-master.png?raw=true "Title")

sg-kube-worker
![Alt text](./images/sg-kube-worker.png?raw=true "Title")

Moreover, a key pair called "kiratech-challenge" for ssh connection has been created and it has been downloaded locally as "kiratech-challenge.pem".
### Ansible:
In this project Ansible is used to automatically provision the VMs on AWS, configure them installing all the necessary packages, configure the master and the worker nodes.
All these steps are performed by a specific Ansible role created with the `ansible-galaxy` command.
The ansible roles are:
- init-ec2: this role is used to create all the VMs on AWS and add their public IP addresses to the Ansible inventory.
- ec2-config: this role is used to configure all the VMs installing the necessary packages (Docker and Kubernetes) and configure the cgroupdriver and iptables.
- cluster-config-master: this role is used to initialize the cluster on the master node with the `kubeadm init` command, create and save locally the join command with the `kubeadm token create` command and install Weave [3], the Container Network Interface.
- cluster-config-worker: this role is used to join to the cluster the worker nodes with the previously locally saved join command.
These roles are executed sequentially by running the setup-cluster playbook.

### Terraform:
In this project Terraform is used to create a namespace called "kiratech-test" in the previously created cluster and to run the CIS Kubernetes benchmark [4] on each node accordingly to their role in the cluster.
The CIS benchmark has been chosen because it has been identified as a global standard during my research on the topic.  
The tool used for perform the benchmark is kube-bench [5], and it has been chosen for its popularity, easy of use and, most importantly, its clearness of output which details and the reasons of the result of each rule tested.

### Helm:
In this project Helm is used deploy Jenkins [6], a CI/CD tool used to automate pipelines, in the "kiratech-test" namespace. 
The deployed application is composed by 3 services: PersistentVolume, ServiceAccount and Service. 
The PersistentVolume is used to persist data in the volume even if the application needs to be restarted or fails, 
the ServiceAccount (with the related ClusterRole and RoleBinding) is used to access the Kubernetes apiserver with a specific account in the namespace "kiratech-test", 
the Service is a LoadBalancer which manages the cluster network and exposes the frontend to a browser accessible address.

### Further improvements:
- In the Ansible part there is a heavy use of the builtin shell module [7] which should be adapted to more suitable builtin modules (such as apt module, file module) or community modules (e.g. k8s module [8]).
- The master and worker nodes joining part should be implemented in Terraform as specified in the challenge instructions, while in this version this part is performed in Ansible. 
The code is ready but commented out in the Terraform directory but due to an infinite loop in the resources provisioning when installing the nodes as master or workers, it couldn't be tested.
- Set the AWS credentials as environment variables.
- Set EC2 instances specifications as vars in the inventory file.
- Add PersistentVolume ans ServiceAccount as Terraform managed resources with the Kubernetes provider used for the namespace creation. 
- Add Helm deployment as part of Terraform to introduce a higher layer of abstraction to Jenkins.

## 2. Repo structure
In this section are listed the main components of this repository, pointing the noteworthy files for each component.

```
kiratech-challenge
 ┃
 ┣ ansible-challenge            #directory of Ansible part
 ┃ ┣ inventories                 
 ┃ ┃ ┗ inventory.yaml           #Ansible inventory
 ┃ ┣ roles
 ┃ ┃ ┣ cluster-config-master    #Ansible role for master node configuration
 ┃ ┃ ┣ cluster-config-worker    #Ansible role for worker nodes configuration
 ┃ ┃ ┣ ec2-config               #Ansible role for EC2 instances configuration
 ┃ ┃ ┗ init-ec2                 #Ansible role for EC2 instance provisioning
 ┃ ┗ setup-cluster.yaml         #Ansible playbook for cluster creation
 ┃
 ┣ helm-challenge               #directory of Helm part
 ┃ ┗ Jenkins
 ┃   ┣ serviceAccount.yaml      #K8s ClusterRole, ServiceAccoint, ClusterRoleBinding 
 ┃   ┣ values.yaml              #Helm values file for custom deployment
 ┃   ┗ volume.yaml              #K8s PersistentVolume, PersistentVolumeClaim
 ┃
 ┣ terraform-challenge          #directory of Terraform part
 ┃ ┣ main.tf                    #Terraform file for declaring resources
 ┃ ┗ terraform.tfstate          #Terraform file for provisioned resources states
 ┗ README.md                    #this file
```

## 3. Install and run the project

### Requirements
- A working AWS account with an IAM role configured for programmatic access, the security groups for master and workers configured as mentioned in the previous section and a key pair for ssh connection called "kiratech-challenge".
- A python 3 interpreter configured in the local machine, I used python 3.8 version.
- Kubectl, Ansible, Helm and Terraform installed on the local machine.
- This repository cloned to your local machine.
- A virtual environment to install the necessary python packages (e.g. Ansible and Boto3) in a controlled environment (optional)

### Starting Ansible 
The first thing to do is navigate with the terminal inside the directory:
`path/to/repo/kiratech-challenge/ansible-challenge` \
Edit the file `inventories/inventory.yaml` replacing the variables with the path to your local python interpreter, the path of your ssh key, the aws access key and the aws secret key.
Now, just run these commands to play the ansible playbook "setup-cluster"
```
export ANSIBLE_HOST_KEY_CHECKING=False #used for ignore ssh authenticity check
ansible-playbook -i inventories/inventory.yaml setup-cluster.yaml
```
After the completion of all the steps, you can check the successful creation of your EC2 instances in the AWS console.
To access the newly created cluster from your local machine run
```
scp -i path/to/your/kiratech-challenge.pem ubuntu@<your:master:node:public:DNS:address>:/home/ubuntu/.kube/config ~/.kube/config
```
This command copies with ssh the admin config file of the cluster to your local machine and add it to your local config file, this permits you to run kubectl commands with the context of your cluster.

### Terraform
The first thing to do is navigate with the terminal inside the directory:
`path/to/repo/kiratech-challenge/terraform-challenge` \
Edit the file `main.tf` with your aws access key and aws secret key in the provider "aws" scope.
Then, run 
```
terraform init
```
to download the necessary providers, in this case "aws" and "kubernetes". \
Now, the existing EC2 instances must be imported in Terraform in order to specify to not create new resources but manage the existing one.
To do so, run:
```
terraform import aws_instance.master <id-instance of your master node>
terraform import aws_instance.worker1 <id-instance of your worker1 node>
terraform import aws_instance.worker2 <id-instance of your worker2 node>
```
note that the id-instance of your nodes can be found in your AWS console in the EC2 instance interface.
Once the nodes have been imported, you can note if any change in your configuration would be fired by Terraform inspecting the output of the command 
```
terraform plan
``` 
In particular, you have to focus on the parameters of the instances (e.g. AMI, instance type or name) and verify that the existing aws_instance resources results as "changed" and not "destroy" and subsequently "added".
Finally, you can run the Terraform command 
```
terraform apply
``` 
which ensures the necessary resources are present and if not, Terraform take care of the provisioning in the desired state. 
During this process, you will be prompt to authorize the operation typing "yes" in the terminal. \
One important aspect of the output of this process will be the validation tasks of kube-bench. 
In particular, you will see a set of instruction tagged as FAIL, WARNING or PASS which are the results of the rules pointed by the CIS Kubernetes benchmark.
One example of the output could be found here [5] in the very top level of the README, while the results of the benchmark on the master node can be found in the following image.

![Alt text](./images/kube-bench-results.png?raw=true "Title")

### Helm
The first thing to do is navigate with the terminal inside the directory:
`path/to/repo/kiratech-challenge/helm-challenge/Jenkins` \
Then, the base Jenkins official chart must be downloaded 
```
helm repo add jenkins https://charts.jenkins.io
helm repo update
```
Our objective is to deploy the official chart with modified deployement options contained in the values.yaml file. \
Before proceeding to the helm chart installation, the PersistentVolume and the ServiceAccout must be created on the cluster as specified in the official Jenkins documentation [9]. To do so, the relative files must be applied to the cluster with
```
kubectl apply -f volume.yaml -n kiratech-test
kubectl apply -f serviceAccount.yaml -n kiratech-test
```
After that, you are ready to deploy the Helm chart with 
```
helm install jenkins -n kiratech-test -f values.yaml jenkinsci/jenkins
```
Once the Jenkins deployment status in the output of `kubectl get pods -n kiratech-test` is ready, the Jenkins GUI is accessible via browser at the address http://<your:master:node:public:DNS:address>:32240/.

### Jenkins
The first time you access Jenkins, you will be prompt to access as the administrator.
The administrator credentials must be extracted with the following commands
```
jsonpath="{.data.jenkins-admin-password}"
secret=$(kubectl get secret -n jenkins jenkins -o jsonpath=$jsonpath)
echo $(echo $secret | base64 --decode)
```
On my server I have set up 3 pipelines connected to this repo, connected with the specific Jenkins plugin, with the purpose of lint my code.
To do this I used 3 separates tools:
- Ansible Lint [10] for the directory ansible-challenge
- TFLint [11] for the directory terraform-challenge
- yamllint [12] for the directory helm-challenge
The pipelines run on a Kubernetes agent which builds the pipeline in a Pod based on the image python:3.9.

## 4. References
[1] https://aws.amazon.com/it/ec2/pricing/on-demand/#selectorArea

[2] https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#before-you-begin

[3] https://kubernetes.io/docs/tasks/administer-cluster/network-policy-provider/weave-network-policy/

[4] https://www.cisecurity.org/benchmark/kubernetes

[5] https://github.com/aquasecurity/kube-bench

[6] https://www.jenkins.io/

[7] https://docs.ansible.com/ansible/latest/collections/ansible/builtin/shell_module.html

[8] https://docs.ansible.com/ansible/latest/collections/kubernetes/core/k8s_module.html

[9] https://www.jenkins.io/doc/book/installing/kubernetes/

[10] https://ansible-lint.readthedocs.io/en/latest/

[11] https://github.com/terraform-linters/tflint

[12] https://yamllint.readthedocs.io/en/stable/quickstart.html