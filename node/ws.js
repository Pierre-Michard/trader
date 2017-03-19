var io = require('socket.io-client');
var amqp = require('amqplib/callback_api');

var socket = io.connect('sandbox.paymium.com/user', {
  path: '/ws/socket.io'
});


function rabbitBroadcast(message){
  amqp.connect('amqp://localhost', function(err, conn) {
    if(err) console.log(`failed to connect ${err}`)

    conn.createChannel(function(err, ch) {
      if(err) console.log(`failed to create channel ${err}`)

      var q = 'paymium';

      ch.assertQueue(q, {durable: true});
      console.log(message);
      ch.sendToQueue(q, new Buffer(message));
    });
  });
}

channel = 'fe7732f9237917fcd1d0d32403440418a104e997f47780b0b9f922a6c76c0e39'
console.log('CONNECTING');

socket.on('connect', function() {
  console.log('CONNECTED');
  console.log('WAITING FOR DATA...');
});

socket.on('disconnect', function() {
  console.log('DISCONNECTED');
});

socket.emit('channel', channel);

socket.on('stream', function(data) {
  console.log('GOT DATA:');
  console.log(data);
  rabbitBroadcast(JSON.stringify(data))
});
