describe 'optoro_redisha::default' do
  Resources::PLATFORMS.each do |platform, value|
    value['versions'].each do |version|
      context "On #{platform} #{version}" do
        include_context 'optoro_redisha'

        let(:chef_run) do
          ChefSpec::SoloRunner.new(platform: platform, version: version, log_level: :error) do |node|
            node.set['lsb']['codename'] = value['codename']
            node.set['redisha']['master'] = 'redis-001.stage.blinq.com'
          end.converge(described_recipe)
        end

        it 'copies the redis binary' do
          expect(chef_run).to create_remote_file("#{Chef::Config[:file_cache_path]}/redis-2.8.19.tar.gz")
        end

        it 'does nothing' do
          expect(chef_run).to_not run_execute('build-redis')
        end

        it 'creates redis user' do
          expect(chef_run).to create_user('redis')
        end

        %w( /var/optoro/redis /var/log/redis /etc/redis ).each do |directory|
          it "creates #{directory}" do
            expect(chef_run).to create_directory(directory)
          end
        end

        %w( /etc/init.d/redis /etc/init.d/sentinel ).each do |redisinit|
          it "creates #{redisinit}" do
            expect(chef_run).to render_file(redisinit)
          end
        end

        %w( redis sentinel ).each do |redisservice|
          it 'starts services' do
            expect(chef_run).to start_service(redisservice)
          end
        end
      end
    end
  end
end
