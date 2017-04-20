var io = require('socket.io-client');
var amqp = require('amqplib');

var socket = io.connect('paymium.com/user', {
  path: '/ws/socket.io'
});

var channel = '';
var out = 'paymium_events';

ampq_conn = amqp.connect('amqp://localhost');

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


function rabbitListen() {
    ampq_conn.then((conn) => {
        return conn.createChannel()
    }).then((ch) => {
        let input = 'paymium_cmd';
        console.log(`consume queue ${input}`);
        ch.assertQueue(input).then((ok) => {
            ch.consume(input, function (msg) {
                if (msg !== null) {
                    //console.log(msg.content.toString());
                    channel = msg.content.toString();
                    socket.emit('channel', channel);
                    ch.ack(msg);
                }
            });
        });
    }).catch(console.warn);
}

console.log('CONNECTING');

socket.on('connect', function () {
    console.log('CONNECTED');
    console.log('WAITING FOR DATA...');
    rabbitBroadcast('ready');
});

socket.on('disconnect', function () {
    console.log('DISCONNECTED');
});

if (channel !== '')
    socket.emit('channel', channel);

socket.on('stream', function (data) {
    //console.log('GOT DATA:');
    //console.log(data);
    rabbitBroadcast(JSON.stringify(data))
});

rabbitListen();