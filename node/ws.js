var io = require('socket.io-client');
var amqp = require('amqplib/callback_api');

var socket = io.connect('paymium.com/user', {
  path: '/ws/socket.io'
});

var channel = '';

function rabbitBroadcast(message){
  amqp.connect('amqp://localhost', function(err, conn) {
    if(err){
        console.log(`failed to connect ${err}`);
    } else {
        conn.createChannel(function(err, ch) {
            if(err) console.log(`failed to create channel ${err}`);

            var out = 'paymium_events';

            ch.assertQueue(out, {durable: true});
            console.log(message);
            ch.sendToQueue(out, new Buffer(message));
        });
    }
  });
}

function rabbitListen(){
    amqp.connect('amqp://localhost', function(err, conn) {
        if(err) {
            console.log(`failed to connect ${err}`);
        } else {
            conn.createChannel(function(err, ch) {
                var input = 'paymium_cmd';
                console.log(`consume queue ${input}`);

                ch.assertQueue(input);

                ch.consume(input, function(msg) {
                    if (msg !== null) {
                        //console.log(msg.content.toString());
                        channel = msg.content.toString();
                        socket.emit('channel', channel);
                        ch.ack(msg);
                    }
                });
            });
        }
    });
}

console.log('CONNECTING');

socket.on('connect', function() {
  console.log('CONNECTED');
  console.log('WAITING FOR DATA...');
  rabbitBroadcast('ready');
});

socket.on('disconnect', function() {
  console.log('DISCONNECTED');
});

if(channel !== '')
  socket.emit('channel', channel);

socket.on('stream', function(data) {
  //console.log('GOT DATA:');
  //console.log(data);
  rabbitBroadcast(JSON.stringify(data))
});

rabbitListen();
