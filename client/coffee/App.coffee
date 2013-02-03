$(->
  console.log "jQuery ready"

  $window = $(window)

  githubController = new GitHubController
  githubController.searchAll(->)
)