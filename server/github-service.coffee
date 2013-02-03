class GitHubService

  request = require ("request")
  async = require("async")
  md = require("node-markdown").Markdown
  $ = require('cheerio')
  _ = require('underscore')
  querystring = require('querystring')
  GitHub = require("github")

  _DEBUG = 1

  IS_HTML_SCRAPING = 0

  MAX_STARRED_REPOS_PAGE = 0
  if _DEBUG
    MAX_STARRED_REPOS_PAGE = 1

  GITHUB_BASE_URL = "https://github.com"

  # githubKey
  if process.env.NODE_ENV is 'production'
    githubKey = require('../config/github-key.json')
  else
    githubKey = require('../config/github-dev-key.json')

  __clientId = githubKey.client_id
  __clientSecret = githubKey.client_secret

  #------------------------
  # url
  #------------------------
  urlForPath: (path) ->
    "#{GITHUB_BASE_URL}#{path}"

  authorizeUrl: (req) ->
    paramString = querystring.stringify({
      client_id: __clientId
    })

    paramString = querystring.stringify({
      client_id: __clientId || "",
      scopes: "",
      redirect_uri: "",
      state: "",
    })

    redirectUrl = @urlForPath("/login/oauth/authorize?#{paramString}")
    console.log("redirectUrl = " + redirectUrl);
    redirectUrl

  #------------------------
  # session
  #------------------------
  getAccessToken: (code, callback) =>
    console.log 'getAccessToken'

    if not code?
      callback("ERROR: no 'code'", null)
      return

    params = {
      client_id: __clientId
      client_secret: __clientSecret,
      code: code
    }

    console.log params

    request.post(@urlForPath("/login/oauth/access_token"), { form:params }, (err, res, body) =>
      console.log("getAccessToken err = " + err);
      console.log("getAccessToken body = " + body);

      if err?
        callback(err, null)
        return

      console.log("querystring.parse(body) = ");
      console.log(querystring.parse(body));

      token = querystring.parse(body).access_token

      console.log("access_token = ");
      console.log(token);

      if token?
        callback(null, token)
      else
        callback("ERROR: getAccessToken returned error body", null)
    )

  # class method
  getUserInfo: (token, callback) =>
    console.log "getUserInfo #{token}"

    # NOTE: to use getUserInfo as class method, don't use @github, create another instance
    github = new GitHub({
      version: "3.0.0"
    })
    github.authenticate({
      type: "oauth",
      token: token
    })

    github.user.get({}, (err, userInfo) ->
      console.log("userInfo =");
      console.log userInfo

      if err?
        callback(err, null)
        return

      callback(null, userInfo)
    )

  #------------------------
  # Initialize
  #------------------------
  constructor: (@userName, @token) ->
    console.log "new GitHubService(#{@userName},#{@token})"

    @github = new GitHub({
      version: "3.0.0"
    })
    @github.authenticate({
      type: "oauth",
      token: @token
    })

  #------------------------
  # APIs
  #------------------------
  getStarredRepos: (callback) ->
