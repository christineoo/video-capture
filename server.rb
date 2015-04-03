require "sinatra"
require "uuid"

get "/" do
  erb :index
end

post "/upload" do
  uuid = UUID.generate
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

    `ffmpeg -i uploads/#{uuid}.webm uploads/#{uuid}.mp4`
    `ffmpeg -i uploads/#{uuid}.mp4 -i uploads/#{uuid}.wav -c:v copy -c:a aac -strict experimental public/videos/#{uuid}.mp4`
  else

    #audio
    audio_type = params['audio'][:type].split("/").last
    File.open("uploads/firefox_audio.#{audio_type}", "w") do |f|
      f.write(params['audio'][:tempfile].read)
    end

    `ffmpeg -i uploads/#{uuid}.webm uploads/#{uuid}.mp4`
    `ffmpeg -i uploads/#{uuid}.mp4 -i uploads/firefox_audio.webm -c:v copy -c:a aac -strict experimental public/videos/#{uuid}.mp4`       
  end
  uuid
end

get "/video/:uuid" do
  @uuid = params[:uuid]
  erb :video
end
