hosts = []

unless Chef::Config['solo']
  hosts = search(:node, 'recipe:optoro_redisha\:\:initial-master')
end

master_ip = hosts.empty? ? nil : hosts.first['ipaddress']
slaveof = master_ip ? "slaveof #{master_ip}" : nil

template '/etc/redis/redis.conf' do
  owner 'redis'
  group 'redis'
  variables(
    :slaveof => slaveof
  )
  not_if { ::File.exist?('/etc/redis/redis.conf') }
end

sentinel_value = master_ip || node['ipaddress']

template '/etc/redis/sentinel.conf' do
  owner 'redis'
  group 'redis'
  variables(
    :sentinel => "sentinel monitor sentinel_sentinel #{sentinel_value} 6379 2"
  )
  not_if { ::File.exist?('/etc/redis/sentinel.conf') }
end
