const sqlQueries = require('../sqlQueries.js');
const Broadcasts = require('./Broadcasts.js');

const loginRequest = function(userInfo){

};

module.exports = function(app, socket){
    this.app = app;
    this.socket = socket;

    this.handlers = {
        'login request': loginRequest.bind(this)
    };
};