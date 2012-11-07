request = require 'request'
libxmljs = require("libxmljs")

exports.index = (req, res) ->
  console.log "routes#index"
  res.render 'index', title: 'Planning Poker'


exports.login = (req, res) ->
  console.log "routes#login"
  res.render 'login', { error: req.flash('error') }

exports.logout = (req, res) ->
  req.logOut()
  res.redirect('/')

exports.vote = (req, res) ->
  res.send 'ok'
