
socket = io.connect('http://localhost:3000')

class PokerViewModel
  constructor: ->
    @projects = ko.observableArray []
    @selectedProject = ko.observable null

  getProjects: ->
    $.get('/projects/')
      .success( (data) => @projects(data))
      .error( (err) -> console.log 'error: ' + err)

  projectSelected: (project) =>
    projectModel = new PokerProject(project)
    @selectedProject(projectModel)
    projectModel.getStories()
    window.location = "#/project/#{project.id}"

  logout: ->
    console.log 'logging out...'
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
          @stories()[key] = for story in data[key]
            new PokerStory(@, story.name, story.id)
        @loaded(true)
      ).error( (err) => console.log err; @loaded true)

  onStorySelected: (story) =>
    if @selectedStory()?
      socket.emit 'unsubscribe', @selectedStory.wsRoomName()
    @selectedStory story
    socket.emit 'subscribe', story.wsRoomName()
    socket.removeAllListeners 'client_voted'
    socket.on 'client_voted', (vote) =>
      console.log "client voted: #{JSON.stringify vote}"
      obj = _.find(story.votes(), (v) -> _.isEqual(v, vote))
      if not obj?
        story.votes().push(vote)
      else
        obj.value = vote.value


class PokerStory
  constructor: (@up, @name, @id) ->
    @selectedValue = ko.observable 0
    @votes = ko.observableArray []
    @wsRoomName = ko.computed => "#{@up.id}/#{@id}"
    @votesRevealed = ko.observable false


  pointBtnClicked: (value) =>
    console.log 'PokerStory#pointBtnClicked'
    @selectedValue value
    socket.emit 'vote', {room: @wsRoomName(), value: value}

  revealVotes: =>
    console.log 'votes reveal!'
    @votesRevealed true

$ ->
  window.pokerModel = pokerModel = new PokerViewModel()
  ko.applyBindings pokerModel, $('#poker-main')[0]

  app = Sammy '#poker-main', ->

    @get '#/', ->
      pokerModel.getProjects()
      pokerModel.selectedProject(null)

    @get '#/project/:project_id', ->
      selectProject = =>
        projectId = @params.project_id
        project = _.find pokerModel.projects(), (p) -> p.id == projectId
        pokerModel.projectSelected project
      if pokerModel.projects().length == 0
        xhr = pokerModel.getProjects()
        xhr.success -> selectProject()
      else
        selectProject()

  app.run '#/'
