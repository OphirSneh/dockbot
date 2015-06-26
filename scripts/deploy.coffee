# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md

module.exports = (robot) ->

  request = require('superagent')

  robot.respond /\bdeploy\b ?([^\s .\-]+)\?* :?([^\s .\-]+)\?*$/i, (msg) ->
    repo = msg.match[1]
    tag = msg.match[2]
    msg.send "#{repo} :: #{tag}"

    request.post('/url').send("{repo: '#{repo}'}").send("{tag: '#{tag}'}").end (err, res) ->
  	if err
    	msg.send "#{err}"
  	else
    	msg.send "deploy successful"
  	return

