request = require 'request'
libxmljs = require("libxmljs")
Q = require 'q'
QQ = require 'qq'



getStoriesForIteration = (projectId, iteration, token) ->
  deferred = Q.defer()

  url = "http://www.pivotaltracker.com/services/v3/projects/#{projectId}/iterations/#{iteration}"
  console.log url
  request.get {url: url, headers: {'X-TrackerToken': token}}, (e,r, body) ->
    if e or r.statusCode != 200
      deferred.reject new Error("Could not fetch stories for iteration: #{iteration}: #{e}, #{r.statusCode}")
    else
      doc = libxmljs.parseXml body
      console.log 'reslving promise'
      deferred.resolve ({
        id: s.get('id').text()
        name: s.get('name').text()
      } for s in doc.find('//story'))
  return deferred.promise


getStoriesByFilter = (projectId, filter, token) ->
  deferred = Q.defer()

  request.get {url: "http://www.pivotaltracker.com/services/v3/projects/#{projectId}/stories", headers: {'X-TrackerToken': token}, qs: {filter: filter}}, (e,r, body) ->
    if e or r.statusCode != 200
      deferred.reject new Error('Could not fetch stories for filter: ' + filter)
    else
      doc = libxmljs.parseXml body
      deferred.resolve ({
        id: s.get('id').text()
        name: s.get('name').text()
      } for s in doc.find('//story'))
  return deferred.promise


exports.setup = (app) ->

  app.get '/:id/stories', (req, res) ->
    stories = {
      current: getStoriesForIteration(req.params.id, 'current', req.user.token)
      backlog: getStoriesForIteration req.params.id, 'backlog', req.user.token
      icebox: getStoriesByFilter req.params.id, 'state:unscheduled', req.user.token
    }
    console.log stories
    QQ.deep(stories).then (resolvedStories) ->
      console.log 'resolved: ' + JSON.stringify resolvedStories
      res.send resolvedStories
    , (err) -> 
      res.send 500, err.message
     

    
  app.get '/', (req, res) ->
    console.log req.user
    request.get {url: 'http://www.pivotaltracker.com/services/v3/projects', headers: {'X-TrackerToken': req.user.token}}, (e, r, body) ->
      if e
        console.log "e: #{JSON.stringify e}"
        return res.send 500, e
      if r.statusCode != 200
        return res.send 500, r.statusCode
      else
        doc = libxmljs.parseXml body
        return res.send ({
          id: p.get('id').text(),
          name: p.get('name').text(),
          scale: p.get('point_scale').text()
        } for p in doc.find('//project'))


