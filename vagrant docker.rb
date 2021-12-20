  # Docker provider pulls from hub.docker.com respecting docker.image if
  # config.vm.box is nil. In this case, we adhoc build util/vagrant/Dockerfile.
  # Note that this bind-mounts from the current dir to
  # /vagrant in the guest, so unless your UID is 1000 to match vagrant in the
  # image, you'll need to: chmod -R a+rw .
  config.vm.provider "docker" do |docker, override|
    override.vm.box = nil
    docker.build_dir = "util/vagrant"
    docker.has_ssh = true
  end

  # Unless we are running the docker container directly
  #   1. run container detached on vm
  #   2. attach on 'vagrant ssh'
  ["virtualbox", "vmware_workstation", "vmware_fusion"].each do |type|
    config.vm.provider type do |virt, override|
      override.vm.provision "docker" do |d|
        d.run "qmkfm/base_container",
          cmd: "tail -f /dev/null",
          args: "--privileged -v /dev:/dev -v '/vagrant:/vagrant'"
      end

      override.vm.provision "shell", inline: <<-SHELL
        echo 'docker restart qmkfm-base_container && exec docker exec -it qmkfm-base_container /bin/bash -l' >> ~vagrant/.bashrc
      SHELL
    end
  end

  config.vm.post_up_message = <<-EOT
    Hello - your VM is up !
  EOT


  Vagrant.configure("2") do |config|
    config.vm.box = "hashicorp/bionic64"
    config.vm.provision "docker" do |d|
      d.build_image "/vagrant/app" ## building image
    end
  end


  Vagrant.configure("2") do |config|
    config.vm.box = "hashicorp/bionic64"
    config.vm.provision "docker",
      images: ["ubuntu"] ## Pulling image
  end

  Vagrant.configure("2") do |config|
    config.vm.box = "hashicorp/bionic64"
    config.vm.provision "docker" do |d|
      d.run "rabbitmq" ## running container
        cmd: "bash -l", ## arguments
        args: "-v '/vagrant:/var/www'" ## arguments
    end
  end


  Vagrant.configure("2") do |config|
    config.vm.box = "hashicorp/bionic64"
    config.vm.provision "docker" do |d|
      d.post_install_provision "shell", inline:"echo export http_proxy='http://127.0.0.1:3128/' >> /etc/default/docker"
      d.run "ubuntu",
        cmd: "bash -l",
        args: "-v '/vagrant:/var/www'"
    end
  end