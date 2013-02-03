module.exports = (app) ->

  i18n = app.get('i18n')
  sharedRedisManager = app.get('sharedRedisManager')

  GithubService = require('../server/github-service')
  SessionManager = require('../server/session-manager')

  app.get('/', (req, res) ->
    console.log "#{req.method} #{req.url}"

    console.log("req.headers[\"accept-language\"] = " + req.headers["accept-language"]);
    console.log("i18n.getLocale = " + i18n.getLocale(req));
    console.log i18n

    sessionManager = new SessionManager(req.session)
    sessionManager.sharedRedisManager = sharedRedisManager

    console.log "isAuthed = " + sessionManager.isAuthed()

    console.log "render"

    lang = i18n.getLocale(req)
    localizeJSON = require("../locales/#{lang}")
    localize = JSON.stringify(localizeJSON)

    res.locals.lang = lang
    res.locals.isAuthed = sessionManager.isAuthed()
    res.locals.localize = localize

    if sessionManager.isAuthed()
      console.log "index.ejs"

      res.locals.userInfo = sessionManager.userInfo()
      res.render 'index.ejs'
    else
      console.log "login.ejs"

      res.locals.userInfo = null
      res.render 'login.ejs'
  )

  app.get('/login', (req, res) ->
    console.log "#{req.method} #{req.url}"

    sessionManager = new SessionManager(req.session)
    sessionManager.sharedRedisManager = sharedRedisManager

    if sessionManager.isAuthed()
      res.redirect('/')
    else
      res.redirect(GithubService::authorizeUrl(req))
  )

  app.get('/callback', (req, res) ->
    console.log "#{req.method} #{req.url}"

    sessionManager = new SessionManager(req.session)
    sessionManager.sharedRedisManager = sharedRedisManager

    if sessionManager.isAuthed() or not req.query.code?
      res.redirect('/')
    else
      sessionManager.getAccessTokenAndUserInfo(req.query.code, (err) ->
        if err?
          console.log err
          res.send(500)
          return

        res.redirect('/')
      )
  )

  app.get('/logout', (req, res) ->
    console.log "#{req.method} #{req.url}"

    sessionManager = new SessionManager(req.session)
    sessionManager.sharedRedisManager = sharedRedisManager

    sessionManager.clearAuth()

    res.redirect('/')
  )