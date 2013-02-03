(function() {
  var AlertController, BaseController, GitHubController,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  BaseController = (function() {

    function BaseController() {
      this.alertController = new AlertController;
    }

    return BaseController;

  })();

  GitHubController = (function(_super) {

    __extends(GitHubController, _super);

    GitHubController.prototype.baseUrl = "https://github.com";

    function GitHubController() {
      var _this = this;
      GitHubController.__super__.constructor.apply(this, arguments);
      this.$ul = $('#repo-ul');
      this.$searchAllButton = $('#search-all');
      this.$searchImageButton = $('#search-image');
      this.$repoBadge = $('#repo-badge');
      this.language = null;
      this.requiresImage = false;
      this.$searchAllButton.on('click', function(ev) {
        ev.preventDefault();
        $(".slides").slides("destroy");
        return _this.searchAll(function() {});
      });
      this.$searchImageButton.on('click', function(ev) {
        ev.preventDefault();
        $(".slides").slides("destroy");
        return _this.searchImage(function() {});
      });
      $('a.language').on('click', function(ev) {
        var $lang;
        ev.preventDefault();
        $lang = $(ev.target);
        $lang.parent().parent().children().removeClass('active');
        $lang.parent().addClass('active');
        _this.language = ev.target.hash.substr(1);
        if (_this.language.length === 0) {
          _this.language = null;
        }
        console.log("@language = " + _this.language);
        return _this.getStarredRepos(function() {});
      });
    }

    GitHubController.prototype.updateRepoBadge = function(count) {
      console.log("updateRepoBadge = " + count);
      this.$repoBadge.css('visibility', 'visible');
      return this.$repoBadge.text("" + count + " Repos");
    };

    GitHubController.prototype.searchAll = function(callback) {
      var _this = this;
      console.log("searchAll");
      this.$ul.empty();
      this.$searchAllButton.addClass('active');
      this.$searchImageButton.removeClass('active');
      this.requiresImage = false;
      return this.getStarredRepos(function(err, repos) {
        return callback(err, repos);
      });
    };

    GitHubController.prototype.searchImage = function(callback) {
      console.log("searchImage");
      this.$ul.empty();
      this.$searchAllButton.removeClass('active');
      this.$searchImageButton.addClass('active');
      this.requiresImage = true;
      return this.getStarredRepos(function(err, repos) {
        return callback(err, repos);
      });
    };

    GitHubController.prototype.getStarredRepos = function(callback) {
      var imageParam, langParam, url,
        _this = this;
      url = null;
      langParam = "";
      imageParam = "";
      if (this.language != null) {
        langParam = "&lang=" + this.language;
      }
      if (this.requiresImage) {
        imageParam = "&image=1";
      }
      url = "/api/starred?" + langParam + imageParam;
      console.log("GET " + url);
      return $.get(url, function(data) {
        var displayCurrentPage, repo, repos, _i, _len;
        repos = data;
        console.log(repos);
        _this.$ul.empty();
        for (_i = 0, _len = repos.length; _i < _len; _i++) {
          repo = repos[_i];
          _this.$ul.append(_this._$repoLi(repo));
        }
        displayCurrentPage = function($slide, current) {
          var $displayControl, $thumbnailDiv;
          console.log("displayCurrentPage");
          $thumbnailDiv = $slide.parent();
          $displayControl = $(".current_slide", $thumbnailDiv);
          if ($displayControl.length > 0) {
            return $displayControl.text(current + " of " + $slide.slides("status", "total"));
          } else {
            return console.log("ERROR: no $displayControl");
          }
        };
        $(".slides").each(function(index) {
          var $slide,
            _this = this;
          $slide = $(this);
          $slide.slides({
            width: 290,
            height: 200,
            pagination: false,
            slide: {
              interval: 300
            },
            navigateEnd: function(current) {
              return displayCurrentPage($slide, current);
            },
            loaded: function() {
              console.log("slide loaded");
              return displayCurrentPage($slide, 1);
            }
          });
          if ($slide.children().length > 1) {
            return displayCurrentPage($slide, 1);
          }
        });
        _this.updateRepoBadge(repos.length);
        if (callback) {
          return callback(null, repos);
        }
      }).error(function(err) {
        if (callback) {
          return callback(err, null);
        }
      });
    };

    GitHubController.prototype._$repoLi = function(repo) {
      var i, imageObj, imageObjs, repoName, template, userName, _i, _ref, _ref1;
      if (!(repo != null)) {
        return "";
      }
      imageObjs = [];
      if ($.isArray(repo.x_imageUrls)) {
        for (i = _i = 0, _ref = repo.x_imageUrls.length - 1; _i <= _ref; i = _i += 1) {
          if (repo.x_imageUrls[i].length === 0) {
            continue;
          }
          imageObj = {
            imageUrl: repo.x_imageUrls[i]
          };
          imageObjs.push(imageObj);
        }
      }
      _ref1 = repo.full_name.split("/"), userName = _ref1[0], repoName = _ref1[1];
      template = ich["repo-li-template"]({
        fullName: repo.fullName,
        userName: userName,
        repoName: repoName,
        ownerLogin: repo.owner.login,
        ownerUrl: "" + this.baseUrl + "/" + repo.owner.login,
        ownerAvatarUrl: repo.owner.avatar_url,
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
        forkUrl: repo.html_url + "/network"
      });
      return template;
    };

    return GitHubController;

  })(BaseController);

  AlertController = (function() {

    function AlertController() {
      this.$alert = $('.alert');
      this.$alertMessage = $('.message', this.$alert);
    }

    AlertController.prototype.showMessage = function(message) {
      this.$alert.removeClass('alert-error');
      this.$alert.removeClass('alert-success');
      this.$alertMessage.html("<strong>" + message + "</strong>");
      return this.$alert.fadeIn('fast');
    };

    AlertController.prototype.hideMessage = function() {
      return this.$alert.fadeOut('fast');
    };

    AlertController.prototype.showSuccessMessage = function(message) {
      var _this = this;
      this.$alert.removeClass('alert-error');
      this.$alert.addClass('alert-success');
      this.$alertMessage.html("<strong>" + message + "</strong>");
      return this.$alert.fadeIn('fast', function() {
        return setTimeout(function() {
          return _this.$alert.fadeOut();
        }, 2000);
      });
    };

    AlertController.prototype.showErrorMessage = function(message) {
      var _this = this;
      this.$alert.removeClass('alert-success');
      this.$alert.addClass('alert-error');
      this.$alertMessage.html("<strong>" + message + "</strong>");
      return this.$alert.fadeIn('fast', function() {
        return setTimeout(function() {
          return _this.$alert.fadeOut();
        }, 2000);
      });
    };

    return AlertController;

  })();

  $(function() {
    var $window, githubController;
    console.log("jQuery ready");
    $window = $(window);
    githubController = new GitHubController;
    return githubController.searchAll(function() {});
  });

}).call(this);