#    callback(null, [])

    console.log("getStarredRepos");

    @allRepos = []

    @_getStarredReposFromPageRecursively(1, (err, repos) ->

      for repo in repos
        GitHubService::_deleteUselessKeysForObject(repo)

#      console.log repos

      callback(err, repos)
    )

  # class method
  _deleteUselessKeysForObject: (obj) ->
    if not _.isObject(obj)
      return

    for key, val of obj
      if _.isObject(val)
        @_deleteUselessKeysForObject(val)
        continue
      else if _.isString(val)
        if val[0..21] is "https://api.github.com"
          delete obj[key]

  _getStarredReposFromPageRecursively: (page, callback) ->
    console.log "_getStarredReposFromPageRecursively"
    console.log "user = #{@userName}, page = #{page}"

    @github.repos.getWatchedFromUser({
      user: @userName,
      page: page,
      per_page: 100
    }
    (err, repos) =>
      if err?
        callback(err, @allRepos)
        return

      @allRepos = @allRepos.concat(repos)

      console.log("fetched repos.length = " + repos.length);
      console.log("@allRepos.length = " + @allRepos.length);

      console.log repos.meta

      hasNextPage = (repos.meta.link.indexOf('rel="next"') >= 0)

      if hasNextPage and (page < MAX_STARRED_REPOS_PAGE or MAX_STARRED_REPOS_PAGE == 0)
        @_getStarredReposFromPageRecursively(page+1, callback)
      else
        callback(null, @allRepos)
    )

  getReadmeImagesFromRepoFullNames: (repoFullNames, defaultBranchNames, callback) ->
    console.log "getReadmeImagesFromRepoFullNames"

    if IS_HTML_SCRAPING
      @scrapeReadmeImagesFromRepoFullNames(repoFullNames, callback)
      return

    async.map([0..repoFullNames.length-1], (i, callback) =>
      repoFullName = repoFullNames[i]
      defaultBranchName = defaultBranchNames[i]

      console.log "repoFullName = #{repoFullName} branch=#{defaultBranchName}"

      [userName, repoName] = repoFullName.split("/")

      ref = "heads/master"
      if defaultBranchName?
        ref = "heads/#{defaultBranchName}"

      async.waterfall([
        # 1. get sha1
        (callback) =>
#          console.log "get sha1"

          @github.gitdata.getReference(
            {
            user: userName,
            repo: repoName,
            ref: ref
            },
          (err, res) ->
            if err?
              callback(err, null)
            else
              callback(null, res.object.sha)
          )
        # 2. get tree
        (sha, callback) =>
#          console.log "get tree"

          @github.gitdata.getTree(
            {
            user: userName,
            repo: repoName,
            sha: sha,
            recursive: false
            },
          (err, res) ->
            if err?
              callback(err, null)
            else
              callback(null, res.tree)
          )
        # 3. get README
        (files, callback) =>
#          console.log "get README"

          readmeFile = null

          for file in files
            components = file.path.split(".")

            if components.length > 2
              continue

            if components[0].toUpperCase() == "README"
              readmeFile = file
              break

          if readmeFile
            @github.gitdata.getBlob(
              {
              user: userName,
              repo: repoName,
              sha: readmeFile.sha
              },
            (err, res) ->
              if err?
                callback(err, null)
              else
                encoded = res.content
                buf = new Buffer(encoded, 'base64')
                decoded = buf.toString()
                callback(null, decoded)
            )
          else
            callback("No README file.", null)
        # 4. convert from markdown to HTML
        (markdown, callback) ->
#          console.log "convert from markdown to HTML"

          html = md(markdown)
          if html?
            callback(null, html)
          else
            callback("Failed to convert markdown to HTML.", null)
        # 5. scrape img tag from HTML
        (html, callback) ->
#          console.log "scrape img tag from HTML"

          imageUrls = []
          $('img', html).each((index, elm) ->
            imageUrls.push(elm.attribs.src)
          )
          console.log imageUrls
          callback(null, imageUrls)
      ]
      (err, imgUrls) ->
#        console.log "async.waterfall callback"

        # always return result so that imageUrlsArray.length = repoIds.length
        if err?
          callback(null, [])
        else
          callback(null, imgUrls)
      )
    (err, imageUrlsArray) =>
      console.log "async.map callback"
      console.log imageUrlsArray

      callback(err, imageUrlsArray)
    )

  scrapeReadmeImagesFromRepoFullNames: (repoFullNames, callback) ->
    console.log "scrapeReadmeImagesFromRepoFullNames"

    async.mapSeries(repoFullNames, (repoFullName, callback) =>
      console.log "get README for #{repoFullName}"

      request({
        method: "GET"
        uri: "https://github.com/#{repoFullName}"
      }
      (error, response, html) ->
        console.log("statusCode = " + response.statusCode);

        imageUrls = []
        $('#readme', html).find('img').each((index, elem) ->
          imageUrls.push(elem.attribs.src)
        )

        console.log("imageUrls = ");
        console.log(imageUrls);
        console.log "----------"

        # never return error for array.length consistency
        callback(null, imageUrls)
      )
    (err, imageUrlsArray) =>
      callback(err, imageUrlsArray)
    )

module.exports = GitHubService