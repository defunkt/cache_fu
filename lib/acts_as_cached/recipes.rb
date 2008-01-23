Capistrano.configuration(:must_exist).load do
  %w(start stop restart kill status).each do |cmd|
    desc "#{cmd} your memcached servers"
    task "memcached_#{cmd}".to_sym, :roles => :app do
      run "RAILS_ENV=production #{ruby} #{current_path}/script/memcached_ctl #{cmd}"
    end
  end
end
