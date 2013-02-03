module.exports = function(grunt) {
  var isDebug = true
  var proc = require('child_process');

  if (isDebug) {
    coffeeBuildTasks = 'concat:coffee coffee:app lint copy:rawJS coffeeBuildOK'
  }
  else {
    coffeeBuildTasks = 'concat:coffee coffee:app lint min coffeeBuildOK'
  }

  grunt.initConfig({
    watch: {
      coffee: {
        files: ['<config:concat.coffee.src>'],
        tasks: coffeeBuildTasks
      },
      stylus: {
        files: ['<config:stylus.app.src>'],
        tasks: 'stylus stylusBuildOK'
      }
    },
    clean: {
      test: ['build']
    },
    concat: {
      coffee: {
        src: [
          'client/coffee/BaseController.coffee',
          'client/coffee/GitHubController.coffee',
          'client/coffee/AlertController.coffee',
          'client/coffee/App.coffee'
        ],
        dest: 'build/_temp_gitfav.coffee'
      }
    },
    coffee: {
      app: {
        src: 'build/_temp_gitfav.coffee',
        dest: 'build/_temp_gitfav.js'
      }
    },
    copy: {
      rawJS: {
        src: 'build/_temp_gitfav.js',
        dest: 'public/javascripts/gitfav.js'
      }
    },
    stylus: {
      app: {
        src: ['client/stylus/style.styl'],
        dest: 'public/stylesheets/style.css',
        options: { compress: true }
      }
    },
    lint: {
      files : [
        //'client/javascripts/script3.js'
      ]
    },
    min: {
      'public/javascripts/gitfav.js': [ 'build/_temp_gitfav.js' ]
    },
    uglify: {
      mangle: {
        defines: {
          DEBUG: ['name', 'true']
        }
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib');

  function notify (message) {
    proc.exec("growlnotify -t 'grunt.js' -m '" + message + "'");
    proc.exec("terminal-notifier -title 'grunt.js' -message '" + message + "'");
  }

  grunt.registerTask('coffeeBuildOK', 'done!', function(){
    var message = "Coffee compile finished!"
    notify(message);
  });

  grunt.registerTask('stylusBuildOK', 'done!', function(){
    var message = "Stylus compile finished!"
    notify(message);
  });

}