require "yaml"
require 'json'
settings = YAML.load_file "settings.yaml"

VIP_HOSTNAME = settings["ip"]["vip_hostname"]
VIP  = settings["ip"]["vip"]
HOSTNAME = settings["host"]["hostname"]
DEPLOYMENT = settings["host"]["deployment"]
COUNT = settings["host"]["worker"]
NETWORK = settings["ip"]["network"]
IP_START = settings["ip"]["start"]
DOMAIN = settings["ip"]["domain"]
BRIDGE = settings["bridge"]
SUPPORT_USER = settings["support_user"]
FOLDERS = %w[stage files keys]

# ─── Banner ───────────────────────────────────────────────────────
load 'banner.rb'

# ─── Validate control plane setup ─────────────────────────────────
server_count = case DEPLOYMENT
when "single"
  1
when "cluster"
  3
else
  abort("Invalid DEPLOYMENT value: #{DEPLOYMENT}. Must be 'single' or 'cluster'.")
end

COUNT += server_count

# ─── Build hostname-to-IP map ─────────────────────────────────────
hostname_ip_map = (1..COUNT).map do |i|
  ["#{HOSTNAME}#{i}", "#{NETWORK}.#{IP_START + i - 1}"]
end.to_h.merge("#{VIP_HOSTNAME}" => "#{NETWORK}.#{VIP}")

map_json = hostname_ip_map.to_json

# ─── Ensure required folders exist ────────────────────────────────
FOLDERS.each do |folder|
  unless Dir.exist?(folder)
    puts "\e[32mCreating #{folder} folder...\e[0m"
    Dir.mkdir(folder)
  end
end

# ─── Vagrant configuration ───────────────────────────────────────
Vagrant.configure("2") do |config|
  config.vm.box = settings["software"]["box"]
  config.vm.box_check_update = true

  config.vm.provision "file", source: "scripts/lib.sh", destination: "/tmp/lib.sh"

  config.vm.provision "shell",
    name: "Configure common settings for nodes",
    env: {
      "SUPPORT_USER" => SUPPORT_USER,
    },
    path: "scripts/common.sh"

    config.vm.provision "shell",
    name: "Networking configuration",
    env: {
      "IP" => IP_START,
      "NETWORK" => NETWORK,
      "DOMAIN" => DOMAIN,
      "HOSTNAME_IP_MAP" => map_json,
      "HOSTNAME" => HOSTNAME,
    },
    path: "scripts/networking.sh"

  hostname_ip_map.each_with_index do |(node_name, node_ip), idx|
    #skip VIP
    next if idx == hostname_ip_map.size - 1
    
    config.vm.define node_name do |host|
      host.vm.hostname = node_name
      host.vm.network :public_network, ip: node_ip, bridge: BRIDGE

    host.vm.provider "virtualbox" do |vb|
        vb.cpus   = settings["host"]["cpu"]
        vb.memory = settings["host"]["memory"]
    end

    host.vm.provision "shell",
      name: "Configure nodes",
      env: {
          "HOSTNAME"       => HOSTNAME,
          "HOSTNAME_IP_MAP" => map_json,
          "NODE_ID"        => (idx + 1).to_s,
          "NODE_COUNT"     => COUNT,
          "SERVER_COUNT"   => server_count,
          "NETWORK"        => NETWORK,
          "IP"             => IP_START + idx,
          "DOMAIN"         => DOMAIN,
          "VIP"            => VIP,
          "VIP_HOSTNAME"   => VIP_HOSTNAME,
          "DEPLOYMENT"     => DEPLOYMENT,
      },
      path: "scripts/rke2.sh"
    end
  end
end
