Robot                                   = require '../robot'
Adapter                                 = require '../adapter'
{TextMessage,EnterMessage,LeaveMessage} = require '../message'

DDPClient = require("/home/cjb/meteor/node-ddp-client/lib/ddp-client")

BOT_NAME = "codexbot"

class Blackboardbot extends Adapter
  run: ->
    self = @
    @robot.name = BOT_NAME
    @ready = false

    initial_cb = ->
      @ready = true
      # XXX 'deleteNick' needs a Nicks id, not a name.  Could use
      # call "getByName", [optional_type: "nicks", name: BOT_NAME]
      # to fetch id, then delete it if exists.  Is that worth it?
      self.ddpclient.call "deleteNick", ["name": BOT_NAME]
      self.ddpclient.call "newNick", ["name": BOT_NAME, "tags": {}]
      self.ddpclient.call "setPresence", [
        nick: BOT_NAME
        room_name: "general/0"
        present: true
        foreground: true
      ]
      self.emit 'connected'

    update_cb = (data) ->
      if @ready
        if data.set.nick isnt BOT_NAME and data.set.system is false and data.set.nick isnt ""
          self.receive new TextMessage data.set.nick, data.set.body

    # Connect to Meteor
    self.ddpclient = new DDPClient(host: "localhost", port: 3000)
    @robot.ddpclient = self.ddpclient
    self.ddpclient.connect ->
      console.log "connected!"
      # xxx should also subscribe to 'paged-messages'
      self.ddpclient.subscribe "paged-messages-nick", [BOT_NAME, "general/0", 0], initial_cb, update_cb, "messages"

  send: (user, strings...) ->
    self = @
    self.ddpclient.call "newMessage", [
      nick: BOT_NAME
      body: "#{user}: #{strings}"
    ]

  reply: (user, strings...) ->
    self = @
    @send user, strings

  ddp_call: (method, args) ->
    self = @
    self.ddpclient.call method, args

exports.use = (robot) ->
  new Blackboardbot robot
