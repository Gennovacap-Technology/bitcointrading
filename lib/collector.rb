require 'server'
class Collector < Server

  def self.run!
    Server.new('collector').run! do
      EM.run do
        ws = Faye::WebSocket::Client.new('wss://real.okcoin.com:10440/websocket/okcoinapi')
        redis = Redis.new

        ws.on :open do |event|
          puts "connection open"

          CHANNELS.each do |channel|
            ws.send(%Q[{"event":"addChannel","channel":"#{channel}"}])
          end
        end

        ws.on :message do |event|
          event_object = JSON.parse(event.data)
          event_object.each do |ev|
            redis.publish(ev['channel'], ev['data'].to_json)
          end
        end

        ws.on :close do |event|
          p [:close, event.code, event.reason]
          ws = nil
        end
      end
    end
  end

end
