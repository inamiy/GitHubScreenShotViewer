class RepoManager

  request = require ("request")
  async = require("async")
  $ = require('cheerio')
  _ = require('underscore')

  GitHubService = require("./github-service")

  # limit display num
  _DEBUG = 0

  constructor: (@userId, @userName, @token) ->
    console.log "new RepoManager(#{@userId},#{@userName},#{@token})"

    @githubService = new GitHubService(@userName, @token)
    @sharedRedisManager = null

  starredRepos: (callback) ->
    console.log "starredRepos"

    @sharedRedisManager.starredReposForUserId(@userId, (err, repos) ->
      if err?
        callback(err, null)
        return

      if _DEBUG
        repos = repos[0..100]

      callback(null, repos)
    )

  updateStarredRepos: (callback) ->
    console.log("updateStarredRepos");

    @githubService.getStarredRepos((err, repos) =>
      console.log "did getStarredRepos (repos.length = #{repos.length})"

      if err?
        callback(err, null)
        return

      # sort starred repos
      repos = _.sortBy(repos, (repo) ->
        repo.pushed_at
      ).reverse() # DESC

      #
      # TODO: only update staled repos
      #

#      repoFullNames = _.map(repos, (repo) ->
#        repo.full_name
#      )
      repoFullNames = []
      defaultBranchNames = []
      for repo in repos
        repoFullNames.push(repo.full_name)
        defaultBranchNames.push(repo.default_branch)

      console.log("repoFullNames = ");
      console.log(repoFullNames);

      @githubService.getReadmeImagesFromRepoFullNames(repoFullNames, defaultBranchNames, (err, imageUrlsArray) =>
        if err?
          callback(err, null)
          return

        console.log imageUrlsArray

        # add extra keys to original repos-json (prefix="x_")
        for i in [0..repos.length-1] by 1
          repos[i].x_imageUrls = imageUrlsArray[i]
          repos[i].x_updated = JSON.stringify(new Date())

        # write in redis
        @sharedRedisManager.setStarredReposForUserId(@userId, repos, (err, res) ->
          if err?
            callback(err, null)
            return

          callback(null, repos)
        )
      )
    )

  filterRepos: (repos, language, requiresImage, callback) ->
    for i in [0..repos.length-1] by 1

      # filter invalid image url
      repos[i].x_imageUrls = _.reject(repos[i].x_imageUrls, (x_imageUrl) ->

        # TODO: create blacklist
        shouldFilter = /(travis|paypal|flattr|creativecommons)/i.test(x_imageUrl)

        console.log("test x_imageUrl = #{x_imageUrl} (filter=#{shouldFilter})");
        return shouldFilter
      )

      if requiresImage
#        console.log("repos[#{i}] = ")
#        console.log(repos[i]);

        if not repos[i].x_imageUrls
          delete repos[i] # null-ify
          continue

        if repos[i].x_imageUrls.length == 0 or repos[i].x_imageUrls[0] == ""
          delete repos[i] # null-ify

    # remove all nulls
    repos = _.reject(repos, (repo) ->
      if repo is null
        return true

      if language?
        if not repo.language? or language.toLowerCase() isnt repo.language.toLowerCase()
          return true

      return false
    )

    callback(null, repos)

module.exports = RepoManager