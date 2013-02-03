module.exports = (app) ->

  ALWAYS_FETCH = 0 # release = 0

  i18n = app.get('i18n')
  sharedRedisManager = app.get('sharedRedisManager')

  _ = require('underscore')

  RepoManager = require('../server/repo-manager')

  _filterAndRenderStarredReposJSON = (res, repos, language, requiresImage) ->
    console.log "_filterAndRenderStarredReposJSON"
    console.log("original repos.length = " + repos.length);

    RepoManager::filterRepos(repos, language, requiresImage, (err, repos) ->
      console.log("filtered repos.length = " + repos.length);

      res.charset = 'utf-8'
      res.contentType('json')
      res.send(repos)
    )

  app.get('/api/starred', (req, res) ->
    console.log "#{req.method} #{req.url}"

    requiresImage = req.query.image || false
    language = req.query.lang

    myId = req.session.oauth.userInfo.id

    repoManager = new RepoManager(
      req.session.oauth.userInfo.id
      req.session.oauth.userInfo.login
      req.session.oauth.token
    )
    repoManager.sharedRedisManager = sharedRedisManager

    repoManager.starredRepos((err, repos) ->
      if err? or not repos? or repos.length == 0
        repoManager.updateStarredRepos((err, repos) ->
          _filterAndRenderStarredReposJSON(res, repos, language, requiresImage)
        )
      else
        _filterAndRenderStarredReposJSON(res, repos, language, requiresImage)
    )
  )
