module.exports = class TestTransport
  constructor: (@options) ->

  sendMail: (msg, cb) ->
    @options.hermes?.emit 'testMessage', msg
    cb null, msg
