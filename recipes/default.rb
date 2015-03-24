
# machine1:   master redis, sentinel:  needs "sentinel monitor" config line
# machine2,3: slave redis, sentinel:   needs "slaveof" and "sentinel monitor" config lines

# Build Tarball
execute 'build-redis' do
  cwd Chef::Config[:file_cache_path]
  command 'tar -xzf redis-2.8.19.tar.gz ; cd redis-2.8.19 ; make && make install'
  action :nothing
end

# Copy Source
remote_file "#{Chef::Config[:file_cache_path]}/redis-2.8.19.tar.gz" do
  source 'http://download.redis.io/releases/redis-2.8.19.tar.gz'
  notifies :run, 'execute[build-redis]', :immediately
end

# Make redis user
user 'redis' do
  shell '/bin/false'
end

# Make supporting directories
%w( /var/optoro/redis /var/log/redis /etc/redis ).each do |redisdir|
  directory redisdir do
    recursive true
    owner 'redis'
    group 'redis'
  end
end

# Copy Init Scripts
%w( /etc/init.d/redis /etc/init.d/sentinel ).each do |redisinit|
  cookbook_file redisinit do
    mode 0755
  end
end

# Search for an existing master
hosts = []
unless Chef::Config['solo']
  hosts = search(:node, 'redisha_master')
end

# If found, set the ip address, if not, we are master, use our ip address
master_ip = hosts.empty? ? node['ipaddress'] : hosts.first['ipaddress']
# Tell the world we are master
node.set['redisha_master'] = true if master_ip == node['ipaddress']

# Create slaveof line for slaves, leave nil if we are master
slaveof = nil
unless master_ip == node['ipaddress']
  slaveof = "slaveof #{master_ip}"
end

template '/etc/redis/redis.conf' do
  owner 'redis'
  group 'redis'
  variables(
    :slaveof => slaveof
  )
  not_if { ::File.exist?('/etc/redis/redis.conf') }
end

template '/etc/redis/sentinel.conf' do
  owner 'redis'
  group 'redis'
  variables(
    :sentinel => "sentinel monitor sentinel_sentinel #{master_ip} 6379 2"
  )
  not_if { ::File.exist?('/etc/redis/sentinel.conf') }
end

# Allow services to be started                            
%w( redis sentinel ).each do |redisservice|
  service redisservice do
    supports :start => true
    action :start
  end
end

# Notes
# backups?
# communicate to devs to talk with a sentinel server and not with redis directly:
# http://redis.io/topics/sentinel-clients
