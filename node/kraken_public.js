var amqp = require('amqplib/callback_api');
var util = require('util');
const WebSocket = require('ws');


function rabbitBroadcast(message){
    amqp.connect('amqp://localhost', function(err, conn) {
        if(err) console.log(`failed to connect ${err}`);

        conn.createChannel(function(err, ch) {
            if(err) console.log(`failed to create channel ${err}`);

            var out = 'kraken_public';

            ch.assertQueue(out, {durable: true});
            console.log(message);
            ch.sendToQueue(out, new Buffer(message));
        });

    });
}

console.log('CONNECTING');


var ws = new WebSocket('wss://d2.bitcoinwisdom.com/?symbol=krakenbtceur', {
    perMessageDeflate: true
});

ws.onmessage = function(m) {
    data = JSON.parse(m.data)
    if(data.trades)
        console.log('Got trades: ', JSON.stringify(data.trades));
    if(data.sdepth)
        console.log('Got sdepth: ', JSON.stringify(data.sdepth));

};