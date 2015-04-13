require 'sinatra'
require 'uuid'
require 'dropbox_sdk'
require 'pry'

# Get your app key and secret from the Dropbox developer website
APP_KEY = 'tde962n2ap70xcs'
APP_SECRET = '3isv4rd0xkhf1hq'
client = DropboxClient.new('HF7_1tzX7iAAAAAAAAAABSt1yx6Z1z206UAYHoPDi50ZpxBg7wn8PLD_xkxyTrYl')
puts "linked account:", client.account_info().inspect

get "/" do
  @uuid = UUID.generate
  erb :index
end

post "/upload/:uuid" do
  uuid = params[:uuid]
  puts params.inspect
  #video
  video_type = params['video'][:type].split("/").last

  File.open("uploads/#{uuid}.#{video_type}", "w") do |f|
    f.write(params['video'][:tempfile].read)
  end

  if (params[:isFirefox] == "false")
    #audio
    audio_type = params['audio'][:type].split("/").last

    File.open("uploads/#{uuid}.#{audio_type}", "w") do |f|
      f.write(params['audio'][:tempfile].read)
    end

    #--------------------------------#--------------------------------------------------------------------------------------------------#
    # ffmpeg command                 #          Explanation                                                                             #
    #--------------------------------#--------------------------------------------------------------------------------------------------#
    # -i filename                    #  Input file name                                                                                 #
    #--------------------------------#--------------------------------------------------------------------------------------------------#
    # -c[:stream_specifier] copy     #  Select an encoder (when used before an output file) or a                                        #
    #                                #  decoder (when used before an input file) for one or more streams.                               #
    #                                #  copy (output only) to indicate that the stream is not to be re-encoded.                         #
    #                                #  [:steam_specifier] can be `a` for audio and `v` for video                                       #
    #--------------------------------#--------------------------------------------------------------------------------------------------#
    # -c:a aac -strict experimental  #  native FFmpeg AAC encoder is included with ffmpeg and is does not require an external library   #
    #--------------------------------#--------------------------------------------------------------------------------------------------#

    Thread.new do # trivial example work thread
      `ffmpeg -i uploads/#{uuid}.webm uploads/#{uuid}.mp4`
      `ffmpeg -i uploads/#{uuid}.mp4 -i uploads/#{uuid}.wav -c:v copy -c:a aac -strict experimental public/videos/#{uuid}.mp4`
      #copy the .mp4 output file to dropbox
      f = File.new("public/videos/#{uuid}.mp4", "r")
      resp_mp4 = client.put_file("#{uuid}.mp4", f)
    end

    uuid+".mp4"
  else
    #video
    resp_video = client.put_file("#{uuid}.#{video_type}", params['video'][:tempfile])
    #audio
    audio_type = params['audio'][:type].split("/").last
    resp_audio = client.put_file("#{uuid}_1.#{audio_type}", params['audio'][:tempfile])

    File.open("uploads/#{uuid}_1.#{audio_type}", "w") do |f|
      f.write(params['audio'][:tempfile].read)
    end
    uuid+".#{video_type}"
  end
end

get "/video/:file_name" do
  @file_name = params[:file_name]
  uuid = params[:file_name].split(".").first
  erb :video
end

get "/video/:file_name/download" do
  begin
    @file_name = params[:file_name]
    final_video = client.get_file("/#{@file_name}")
    open("#{@file_name}", 'w') {|f| f.puts final_video }
    send_file "#{@file_name}", :filename => "#{@file_name}", :type => "Application/video"
    rescue DropboxError => e
      if e.http_response.code == '404'
        @status_message = "Please wait, your video file is being converted."
      end
  end
  erb :video
end
