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
  erb :index
end

post "/upload" do
  uuid = UUID.generate
  puts params.inspect
  #video
  video_type = params['video'][:type].split("/").last
  resp_video = client.put_file("#{uuid}.#{video_type}", params['video'][:tempfile])

  File.open("uploads/#{uuid}.#{video_type}", "w") do |f|
    f.write(params['video'][:tempfile].read)
  end

  if (params[:isFirefox] == "false")
    #audio
    audio_type = params['audio'][:type].split("/").last
    resp_audio = client.put_file("#{uuid}.#{audio_type}", params['audio'][:tempfile])
    #resp_mp4 = client.put_file("#{uuid}.mp4", "")

    File.open("uploads/#{uuid}.#{audio_type}", "w") do |f|
      f.write(params['audio'][:tempfile].read)
    end

    video_name = resp_video['path'].split("/").last
    audio_name = resp_audio['path'].split("/").last
    #mp4_name = resp_mp4['path'].split("/").last

    video_content = client.get_file(resp_video['path'])
    open(video_name, 'w') {|f| f.puts video_content }
    audio_content = client.get_file(resp_audio['path'])
    open(audio_name, 'w') {|f| f.puts audio_content }

   # `ffmpeg -i #{video_name} #{mp4_name}`
   # f = File.new("#{uuid}.mp4", "r")
   # resp_mp4 = client.put_file("#{uuid}.mp4", f)

   # `ffmpeg -i #{mp4_name} -i #{audio_name} -c:v copy -c:a aac -strict #{resp_mp4['path']}`
   # f = File.new("#{uuid}.mp4", "r")
   # resp_mp4 = client.put_file("#{uuid}.mp4", f)
    `ffmpeg -i uploads/#{uuid}.webm uploads/#{uuid}.mp4`
    `ffmpeg -i uploads/#{uuid}.mp4 -i uploads/#{uuid}.wav -c:v copy -c:a aac -strict experimental public/videos/#{uuid}.mp4`

    f = File.new("public/videos/#{uuid}.mp4", "r")
    resp_mp4 = client.put_file("#{uuid}.mp4", f)
  else
    directory = "#{settings.root}/public/videos"
    puts directory

    #audio
    audio_type = params['audio'][:type].split("/").last
    resp_audio = client.put_file("#{uuid}_1.#{audio_type}", params['audio'][:tempfile])

    File.open("uploads/#{uuid}_1.#{audio_type}", "w") do |f|
      f.write(params['audio'][:tempfile].read)
    end

    puts `ls`
    `ffmpeg -i uploads/#{uuid}.#{video_type} uploads/#{uuid}.mp4`
    `ffmpeg -i uploads/#{uuid}.mp4 -i uploads/"#{uuid}_1".#{audio_type} -c:v copy #{directory}/#{uuid}.mp4`

    f = File.new("#{directory}/#{uuid}.mp4", "r")
    resp_mp4 = client.put_file("#{uuid}.mp4", f)

  end
  uuid
end

get "/video/:uuid" do
  @uuid = params[:uuid]
  erb :video
end
