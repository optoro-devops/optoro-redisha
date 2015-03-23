# Sentinel needs to connect to master to figure out the rest of the slaves and the sentinels
# What happens if we add a future node after a running sentinel has re-arranged things?
# Use Chef to create the template, use sentinel to monitor the template
master_ip = '127.0.0.1'
hosts = []

unless Chef::Config['solo']
  hosts = search(:node, 'recipe:optoro_redisha\:\:initial-master')
end

master_ip = hosts.empty? ? master_ip : hosts.first['ipaddress']

template '/etc/redis/sentinel.conf' do
  owner 'redis'
  group 'redis'
  variables(
    :sentinel => "sentinel monitor sentinel_sentinel #{master_ip} 6379 2"
  )
  not_if { ::File.exist?('/etc/redis/sentinel.conf') }
end
