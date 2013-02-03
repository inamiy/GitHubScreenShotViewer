http = require('http')
util = require('util')
fs = require('fs')
i18n = require("i18n")
winston = require('winston')
express = require('express')
RedisStore = require('connect-redis')(express)
argv = require('optimist').argv

routes = require('./routes')
RedisManager = require('./server/redis-manager')

app = express()

#----------------------------------------
# argv
#----------------------------------------
port = process.env.PORT || argv.p || 3000
redisId = argv.redis || 0

#----------------------------------------
# sharedRedisManager
# FIXME: how can I make singleton in CoffeeScript...?
#----------------------------------------
sharedRedisManager = new RedisManager(redisId)

#----------------------------------------
# locale
# https://github.com/mashpie/i18n-node
#----------------------------------------
i18n.configure({
  # setup some locales - other locales default to en silently
  locales:['ja', 'en'],

  extension: '.json',

  # where to register __() and __n() to, might be "global" if you know what you are doing
  register: global
})

#----------------------------------------
# Winston
# http://codezine.jp/article/detail/6530
#----------------------------------------
if process.env.NODE_ENV != 'production'

#  logDir = './log'
#
#  if not fs.existsSync(logDir)
#    fs.mkdirSync(logDir, 0o777)
#
#  # output to file
#  winston.add(winston.transports.File, {
#    filename : "#{logDir}/app.log"
#    timestamp: false
#    json: false
#  })

  # change console output
  winston.remove(winston.transports.Console)
  winston.add(winston.transports.Console, {
    timestamp: false
    colorize : true
    level    : 'silly'
  })
  console.log = (d) ->
    winston.debug(util.inspect(d))
  console.info = (d) ->
    winston.info(util.inspect(d))

  console.log("Development Mode")
else
  console.log("Production Mode")

console.log("redisId = #{redisId}")

#----------------------------------------
# Express
#----------------------------------------
app.locals({
  title: 'GitHub ScreenShot Viewer'
  author: 'Yasuhiro Inami'
  email: 'inamiy@gmail.com'
  __i: i18n.__
  __n: i18n.__n
})

app.configure( ->
  app.set('port', port)
  app.set('views', __dirname + '/views')
  app.set('view engine', 'ejs')
  app.set('i18n', i18n)
  app.set('sharedRedisManager', sharedRedisManager)

  app.use(express.logger('dev'))
  app.use(express.bodyParser())
  app.use(express.methodOverride())
  app.use(express.cookieParser("something secret"))
  app.use(express.session({
    secret: "something secret",
    cookie: {maxAge: 1000 * 60 * 60 * 24 * 7}, # 1 week
    store: new RedisStore({
      host: "127.0.0.1",
      port: 6379,
      db: redisId
    })
  }))

  #using 'accept-language' header to guess language settings
  app.use(i18n.init)
  app.use(app.router)

  routes(app)

  app.use(express.static(__dirname + '/public'))
)

app.configure('development', ->
  # app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))
  app.use(express.errorHandler())
)

http.createServer(app).listen(app.get('port'), ->
  console.log("Express server listening on port " + app.get('port'))
)

