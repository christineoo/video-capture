require 'sinatra'
require 'uuid'
require 'dropbox_sdk'

# Get your app key and secret from the Dropbox developer website
APP_KEY = 'tde962n2ap70xcs'
APP_SECRET = '3isv4rd0xkhf1hq'

#flow = DropboxOAuth2FlowNoRedirect.new(APP_KEY, APP_SECRET)
#authorize_url = flow.start()

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
  #resp_video = client.put_file("#{uuid}.#{video_type}", params['video'][:tempfile])

  File.open("uploads/#{uuid}.#{video_type}", "w") do |f|
    f.write(params['video'][:tempfile].read)
  end

  if (params[:isFirefox] == "false")
    #audio
    audio_type = params['audio'][:type].split("/").last
    #resp_audio = client.put_file("#{uuid}.#{audio_type}", params['audio'][:tempfile])

    File.open("uploads/#{uuid}.#{audio_type}", "w") do |f|
      f.write(params['audio'][:tempfile].read)
    end

    #video_name = resp_video['path'].split("/").last
    #audio_name = resp_audio['path'].split("/").last

    #video_content = client.get_file(resp_video['path'])
    #open(video_name, 'w') {|f| f.puts video_content }
    #audio_content = client.get_file(resp_audio['path'])
    #open(audio_name, 'w') {|f| f.puts audio_content }

    Thread.new do # trivial example work thread
      `ffmpeg -i uploads/#{uuid}.webm uploads/#{uuid}.mp4`
      `ffmpeg -i uploads/#{uuid}.mp4 -i uploads/#{uuid}.wav -c:v copy -c:a aac -strict experimental public/videos/#{uuid}.mp4`
      f = File.new("public/videos/#{uuid}.mp4", "r")
      resp_mp4 = client.put_file("#{uuid}.mp4", f)
    end

    uuid+".mp4"
  else
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
    @status_message = "Video is ready! Enjoy!"
    send_file "#{@file_name}", :filename => "#{@file_name}", :type => "Application/video"
    rescue DropboxError => e
      if e.http_response.code == '404'
        @status_message = "Please wait, your video file is being converted."
      end
  end
  erb :video
end
