class GitHubController extends BaseController

  baseUrl: "https://github.com"

  constructor: ->
    super

    @$ul = $('#repo-ul')
    @$searchAllButton = $('#search-all')
    @$searchImageButton = $('#search-image')
    @$repoBadge = $('#repo-badge')

    @language = null
    @requiresImage = false

    @$searchAllButton.on('click', (ev) =>
      ev.preventDefault()

      $(".slides").slides("destroy");
      @searchAll(->)
    )

    @$searchImageButton.on('click', (ev) =>
      ev.preventDefault()

      $(".slides").slides("destroy");
      @searchImage(->)
    )

    $('a.language').on('click', (ev) =>
      ev.preventDefault()

      $lang = $(ev.target)
      $lang.parent().parent().children().removeClass('active')
      $lang.parent().addClass('active')

#      @language = $lang.text()
      @language = ev.target.hash.substr(1)

      if @language.length == 0
        @language = null

      console.log("@language = " + @language);

      @getStarredRepos(->)

    )

  updateRepoBadge: (count) ->
    console.log "updateRepoBadge = #{count}"
    @$repoBadge.css('visibility', 'visible')
    @$repoBadge.text("#{count} Repos")

  searchAll: (callback) ->
    console.log("searchAll");
    @$ul.empty()

    @$searchAllButton.addClass('active')
    @$searchImageButton.removeClass('active')

    @requiresImage = false

    @getStarredRepos((err, repos) =>
      callback(err, repos)
    )

  searchImage: (callback) ->
    console.log("searchImage");
    @$ul.empty()

    @$searchAllButton.removeClass('active')
    @$searchImageButton.addClass('active')

    @requiresImage = true

    @getStarredRepos((err, repos) ->
      callback(err, repos)
    )

  getStarredRepos: (callback) ->
    url = null
    langParam = ""
    imageParam = ""

    if @language?
      langParam = "&lang=#{@language}"

    if @requiresImage
      imageParam = "&image=1"

    # FIXME: tell me the easiest way to create client-side querystring...
    url = "/api/starred?" + langParam + imageParam

    console.log "GET #{url}"

    $.get(url, (data) =>
      repos = data
      console.log repos

      @$ul.empty()
      for repo in repos
        @$ul.append(@_$repoLi(repo))

      # function
      displayCurrentPage = ($slide, current) ->
        console.log "displayCurrentPage"
        $thumbnailDiv = $slide.parent()
        $displayControl = $(".current_slide", $thumbnailDiv)
        if $displayControl.length > 0
          $displayControl.text(current + " of " + $slide.slides("status","total"))
        else
          console.log "ERROR: no $displayControl"

      # https://github.com/nathansearles/Slides/
      $(".slides").each((index)->
        $slide = $(this)

        $slide.slides(
          width: 290,
          height: 200,
          pagination: false,
          slide: {
            interval: 300
          }
          navigateEnd: (current) =>
            displayCurrentPage($slide, current)
          loaded: =>
            # NOTE: never called
            console.log "slide loaded"
            displayCurrentPage($slide, 1)
        )

        # workaround for loaded not being called
        if $slide.children().length > 1
          displayCurrentPage($slide, 1)
      )

      @updateRepoBadge(repos.length)

      if callback
        callback(null, repos)

    ).error((err) ->
      if callback
        callback(err, null)
    )

  _$repoLi: (repo) ->
    if not repo?
      return ""

    # mustache hash-loop
    # http://mustache.github.com/mustache.5.html
    imageObjs = []
    if $.isArray(repo.x_imageUrls)
      for i in [0..repo.x_imageUrls.length-1] by 1
        # skip empty
        if repo.x_imageUrls[i].length == 0
          continue

        imageObj = { imageUrl:repo.x_imageUrls[i] }
        imageObjs.push(imageObj)

    [userName, repoName] = repo.full_name.split("/")

    template = ich["repo-li-template"]({
      fullName:  repo.fullName,
      userName:  userName,
      repoName:  repoName,
      ownerLogin:  repo.owner.login,
      ownerUrl: "#{@baseUrl}/#{repo.owner.login}",
      ownerAvatarUrl:  repo.owner.avatar_url,
      watchers: repo.watchers,
      forks: repo.forks,
      openIssues: repo.open_issues,
      homepage: repo.homepage,
      createdAt: repo.created_at,
      pushedAt: moment(repo.pushed_at).fromNow(),
      updatedAt: repo.updated_at,
      htmlUrl: repo.html_url,
      cloneUrl: repo.clone_url,
      gitUrl: repo.git_url,
      sshUrl: repo.ssh_url,
      language: repo.language,
      description: repo.description,
      imageUrls: imageObjs,
      starUrl: repo.html_url + "/stargazers",
      forkUrl: repo.html_url + "/network",
    })

    template