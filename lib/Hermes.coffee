_ = require 'underscore'
handlebars = require 'handlebars'
fs = require 'fs'
path = require 'path'
nodemailer = require "nodemailer"


getViews = (viewRoot, name) ->
  getView = (path) -> handlebars.compile fs.readFileSync path, 'utf8'
  getPath = (ext) -> path.resolve viewRoot, "#{name}#{ext}.handlebars"
  views = {}

  views.text = if fs.existsSync p = getPath '' then getView p
  else if fs.existsSync p = getPath '.text' then getView p

  views.html = getView p if fs.existsSync p = getPath '.html'

  views

class Mailer
  mainOnly: no

  constructor: (mailer, @_config, @_transport) ->
    if _.isFunction mailer
      @mainOnly = yes
      mailer = main : mailer

    if mailer.defaults?
      @defaults = mailer.defaults
      delete mailer.defaults
    else @defaults = {}

    if @defaults.data and @_config.defaults.data?
      _.defaults @defaults.data, @_config.defaults.data

    _.defaults @defaults, @_config.defaults

    @setMethod name, method for name, method of mailer
    return @main if @mainOnly

  setMethod: (name, method) ->
    views = getViews @_config.views, name

    @[name] = (args...) =>
      cb = if _.isFunction _.last args then args.pop() else ->
      that = mail: (message = {}) => @_mail views, message, cb
      method.apply that, args

  _mail: (views = {}, message = {}, cb = ->) ->
    if message.data? and @defaults.data?
      _.defaults message.data, @defaults.data

    _.defaults message, @defaults
    message.text = views.text message.data if views.text?
    message.html = views.html message.data if views.html?

    @_transport.sendMail message, cb

module.exports = class Hermes
  constructor: (@config, mailers) ->
    @createTransport()
    @addMailer name, mailer for name, mailer of mailers

  createTransport: ->
    @_transport = nodemailer.createTransport @config.transport.type, @config.transport

  addMailer: (name, mailer) ->
    config = _.clone @config
    config.views = path.resolve @config.views, name
    @[name] = new Mailer mailer, config, @_transport

  #send: ->
    # if msg.view passed then create template then memorize(by path)
    # body?
  close: -> @_transport.close()