require 'mina/bundler'
require 'mina/git'

# Basic settings:
# domain     - The hostname to SSH to
# deploy_to  - Path to deploy into
# repository - Git repo to clone from (needed by mina/git)
# user       - Username in the  server to SSH to (optional)

set :user, 'deploy'
set :domain, 'radiophonics'
set :deploy_to, '/var/www/webaudio'
set :repository, 'gitlab:radiophonics.git'

desc "Deploys the current version to the server."
task :deploy do
  deploy do
    invoke :'git:clone'
  end
end
