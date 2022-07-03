provider "aws" {
    region = "eu-central-1"
    access_key = "{secrets.access_key}"
    secret_key = "{secrets.secret_key}"
}

resource "aws_instance" "master" {
  ami               = "ami-0c9354388bb36c088"
  instance_type     = "t3.medium"
  availability_zone = "eu-central-1a"
  key_name          = "kiratech-challenge"
  
  tags = {
    Name = "master"
  }
}

resource "aws_instance" "worker1" {
  ami               = "ami-0c9354388bb36c088"
  instance_type     = "t3.medium"
  availability_zone = "eu-central-1a"
  key_name          = "kiratech-challenge"
  
  tags = {
    Name = "worker1"
  }
}

resource "aws_instance" "worker2" {
  ami               = "ami-0c9354388bb36c088"
  instance_type     = "t3.medium"
  availability_zone = "eu-central-1a"
  key_name          = "kiratech-challenge"
  
  tags = {
    Name = "worker2"
  }
}

# resource "null_resource" "create_master_node" {
#   connection {
#     type = "ssh"
#     user = "ubuntu"
#     host = aws_instance.master.public_ip
#     private_key = "${file("/Users/lorenzorandazzo/Documents/certificates/kiratech-challenge.pem")}"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo su",
#       "kubeadm config images pull",
#       "kubeadm init --control-plane-endpoint $(aws_instance.test.public_ip):6443",
#       "kubeadm token create  --print-join-command > kubernetes_join_command.sh", # unable to assign this a local file
#       "su ubuntu",
#       "mkdir -p $HOME/.kube",
#       "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
#       "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
#       "kubectl apply -f \"https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')\""
#     ]
#   }
# }

# provisioner "local-exec" {
#     command = "scp -i ${file("/Users/lorenzorandazzo/Documents/certificates/kiratech-challenge.pem")} root@${aws_instance.master.public_dns}:~/kubernetes_join_command.sh ~/kubernetes_join_command.sh"
# }

# provisioner "local-exec" {
#     command = "scp -i ${file("/Users/lorenzorandazzo/Documents/certificates/kiratech-challenge.pem")} ubuntu@${aws_instance.master.public_dns}:/home/ubuntu/.kube/config ~/.kube/config"
# }

# resource "null_resource" "create_worker_node_1" {
#   connection {
#     type = "ssh"
#     user = "root"
#     host = aws_instance.worker1.public_ip
#     private_key = "${file("/Users/lorenzorandazzo/Documents/certificates/kiratech-challenge.pem")}"
#   }

#   provisioner "file" {
#     source      = "~/kubernetes_join_command.sh"
#     destination = "/tmp/kubernetes_join_command.sh"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sh /tmp/kubernetes_join_command.sh"
#     ]
#   }
# }

# resource "null_resource" "create_worker_node_2" {
#   connection {
#     type = "ssh"
#     user = "root"
#     host = aws_instance.worker2.public_ip
#     private_key = "${file("/Users/lorenzorandazzo/Documents/certificates/kiratech-challenge.pem")}"
#   }

#   provisioner "file" {
#     source      = "~/kubernetes_join_command.sh"
#     destination = "/tmp/kubernetes_join_command.sh"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sh /tmp/kubernetes_join_command.sh"
#     ]
#   }
# }

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kubernetes-admin@kubernetes"
}

resource "kubernetes_namespace" "namespace_kiratech" {
  metadata {
    name = "kiratech-test"
  }
}

resource "null_resource" "run_CIS_Kubernets_benchmark_on_master" {
  connection {
    type = "ssh"
    user = "ubuntu"
    host = aws_instance.master.public_ip
    private_key = "${file("/Users/lorenzorandazzo/Documents/certificates/kiratech-challenge.pem")}"
  }

  provisioner "remote-exec" {
    inline = [
      "wget https://github.com/aquasecurity/kube-bench/releases/download/v0.3.0/kube-bench_0.3.0_linux_amd64.tar.gz",
      "tar -xvf kube-bench_0.3.0_linux_amd64.tar.gz",
      "./kube-bench --config-dir `pwd`/cfg --config `pwd`/cfg/config.yaml master"
    ]
  }
}

resource "null_resource" "run_CIS_Kubernets_benchmark_on_worker_1" {
  connection {
    type = "ssh"
    user = "ubuntu"
    host = aws_instance.worker1.public_ip
    private_key = "${file("/Users/lorenzorandazzo/Documents/certificates/kiratech-challenge.pem")}"
  }

  provisioner "remote-exec" {
    inline = [
      "wget https://github.com/aquasecurity/kube-bench/releases/download/v0.3.0/kube-bench_0.3.0_linux_amd64.tar.gz",
      "tar -xvf kube-bench_0.3.0_linux_amd64.tar.gz",
      "./kube-bench --config-dir `pwd`/cfg --config `pwd`/cfg/config.yaml node"
    ]
  }
}

resource "null_resource" "run_CIS_Kubernets_benchmark_on_worker_2" {
  connection {
    type = "ssh"
    user = "ubuntu"
    host = aws_instance.worker2.public_ip
    private_key = "${file("/Users/lorenzorandazzo/Documents/certificates/kiratech-challenge.pem")}"
  }

  provisioner "remote-exec" {
    inline = [
      "wget https://github.com/aquasecurity/kube-bench/releases/download/v0.3.0/kube-bench_0.3.0_linux_amd64.tar.gz",
      "tar -xvf kube-bench_0.3.0_linux_amd64.tar.gz",
      "./kube-bench --config-dir `pwd`/cfg --config `pwd`/cfg/config.yaml node"
    ]
  }
}