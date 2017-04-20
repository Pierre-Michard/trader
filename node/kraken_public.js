var util = require('util');
const WebSocket = require('ws');
var ampq_conn = require('amqplib').connect('amqp://localhost');

var out = 'kraken_public';

out_queue = ampq_conn.then( (conn) => {
    return conn.createChannel();
}).then((ch) => {
    ch.assertQueue(out, {durable: true});
    return ch;
});


function rabbitBroadcast(message) {
    //console.log(message);
    out_queue.then((ch) => {
        ch.sendToQueue(out, new Buffer(message));
    }).catch(console.warn);
}

console.log('connecting');

var ws = new WebSocket('wss://d2.bitcoinwisdom.com/?symbol=krakenbtceur', {
    perMessageDeflate: true
});

ws.onmessage = function(m) {
    data = JSON.parse(m.data);
    if((data.trades) || (data.sdepth))
    {
        //console.log('Got trades or sdepth: ', JSON.stringify(data));
        rabbitBroadcast(m.data);
    }
};

ws.on('open', function open() {
    console.log('connected');
});

ws.on('close', function close() {
    console.log('disconnected');
});


setInterval(()=>{
    ws.send('ping');
}, 5000);

