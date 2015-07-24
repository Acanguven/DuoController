// Load the TCP Library
net = require('net');
var fs = require('fs');
var http = require('http');



// Keep track of the chat clients
var clients = [];
var commandsList = [];
// Start a TCP Server
net.createServer(function (socket) {

  // Identify this client
  socket.name = socket.remoteAddress + ":" + socket.remotePort
  socket.secretKey = false

  // Put this new client in the list
  clients.push(socket);
  // Send a nice welcome message and announce
  // Handle incoming messages from clients.
  socket.on('data', function (buffer) {
    var data = buffer.toString('utf8')
    commandsList.push(data);
    data = data.replace(/(\r\n|\n|\r)/gm,"");
    data = data.split("||")[0]
    var action = data.split(",")
    switch(action[0]){
      //Setup Client
      case "setup":
        socket.gameId = action[1];
        socket.champion = action[2];
        socket.allowedPlayer = {}
        socket.write("setuptrue,"+socket.gameId);
      break;
      //Player Permissions
      case "auth":
        socket.allowedPlayer[action[1]] = (action[2].toLowerCase() === 'true');
        var respond = ["auth",action[1],socket.allowedPlayer[action[1]]]
        socket.write(respond.join())
      break;

      //Get Players
      case "getplayers":
        var list = clients.findByGameId(socket.gameId,socket.champion)
        resList = ["online"]
        for(var x = 0; x < list.length; x++){
          resList.push(list[x].champion)
        }
        resList = resList.join()
        socket.write(resList)
      break;

      case "select":
        var list = clients.findByGameId(socket.gameId,socket.champion)
        var target = action[1]
        var targetSocket = list.findByChampion(target)
        if (targetSocket && targetSocket.allowedPlayer[socket.champion]){
          var respond = ["selected",target]
          socket.write(respond.join())
          targetSocket.write("puppetmaster,"+socket.champion)
        }else{
          var respond = ["cantselect",target]
          socket.write(respond.join())
        }
      break;

      //Movement
      case "0":
        var command = [0,action[2],action[3]]
        var target = action[1]
        var list = clients.findByGameId(socket.gameId,socket.champion);
        var targetSocket = list.findByChampion(target)
        if (targetSocket && targetSocket.allowedPlayer[socket.champion]){
          command = [0,action[2],action[3]].join()
          targetSocket.write(command)
        }
      break;
      //Spell
      case "1":
        var command = [0,action[2],action[3]]
        var target = action[1]
        var list = clients.findByGameId(socket.gameId,socket.champion);
        var targetSocket = list.findByChampion(target)
        if (targetSocket && targetSocket.allowedPlayer[socket.champion]){
          command = [1,action[2],action[3],action[4]].join()
          targetSocket.write(command)
        }
      break;
      //Attack
      case "2":
        var command = [0,action[2],action[3]]
        var target = action[1]
        var list = clients.findByGameId(socket.gameId,socket.champion);
        var targetSocket = list.findByChampion(target)
        if (targetSocket && targetSocket.allowedPlayer[socket.champion]){
          command = [2,action[2],action[3]].join()
          targetSocket.write(command)
        }
      break;
    }
  });

  socket.on('end', function () {
    clients.splice(clients.indexOf(socket), 1);
  });

  socket.on("error", function(err){
    console.log("Caught flash policy server socket error: ")
    console.log(err.stack)
  })


}).listen(44444);

console.log("Duo Controller server running at port 5000\n");

function sendByKey(message, sender) {
  clients.forEach(function (client) {
    if (client === sender) return;
    client.write(message);
  });
}

Array.prototype.findByGameId = function(id,champion){
  list = [];
  for(var x = 0; x < this.length; x++){
    if(this[x].gameId == id && this[x].champion != champion){
      list.push(this[x]);
    }
  }
  return list;
}

Array.prototype.findByChampion = function(champion){
  for(var x = 0; x < this.length; x++){
    if(this[x].champion == champion){
      return this[x]
    }
  }
  return false
}

var httpser = http.createServer(function(req, res) {
    res.write("<h1>Duo Controller</h1>\n")
    res.write("Connected users:"+clients.length)
    
    
    res.write("<h1>Latest Commands</h1>\n")
    for(var x = 0; x < commandsList.length; x++){
        res.write((x+1) + ":" +commandsList[x] + "<br>");
    }
    
    res.end()
})
httpser.listen(88, '0.0.0.0');
