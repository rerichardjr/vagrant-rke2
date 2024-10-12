require "yaml"
settings = YAML.load_file "settings.yaml"

SERVER_NODE_HOSTNAME = settings["nodes"]["server"]["hostname"]
AGENT_NODE_COUNT = settings["nodes"]["agent"]["count"]
AGENT_NODE_HOSTNAME = settings["nodes"]["agent"]["hostname"]
RKE2_NET = settings["ip"]["network"]
SERVER_IP = RKE2_NET + "#{settings["ip"]["server_net_start"]}"
AGENT_NET_START = settings["ip"]["agent_net_start"]
SUPPORT_USER = settings["support_user"]
DOMAIN = settings["ip"]["domain"]
BRIDGE = settings["bridge"]

Vagrant.configure("2") do |config|
  config.vm.box = settings["software"]["box"]
  config.vm.box_check_update = true

  config.vm.provision "shell",
    name: "Configure common settings for nodes",
    env: {
      "SUPPORT_USER" => SUPPORT_USER,
      "DOMAIN" => DOMAIN,
      "SERVER_NODE_HOSTNAME" => SERVER_NODE_HOSTNAME,
      "SERVER_IP" => SERVER_IP,
    },
    path: "scripts/common.sh"

  config.vm.define SERVER_NODE_HOSTNAME do |server|
    server.vm.hostname = SERVER_NODE_HOSTNAME
    server.vm.network :public_network, ip: SERVER_IP, :bridge => BRIDGE
    server.vm.provider "virtualbox" do |vb|
      vb.cpus = settings["nodes"]["server"]["cpu"]
      vb.memory = settings["nodes"]["server"]["memory"]
    end
    server.vm.provision "shell",
      name: "Configure server node",
      env: {
          "SERVER_IP" => SERVER_IP,
          "SERVER_NODE_HOSTNAME" => SERVER_NODE_HOSTNAME,
          "DOMAIN" => DOMAIN,
          "SUPPORT_USER" => SUPPORT_USER,
      },
      path: "scripts/server-node.sh"
  end

  (1..AGENT_NODE_COUNT).each do |i|
    config.vm.define "#{AGENT_NODE_HOSTNAME}#{i}" do |agent|
      agent.vm.hostname = "#{AGENT_NODE_HOSTNAME}#{i}"
      agent.vm.network :public_network, ip: RKE2_NET + "#{AGENT_NET_START+i}", :bridge => BRIDGE
      agent.vm.provider "virtualbox" do |vb|
        vb.cpus = settings["nodes"]["agent"]["cpu"]
        vb.memory = settings["nodes"]["agent"]["memory"]
      end
      agent.vm.provision "shell",
        name: "Configure agent nodes",
        env: {
            "NETWORK" => RKE2_NET,
            "NODE_START" => "#{AGENT_NET_START+i}",
            "DOMAIN" => DOMAIN,
            "SERVER_NODE_HOSTNAME" => SERVER_NODE_HOSTNAME,
        },
        path: "scripts/agent-node.sh"
    end
  end
end

if ( settings["install_addons"] == true )
  Vagrant.configure("2") do |config|
    config.vm.define SERVER_NODE_HOSTNAME do |server|
      server.vm.provision "shell",
      name: "Install addons",
      env: {
        "DOMAIN" => DOMAIN,
        "SERVER_NODE_HOSTNAME" => SERVER_NODE_HOSTNAME,
        "HELM_VER" => settings["software"]["helm"],
        "RANCHER_VER" => settings["software"]["rancher"],
        "CERTMANAGER_VER" => settings["software"]["cert-manager"],
        "LONGHORN_VER" => settings["software"]["longhorn"],
      },
      path: "scripts/addons.sh",
      privileged: false
    end
  end
end