require 'faye/websocket'
require 'eventmachine'
require 'redis'
require 'json'
require 'pg'

EM.run {
  PARTNER = '2020666'
  SECRET_KEY = 'F086BB356DF71F9BF9BE435D2A011A2D'
  CHANNELS = [
    'ok_btcusd_future_ticker_this_week',
    'ok_btcusd_future_ticker_next_week',
    'ok_btcusd_future_ticker_month',
    'ok_btcusd_future_ticker_quarter'
  ]

  pg = PG.connect(dbname: 'okcoin', user: 'vagrant', password: 'vagrant')
  pg.prepare('insert_data', 'INSERT INTO "data" ("channel", "buy", "contract_id", "high", "hold_amount", "last", "low", "sell", "unit_amount", "vol") VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);')

  redis = Redis.new
  redis.subscribe(*CHANNELS) do |on|
    on.subscribe do |channel, subscriptions|
      puts "Subscribed to ##{channel} (#{subscriptions} subscriptions)"
    end

    on.message do |channel, message|
      puts "##{channel}: #{message}"

      data = JSON.parse(message)
      pg.exec_prepared('insert_data', [
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

      redis.unsubscribe if message == "exit"
    end

    on.unsubscribe do |channel, subscriptions|
      puts "Unsubscribed from ##{channel} (#{subscriptions} subscriptions)"
    end
  end

# {"buy"=>382.42, "contractId"=>"20141121012", "high"=>390.45, "hold_amount"=>397169, "last"=>"382.43", "low"=>375, "sell"=>382.59, "unitAmount"=>100, "vol"=>"694,104.00"}

  # @ws.on :open do |event|
  #   puts "connection open"
  # end

  # @ws.on :message do |event|
  #   # redis.publish(:ok_btcusd_ticker, event.data)
  # end

  # @ws.on :close do |event|
  #   p [:close, event.code, event.reason]
  #   @ws = nil
  # end


  # def send(message)
  #   @ws.send(message)
  # end

  # def spot_trade(channel, symbol, type, price, amount)
  #   send("{'event':'addChannel','channel':'"+channel+"','parameters':{'partner':'"+partner+"','secretkey':'"+secretKey+"','symbol':'"+symbol+"','type':'"+type+"','price':'"+price+"','amount':'"+amount+"'}}")

  # end

  # def spot_cancel_order(channel, symbol, order_id)
  #   send("{'event':'addChannel','channel':'"+channel+"','parameters':{'partner':'"+partner+"','secretkey':'"+secretKey+"','symbol':'"+symbol+"','order_id':'"+order_id+"'}}")
  # end
}
