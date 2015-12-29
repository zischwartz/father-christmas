$ = require "jquery"
node_emoji = require "node-emoji"

d3 = require "d3"

navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia;

window.requestAnimationFrame = window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame

class Mirror 
  constructor: (sel="#main")->
    @el = $(sel)
    @video_to_canvas_ratio = 10 # sampling of <video> to our hidden canvas (which is 1/n the size of the video)
    @mirror_ratio = 20

    [width, height] = [$(window).width(), $(window).height()]

    @hidden= $("<div style='display:none'>")

    @video = $ "<video autoplay=''></video>"
    @video_canvas = $("<canvas id='video_canvas'></canvas>")
    @vid_can_ctx = @video_canvas.get(0).getContext('2d')
    @mirror = $ "<canvas id='mirror' width='#{width}' height='#{height}'></canvas>"
    @m_ctx = @mirror.get(0).getContext('2d')

    @el.append @hidden
    @hidden.append @video
    @hidden.append @video_canvas
    
    @el.append @mirror

    @scale = d3.scale.quantize().domain([0, 255]).range([4, 3, 2, 1, 0])

    @start()

  start: ->
    if navigator.getUserMedia
      navigator.getUserMedia {audio: false, video: true}, ((stream) =>
        url = window.URL or window.webkitURL
        src = if navigator.getUserMedia then url.createObjectURL(stream) else stream
        @video.attr('src', src )
        # and finally
        @animate()
      ), (error) ->
        console.error 'Video capture error: ', error.code

  animate: =>
    @get_video_data()
    requestAnimationFrame @animate


  get_video_data: ->
    vid_node = @video.get(0)
    # until it's done intializing, these will be 0
    if vid_node["videoWidth"] and vid_node["videoHeight"]
      [dest_w, dest_h] = [vid_node["videoWidth"]/ @video_to_canvas_ratio, vid_node["videoHeight"]/ @video_to_canvas_ratio]
      @vid_can_ctx.drawImage @video.get(0), 0, 0, vid_node["videoWidth"], vid_node["videoHeight"], 0, 0, dest_w, dest_h
      image_data = @vid_can_ctx.getImageData  0, 0, dest_w, dest_h
      @render(image_data)

  draw: (x,y,r,g,b)->
    luma = (r+g+b)/3
    @m_ctx.fillStyle = "rgb(#{luma},#{luma},#{luma})"
    @m_ctx.fillRect(x*@mirror_ratio+@x_offset,y*@mirror_ratio,@mirror_ratio,@mirror_ratio)

    v = @scale (r+g+b)/3
    image = document.getElementById("i#{v}")
    @m_ctx.drawImage(image, x*@mirror_ratio+@x_offset, y*@mirror_ratio, @mirror_ratio, @mirror_ratio)

  render: (image_data)=>
    [mirror_width, mirror_height] = [ @mirror.width(), @mirror.height() ]
    @m_ctx.clearRect 0, 0, mirror_width, mirror_height
    
    data = image_data.data

    @x_offset = (mirror_width-image_data.width*@mirror_ratio)/2

    x = y = 0
    while y < image_data.height
      x = 0
      while x < image_data.width
        [x, y] = [Math.floor(x), Math.floor(y)]
        pos = ((image_data.width * y) + x) * 4
        [r,g,b] = [ data[pos], data[pos+1], data[pos+2]]
        @draw(x,y,r,g,b)
        x+=1
      y+=1









$ ->
  app = new Mirror
  window.app = app