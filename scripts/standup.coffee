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
    standup = robot.brain.data.standup?[msg.message.user.room]
    user = msg.message.user
    if standup and not standup.started and user not in standup.remaining
      standup.remaining.push msg.message.user

  robot.respond /(?:cancel|stop) standup *$/i, (msg) ->
    delete robot.brain.data.standup?[msg.message.user.room]
    msg.send "Standup cancelled"

  robot.respond /(start )?standup$/i, (msg) ->
    room  = msg.message.user.room
    if robot.brain.data.standup?[room]
      msg.send "The standup for ##{room} is in progress! Cancel it first with 'cancel standup'"
      return

    robot.brain.data.standup or= {}
    robot.brain.data.standup[room] = {
      start: null,
      remaining: []
      started: false,
    }

    msg.send "<!channel> Please say something to be part of the standup (starting in 60 seconds)"

    setTimeout ->
      startStandup msg
    , 60000

  robot.respond /next$/i, (msg) ->
    standup = robot.brain.data.standup?[msg.message.user.room]
    return if not standup or not standup.started
    nextPerson msg

  robot.respond /add me$/i, (msg) ->
    return if not robot.brain.data.standup?[msg.message.user.room]
    user = msg.message.user
    standup = robot.brain.data.standup?[msg.message.user.room]
    if user not in standup.remaining
      standup.remaining.push user
    msg.send "#{user.name}: You're in!"

  startStandup = (msg) ->
    return if not robot.brain.data.standup?[msg.message.user.room]
    room  = msg.message.user.room
    standup = robot.brain.data.standup[room]
    standup.started = true
    standup.start = new Date().getTime()
    who = standup.remaining.map((user) -> user.name).join(', ')
    msg.send "Ok, let's start the standup: #{who}"
    nextPerson msg

  nextPerson = (msg) ->
    room = msg.message.user.room
    standup = robot.brain.data.standup[room]
    if standup.remaining.length == 0
      howlong = calcMinutes(new Date().getTime() - standup.start)
      msg.send "All done! Standup was #{howlong}."
      delete robot.brain.data.standup[room]
    else
      standup.current = standup.remaining.shift()
      msg.send "#{standup.current.name}: You're up"

calcMinutes = (milliseconds) ->
  seconds = Math.floor(milliseconds / 1000)
  if seconds > 60
    minutes = Math.floor(seconds / 60)
    seconds = seconds % 60
    "#{minutes} minutes and #{seconds} seconds"
  else
    "#{seconds} seconds"
