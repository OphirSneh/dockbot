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

  get_username = (response) ->
    "@#{response.message.user.name}"

  robot.hear /@?([\w .\-]+)\?* (\bkrilling it\b|\+\+)/i, (msg) ->
    username = msg.match[1]
    userExists username, (exists) ->
      if exists
        currentUser = get_username(msg).slice(1)
        if currentUser == username
          msg.send "_pats on back_"
        else
          robot.brain.set("#{username}_points",
            (robot.brain.get("#{username}_points") || 0) + 1
          )
          points = robot.brain.get("#{username}_points") || 0
          msg.send "#{currentUser} just gave #{username} a krill: total #{points}"
      else
        msg.send "No user '#{username}' found"

  robot.hear /@?([\w .\-]+)\?* (\bdropped the krill\b|\-\-)/i, (msg) ->
    username = msg.match[1]
    userExists username, (exists) ->
      if exists
        points = robot.brain.get("#{username}_points") || 0
        currentUser = get_username(msg).slice(1)
        if currentUser == username
          msg.send "why do you hate yourself?"
        else
          if points <=0
            msg.send "#{username} doesn't have any points"
          else
            robot.brain.set("#{username}_points",
              (robot.brain.get("#{username}_points") || 0) - 1
            )
            points = robot.brain.get("#{username}_points") || 0
            msg.send "#{currentUser} just removed a krill from #{username}: total #{points}"
      else
        msg.send "No user '#{username}' found"

  robot.hear /@?([\w .\-]+)\?* \bkrill count\b/i, (msg) ->
    username = msg.match[1]
    userExists username, (exists) ->
      if exists
        points = robot.brain.get("#{username}_points") || 0
        msg.send "#{username} has #{points} total krill"
      else
        msg.send "No user '#{username}' found"

  userExists = (username, cb) ->
    console.log('username:' + username)
    exists = false
    getAllUsers (err, members) ->
      console.log('1'+ exists)
      exists = false if err
      exists = nameInObject(member, username, exists) for member in members
      console.log('2'+ exists)
      cb exists

  nameInObject = (object, name, exists) ->
    return true if object.name == name
    return exists

  getAllUsers = (callback) ->
    apiToken = process.env.HUBOT_SLACK_API_TOKEN
    return callback(new Error("No API key")) if !apiToken
    robot.logger.debug "Fetching users.list"
    robot.http("https://slack.com/api/users.list")
    .query(token: apiToken)
    .get() (err, res, body) ->
      if err
        return callback(err)
      callback null, JSON.parse(body)?.members
