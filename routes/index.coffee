module.exports = (app) ->
  require('./page')(app)
  require('./api')(app)

