request = require 'request'
libxmljs = require("libxmljs")
Q = require 'q'
QQ = require 'qq'
_ = require 'underscore'


PT_ROOT = 'http://www.pivotaltracker.com/services/v3'

getQ = (opts) ->
  deferred = Q.defer()
  request.get opts, (e, r, body) ->
    if e then return deferred.reject e
    if r.statusCode is not 200
      return deferred.reject new Error({code: r.statusCode, message: body})
    deferred.resolve body
  return deferred.promise


translatePTStory = (story) ->
  id: story.get('id').text()
  name: story.get('name').text()


getStoriesForIteration = (projectId, iteration, token) ->
  url = "#{PT_ROOT}/projects/#{projectId}/iterations/#{iteration}"
  getQ({url: url, headers: {'X-TrackerToken': token}})
    .then (body) ->
      doc = libxmljs.parseXml body
      return _.map doc.find('//story'), translatePTStory


getStoriesByFilter = (projectId, filter, token) ->
  getQ({
    url: "#{PT_ROOT}/projects/#{projectId}/stories"
    headers: {'X-TrackerToken': token}
    qs: {filter: filter}
  })
    .then (body) ->
      doc = libxmljs.parseXml body
      return _.map doc.find('//story'), translatePTStory


exports.setup = (app) ->

  app.get '/:id/stories', (req, res) ->
    stories = {
      current: getStoriesForIteration(req.params.id, 'current', req.user.token)
      backlog: getStoriesForIteration req.params.id, 'backlog', req.user.token
      icebox: getStoriesByFilter req.params.id, 'state:unscheduled', req.user.token
    }
    QQ.deep(stories)
      .then (resolvedStories) ->
        res.send resolvedStories
      .fail (err)->
        res.send 500, err.message
      .end()

  translatePTProject = (project) ->
    id: project.get('id').text()
    name: project.get('name').text()
    scale: project.get('point_scale').text()
     

  app.get '/:id', (req, res) ->
    getQ url: "#{PT_ROOT}/projects/#{req.params.id}",
         headers: {'X-TrackerToken': req.user.token}
      .then (body) ->
        doc = libxmljs.parseXml body
        res.send _.first _.map doc.find('//project'), translatePTProject
      .end()

    
  app.get '/', (req, res) ->
    getQ({url: "#{PT_ROOT}/projects", headers: {'X-TrackerToken': req.user.token}})
      .then (body) ->
        doc = libxmljs.parseXml body
        res.send _.map doc.find('//project'), translatePTProject
      .end()
