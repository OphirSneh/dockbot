# Description
#   Basic standup bot, based on:
#   https://github.com/docker/bender
#   https://github.com/miyagawa/hubot-standup
#
# Commands:
#   hubot standup - starts a standup in the current channel
#   hubot cancel standup - stops a running standup
#   hubot next - passes on to the next person in a standup
#   hubot addme - adds you to the current standup
#
# Author:
#   bfirsh

module.exports = (robot) ->
  robot.hear /.+/, (msg) ->
    standup = robot.brain.data.standup?[msg.message.room]
    user = msg.message.user
    if standup and not standup.started and user not in standup.remaining
      standup.remaining.push msg.message.user

  robot.respond /(?:cancel|stop) standup *$/i, (msg) ->
    delete robot.brain.data.standup?[msg.message.room]
    msg.send "Standup cancelled"

  robot.respond /(start )?standup$/i, (msg) ->
    room  = msg.message.room
    if robot.brain.data.standup?[room]
      msg.send "The standup for ##{room} is in progress! Cancel it first with 'cancel standup'"
      return

    robot.brain.data.standup or= {}
    robot.brain.data.standup[room] = {
      start: null,
      remaining: []
      started: false,
    }

    getUsersForChannel room, (err, users) ->
      if err
        robot.logger.error "Error getting users: #{err}"
        users = ["channel"]

      who = users.map((user) -> "@#{user}").join(', ')
      msg.send "#{who} Starting a standup in 60 seconds! Please say something to join."

      setTimeout ->
        startStandup msg
      , 60000

  robot.respond /next$/i, (msg) ->
    standup = robot.brain.data.standup?[msg.message.room]
    return if not standup or not standup.started
    nextPerson msg

  robot.respond /add me$/i, (msg) ->
    return if not robot.brain.data.standup?[msg.message.room]
    user = msg.message.user
    standup = robot.brain.data.standup?[msg.message.room]
    if user not in standup.remaining
      standup.remaining.push user
    msg.send "@#{user.name}: You're in!"

  startStandup = (msg) ->
    return if not robot.brain.data.standup?[msg.message.room]
    room  = msg.message.room
    standup = robot.brain.data.standup[room]
    standup.started = true
    standup.start = new Date().getTime()
    who = standup.remaining.map((user) -> "@#{user.name}").join(', ')
    msg.send "Ok, let's start the standup: #{who}"
    nextPerson msg

  nextPerson = (msg) ->
    room = msg.message.room
    standup = robot.brain.data.standup[room]
    if standup.remaining.length == 0
      howlong = calcMinutes(new Date().getTime() - standup.start)
      msg.send "All done! Standup was #{howlong}."
      delete robot.brain.data.standup[room]
    else
      standup.current = standup.remaining.shift()
      msg.send "@#{standup.current.name}: You're up"

  getUsersForChannel = (channelName, callback) ->
    apiToken = process.env.HUBOT_SLACK_API_TOKEN
    return callback(new Error("No API key")) if !apiToken
    channel = robot.adapter.client.getChannelByName(channelName)
    return callback(new Error("Channel could not be found")) if !channel
    robot.logger.debug "Fetching channels.info for #{channel.id}"
    robot.http("https://slack.com/api/channels.info")
      .query({
        token: apiToken
        channel: channel.id
      })
      .get() (err, res, body) ->
        if err
          return callback(err)
        channel = JSON.parse(body)?.channel
        if !channel
          return callback(true)
        userIdToNameMapping (err, map) ->
          return callback(err) if err
          callback null, (map[member] for member in channel.members)

  userIdToNameMapping = (callback) ->
    getAllUsers (err, members) ->
      return callback(err) if err
      map = {}
      for member in members
        map[member.id] = member.name
      callback null, map

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


calcMinutes = (milliseconds) ->
  seconds = Math.floor(milliseconds / 1000)
  if seconds > 60
    minutes = Math.floor(seconds / 60)
    seconds = seconds % 60
    "#{minutes} minutes and #{seconds} seconds"
  else
    "#{seconds} seconds"
