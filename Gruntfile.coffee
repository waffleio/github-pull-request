module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-simple-mocha'

  grunt.registerTask 'default', ['coffee']

  grunt.registerTask 'test', ['simplemocha']

  grunt.initConfig

    watch:
      src:
        files: '**/*.coffee'
        tasks: ['coffee']

    coffee:
      src:
        expand: true
        cwd: 'src'
        src: ['**/*.coffee']
        dest: 'js'
        ext: '.js'

    simplemocha:
      options:
        compilers: ['coffee:coffee-script']
        timeout: 3000
        ignoreLeaks: false
        ui: 'bdd'
        reporter: 'dot'
      all:
        src: ['spec/**/*.coffee']

