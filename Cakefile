{print}       = require 'util'
{exec} = require 'child_process'

if process.env.NODE_PATH
  process.env.NODE_PATH = "#{__dirname}:#{process.env.NODE_PATH}"
else
  process.env.NODE_PATH = "#{__dirname}"

task 'run', 'run the server', ->
  exec "coffee -c ./public/", (err, sout, serr) ->
    console.log "compiling..."
    print sout if sout?
    print serr if serr?
    exec "coffee app.cofee"
