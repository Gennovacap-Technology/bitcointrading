require 'server'
require 'pg'

class Processor < Server

  PARTNER = '2020666'
  SECRET_KEY = 'F086BB356DF71F9BF9BE435D2A011A2D'

  def self.run!
    Server.new('processor').run! do
      EM.run do
        pg = PG.connect(host: 'localhost', dbname: 'bitcoin_futures', user: 'postgres', password: 'postgres')
        pg.prepare('insert_data_future', 'INSERT INTO "data" ("channel", "buy", "contract_id", "high", "hold_amount", "last", "low", "sell", "unit_amount", "vol") VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);')
        pg.prepare('insert_data_current', 'INSERT INTO "current_data" ("channel", "buy", "high", "last", "low", "sell", "timestamp", "vol") VALUES ($1, $2, $3, $4, $5, $6, $7, $8);')

        redis = Redis.new
        redis.subscribe(*CHANNELS) do |on|
          on.subscribe do |channel, subscriptions|
            Log::write "Subscribed to ##{channel} (#{subscriptions} subscriptions)"
          end

          on.message do |channel, message|
            Log::write "##{channel}: #{message}"

            data = JSON.parse(message)
            if channel == 'ok_btcusd_ticker' # current
              pg.exec_prepared('insert_data_current', [
                channel,
                data['buy'],
                data['high'],
                data['last'],
                data['low'],
                data['sell'],
                data['timestamp'].to_i,
                data['vol']
              ])
            else # future
              pg.exec_prepared('insert_data_future', [
                channel,
                data['buy'],
                data['contractId'],
                data['high'],
                data['hold_amount'],
                data['last'],
                data['low'],
                data['sell'],
                data['unitAmount'],
                data['vol']
              ])
            end
            redis.unsubscribe if message == "exit"
          end

          on.unsubscribe do |channel, subscriptions|
            Log::write "Unsubscribed from ##{channel} (#{subscriptions} subscriptions)"
          end
        end
      end
    end
  end

end
