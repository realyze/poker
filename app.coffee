
express = require('express')
routes = require('./routes')
user = require('./routes/user')
http = require('http')
path = require('path')
passport = require 'passport'
LocalStrategy = require('passport-local').Strategy
agent = require 'superagent'
libxmljs = require("libxmljs")
flash = require('connect-flash')
request = require 'request'
RedisStore = require('connect-redis')(express)
require 'express-namespace'

app = express()

app.configure ->
  app.set('port', process.env.PORT || 3000)
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')
  app.use(express.favicon())
  app.use(express.logger('dev'))
  app.use(express.bodyParser())
  app.use(express.methodOverride())
  app.use(express.cookieParser('23b78fg48cby384fv8f38f'))
  app.use(express.session({secret: "ervf237fgb34fb283fg", store: new RedisStore}))
  app.use(require('stylus').middleware(__dirname + '/public'))
  app.use(express.static(path.join(__dirname, 'public')))
  app.use passport.initialize()
  app.use passport.session()
  app.use flash()
  app.use(app.router)

app.configure 'development', ->
  app.use express.errorHandler()
  app.locals.pretty = true

app.post '/login',
  passport.authenticate 'local', { successRedirect: '/', failureRedirect: '/login', failureFlash: true}

app.get '/login', routes.login

ensureAthenticated = (req, res, next) ->
  console.log 'ensureAthenticated'
  if req.isAuthenticated()
    return next()
  else
    return res.redirect '/login'

app.get '/', ensureAthenticated, routes.index
app.get '/logout', ensureAthenticated, routes.logout
app.namespace '/projects', ensureAthenticated, -> require('./routes/projects').setup(app)
app.post '/vote', ensureAthenticated, routes.vote


server = app.listen app.get('port'), ->
  console.log "Express server listening on port " + app.get('port') + ' with env: ' + app.settings.env

sio = require('socket.io').listen(server)

passport.serializeUser (user, done) ->
  console.log "serializeUser: #{JSON.stringify user}"
  done null, user

passport.deserializeUser (user, done) ->
  console.log "deserializeUser: #{JSON.stringify user}"
  done null, user

passport.use new LocalStrategy (username, password, done) ->
  console.log 'authenticating'
  request.get {url: "https://#{encodeURIComponent username}:#{encodeURIComponent password}@www.pivotaltracker.com/services/v3/tokens/active"}, (e, r, body) ->
    if e
      return done(e)
    if r.statusCode != 200
      return done(null, false, message: "PT returned: #{r.statusCode}")
    else
      handleWebSocketConnection(username)
      apiTokenElem = libxmljs.parseXml(body).get('//guid')
      done(null, token: apiTokenElem.text())
    

handleWebSocketConnection = (username) ->
  sio.sockets.on 'connection', (socket) ->
    console.log 'WS connected'
    socket.on 'subscribe', socket.join
    socket.on 'unsubscribe', socket.leave
    socket.on 'vote', (obj) ->
      console.log "voted: #{JSON.stringify obj}"
      sio.sockets.in(obj.room).emit('client_voted', {user: username, value: obj.value})


