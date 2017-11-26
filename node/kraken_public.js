const KryptoSocket = require('krypto-socket');
const timestamp = require('unix-timestamp');


class kryptoToRabbit{
    constructor(rabbitChannelName, kryptoChannels) {
        this.rabbitChannelName = rabbitChannelName;
        this.rabbit = this.rabbitChannel( rabbitChannelName);
        let kryptoSocket = new KryptoSocket(kryptoChannels);

        kryptoSocket.on('message', (message) => {
            if (message.tradesUpdate) {
                this.rabbitBroadcast('trades', message['tradesUpdate']['trades']);
            }
            if (message.orderBookUpdate) {
                this.rabbitBroadcast('sdepth', message['orderBookUpdate']);
            }
        });
    }

    rabbitChannel(channelName){
        return this.rabbitConn().then( (conn) => {
                return conn.createChannel();
            }).then((ch) => {
                ch.assertQueue(channelName, {durable: true});
                return ch;
            });
    }

    rabbitConn(){
        return require('amqplib').connect('amqp://localhost');
    }

    rabbitBroadcast(type, content) {
        let message = {
            'now' : parseInt(timestamp.now()),
            'type' : type
        };
        message[type] = content;

        console.log(JSON.stringify(message));
        this.rabbit.then((ch) => {
            ch.sendToQueue(this.rabbitChannelName, new Buffer(JSON.stringify(message)));
        }).catch(console.warn);
    }
}

new kryptoToRabbit('kraken_public', ["market:kraken:btceur:orderbook:snapshots", "market:kraken:btceur:trades"]);
//new kryptoToRabbit('gdax_public', ["market:gdax:btceur:orderbook:snapshots"]);