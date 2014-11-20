role :app, %w{bitcoin@104.236.4.31}
role :web, %w{bitcoin@104.236.4.31}
role :db,  %w{bitcoin@104.236.4.31}

server '104.236.4.31', user: 'bitcoin', roles: %w{web app}

set :deploy_to, "/home/bitcoin/bitcoin_futures"

set :ssh_options, {
  forward_agent: true,
  port: 22,
  keys: '~/.ssh/id_rsa'
}
