var io = require('socket.io-client');
var amqp = require('amqplib');

var socket = io.connect('paymium.com/public', {
  path: '/ws/socket.io'
});

var out = 'paymium_public';

var ampq_conn = amqp.connect('amqp://localhost');

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


console.log('CONNECTING');

socket.on('connect', function () {
    console.log('CONNECTED');
    console.log('WAITING FOR DATA...');
});

socket.on('disconnect', function () {
    console.log('DISCONNECTED');
});

socket.on('stream', function (data) {
    //console.log('GOT DATA:');
    //console.log(data);
    rabbitBroadcast(JSON.stringify(data))
});
