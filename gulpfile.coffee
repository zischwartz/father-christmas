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

# gulp.task 'javascript', ->
#   # set up the browserify instance on a task basis
#   b = browserify(
#     entries: './mirror.coffee'
#     debug: true
#     transform: [ coffeeify ])
#   b.bundle().pipe(source('mirror.js'))
#   .pipe(buffer())
#   # .pipe(sourcemaps.init(loadMaps: true)).pipe(uglify())
#   .on('error', plugins.util.log)
#   # .pipe(sourcemaps.write('./'))
#   .pipe gulp.dest('./dist/')

# same as above but better, delete above probs

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

aws_site = require './aws-site.coffee' 

try
  aws_config = JSON.parse(fs.readFileSync("./aws.json"));
catch err
  plugins.util.log plugins.util.colors.bgRed 'No AWS config found!'

publisher = plugins.awspublish.create(aws_config)
# headers = {'Cache-Control': 'max-age=315360000, no-transform, public'}; # 10 years
headers = {'Cache-Control': 'max-age=3600, no-transform, public'}; #  1 hour


# Delete every damn thing in a bucket. Use with care.
gulp.task "delete", ->
  gulp.src('./noexist/*')
  .pipe(publisher.sync())
  .pipe(plugins.awspublish.reporter())


# ## Publishing to S3
gulp.task 'publish', ->
  gulp.src('dist/**/**')
  .pipe(plugins.awspublish.gzip())
  .pipe(publisher.publish())
  .pipe(publisher.cache())
  .pipe(plugins.awspublish.reporter())

# Set up a bucket
gulp.task 'setup_bucket', ->
  aws_site.config aws_config
  aws_site.createBucket ->
    aws_site.putBucketPolicy ->
      aws_site.configureWebsite(aws_config.bucket)

# gulp.task 'cloudfront', ->
#   revAll = new plugins.revAll()
#   gulp.src('dist/**')
#       .pipe(revAll.revision())
#       .pipe(plugins.awspublish.gzip())
#       .pipe(publisher.publish(headers))
#       .pipe(publisher.cache())
#       .pipe(plugins.awspublish.reporter())
#       .pipe(plugins.cloudfront(aws_config))


