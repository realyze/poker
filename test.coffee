agent = require 'superagent'
agent.get('https://www.pivotaltracker.com/services/v3/tokens/active').auth('tomas@salsitasoft.com', 'Pink elephant remover').end (res)->console.log res.text; console.log res.status; console.log res.type; console.log JSON.stringify (k for k of res); console.log res
