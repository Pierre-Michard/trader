const KryptoSocket = require('krypto-socket');
const timestamp = require('unix-timestamp');

var ampq_conn = require('amqplib').connect('amqp://localhost');

var out = 'kraken_public';

out_queue = ampq_conn.then( (conn) => {
    return conn.createChannel();
}).then((ch) => {
    ch.assertQueue(out, {durable: true});
    return ch;
});


function rabbitBroadcast(type, content) {
    let message = {
        'now' : parseInt(timestamp.now()),
        'type' : type
    };
    message[type] = content;

    console.log(JSON.stringify(message));
    out_queue.then((ch) => {
        ch.sendToQueue(out, new Buffer(JSON.stringify(message)));
    }).catch(console.warn);
}

console.log('connecting');

let kryptoSocket = new KryptoSocket(["market:kraken:btceur:orderbook:snapshots", "market:kraken:btceur:trades"]);

kryptoSocket.on('message', (message) => {
    if(message.tradesUpdate) {
        rabbitBroadcast('trades', message['tradesUpdate']['trades']);
    }
    if (message.orderBookUpdate) {
        rabbitBroadcast('sdepth', message['orderBookUpdate']);
    }
});