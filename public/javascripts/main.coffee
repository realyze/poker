socket = io.connect('http://localhost:3000');


class PokerViewModel
  constructor: ->
    @projects = ko.observableArray []
    @selectedProject = ko.observable null

  getProjects: ->
    $.get('/projects/')
      .success( (data) => console.log data; @projects(data))
      .error( -> console.log 'error')

  projectSelected: (project) =>
    projectModel = new PokerProject(project)
    @selectedProject(projectModel)
    projectModel.getStories()

  logout: ->
    window.location = '/logout'


class PokerProject
  constructor: (project) ->
    @loaded = ko.observable false
    @id = project.id
    @stories = ko.observable {}
    @scale = ko.observable project.scale.split(',')
    @selectedStory= ko.observable null

  getStories: ->
    console.log "PokerProject#getStories"
    $.get("/projects/#{@id}/stories")
      .success((data) => 
        for own key of data
          @stories()[key] = (new PokerStory(@, story.name, story.id) for story in data[key])
        @loaded(true)
      ).error( (err) => console.log err; @loaded true)

  onStorySelected: (story) =>
    console.log "story selected"
    @selectedStory story
    room = "#{@id}/#{story.id}"
    socket.emit 'unsubscribe', room
    socket.emit 'subscribe', room

class PokerStory
  constructor: (@up, @name, @id) ->
    @selectedValue = ko.observable 0
    @scores = ko.observable {}

  pointBtnClicked: (value) =>
    @selectedValue value
    room = "#{@up.id}/#{@id}"
    socket.emit 'vote', {room: room, score: value}
    socket.on 'score', (score) ->
      console.log 'score: ' + JSON.stringify score

$ ->
  pokerModel = new PokerViewModel()
  ko.applyBindings pokerModel, $('#poker-main')[0]
  pokerModel.getProjects()
