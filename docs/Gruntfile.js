module.exports = function(grunt) {
  
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    exec: {
      build_sphinx: {
        cmd: 'python -msphinx -b html -a source build/html || python2 -msphinx -b html -a source build/html'
      }
    },
    connect: {
      server: {
        options: {
          port: 2106,
          base: './build/html',
          livereload: true
        }
      }
    },
    open: {
      dev: {
        path: 'http://localhost:2106'
      }
    },
    watch: {
      sphinx: {
        files: ['./source/**/*.rst', './source/**/*.py', './source/_static/*', './source/_templates/*'],
        tasks: ['exec:build_sphinx']
      },
      livereload: {
        files: ['./build/html/*'],
        options: { livereload: true }
      }
    }
  });
  
  grunt.loadNpmTasks('grunt-exec');
  grunt.loadNpmTasks('grunt-contrib-connect');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-open');
  
  grunt.registerTask('default', ['exec', 'connect', 'open', 'watch']);
};