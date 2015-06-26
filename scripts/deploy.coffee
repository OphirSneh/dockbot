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

  robot.respond /\bdeploy\b ?([\w .\-]+)*\/?([\w .\- .^\s]+)*:?([\w .\-]+)$/i, (msg) ->
  	namespace = msg.match[1]
    repo_name = msg.match[2]
    tag = msg.match[3]
    msg.send "#{repo} :: #{tag}"

    request.post('/url').send("{namespace: '#{namespace}'}").send("{repo_name: '#{repo_name}'}").send("{tag: '#{tag}'}").end (err, res) ->
  	if err
    	msg.send "#{err}"
  	else
    	msg.send "deploy successful"
  	return

