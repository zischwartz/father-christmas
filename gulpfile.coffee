gulp = require 'gulp'
fs = require 'fs'

browserify = require 'browserify'
coffeeify = require 'coffeeify'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer' 

watchify = require('watchify')
assign = require('lodash.assign')

# sourcemaps = require('gulp-sourcemaps')

onError = (err) ->
  console.log(err.message)
  console.log(err.stack)
  this.emit('end')


# `gulp-load-plugins` loads all the modules in your `package.json` that begin with `gulp-` converting  dashes to camelcase, e.g. `'gulp-front-matter'` becomes `plugins.frontMatter`
gulpLoadPlugins = require 'gulp-load-plugins'
plugins = gulpLoadPlugins()

style_glob = ["*.less"]

gulp.task "less", ->
  gulp.src(style_glob).pipe(plugins.watch())
  .pipe(plugins.less()).pipe(plugins.continuousConcat('style.css'))
  .pipe(gulp.dest("./dist")).pipe(plugins.connect.reload())

bundle = ->
  b.bundle().on('error', plugins.util.log.bind(plugins.util, 'Browserify Error')).pipe(source('bundle.js')).pipe(buffer())
  # .pipe(sourcemaps.init(loadMaps: true)).pipe(sourcemaps.write('./'))
  .pipe gulp.dest('./dist')
  .pipe plugins.connect.reload()

# add custom browserify options here
customOpts = 
  entries: [ './mirror.coffee' ]
  debug: true
  transform: [ coffeeify ]

opts = assign({}, watchify.args, customOpts)
b = watchify(browserify(opts))
# add transformations here
# i.e. b.transform(coffeeify);
gulp.task 'js', bundle
# so you can run `gulp js` to build the file
b.on 'update', bundle
# on any dep update, runs the bundler
b.on 'log', plugins.util.log


gulp.task 'connect', ->
  plugins.connect.server
    root: './'
    port: 8882
    livereload:
      port: 35735

gulp.task 'default', ['js', 'connect', 'less']
