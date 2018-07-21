const sqlQueries = require('../sqlQueries.js');
const Broadcast = require('./SocketHelpers.js').Broadcast;
const Validations = require('./SocketHelpers.js').Validations;

// Broadcasts the active games to all users.
function getGames () {
    const self = this;

    sqlQueries.getGames(function (GameList) {
        console.log('Sending game list to ' + self.socket.user.username);
        self.socket.emit('lobbyGameList', {games: GameList});
    });
}

module.exports = function(socket){
    this.socket = socket;

    this.handlers = {
        'lobbyGetGames': getGames.bind(this)
    };
};
