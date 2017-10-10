const sqlQueries = require('../sqlQueries.js');
const Broadcasts = require('./Broadcasts.js');

const broadcastActiveRooms = function() {
    let self = this;

    Broadcasts.refreshRoomList(self.socket);
};

// Creates a new room.
const createRoom = function(roomInfo) {
    let self = this;

    // Builds info about user for the SQL query.
    let userInfo = {userId: self.app.onlineUsers[self.socket.id]};

    if(roomInfo.roomPassword.trim().length < 1) {
        roomInfo.roomPassword = 'NULL'
    }

    if (roomInfo.roomName.trim().length < 4 || roomInfo.roomName.trim().length > 20) {
        self.socket.emit('server error', {error: 'Room name must be between 4 and 20 characters.'});
    } else {
        // Creates room in SQL
        sqlQueries.createRoom(userInfo, roomInfo, function (results) {
            // Host joins room channel.
            self.socket.join(results[0].roomId);
            console.log('Created room ' + results[0].roomId);

            Broadcasts.refreshRoomList(self.socket);

            sqlQueries.getRoomDetails(results[0], function (results) {
                self.socket.server.in(results.roomId).emit('room update', results);
            });
        });
    }
};

const joinRoom = function(roomInfo) {
    let self = this;

    // Builds info about user for the SQL query.
    let userInfo = {userId: self.app.onlineUsers[self.socket.id]};

    sqlQueries.getRoomDetails(roomInfo, function(results) {

        if (results.players.length > 1) {
            self.socket.emit('server error', {error: 'Room is full.'});
        } else {
            // Joins room in SQL.
            sqlQueries.joinRoom(userInfo, roomInfo, function () {
                // Joins room's socket.io channel.
                self.socket.join(roomInfo.roomId);

                Broadcasts.refreshRoomList(self.socket);

                // Gets the room's players and other room info to broadcast to channel.
                sqlQueries.getRoomDetails(roomInfo, function (results) {
                    self.socket.server.in(roomInfo.roomId).emit('room update', results);
                });
            });
        }
    });
};

module.exports = function(app, socket){
    this.app = app;
    this.socket = socket;

    this.handlers = {
        'lobby get active rooms': broadcastActiveRooms.bind(this),
        'lobby create room': createRoom.bind(this),
        'lobby join room': joinRoom.bind(this)
    };
};