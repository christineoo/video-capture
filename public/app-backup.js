$(document).ready(function(){
  // config
  var videoWidth = 640;
  var videoHeight = 480;

  // setup
  var stream;
  var audio_recorder = null;
  var video_recorder = null;
  var recording = false;
  var playing = false;
  var formData = null;
  var isFirefox = !!navigator.mozGetUserMedia;

  //var videoRecorder; //added
  //var audioRecorder; //added

  // set the video options
  var videoOptions = {
    type: "video",
    video: {
      width: videoWidth,
      height: videoHeight
    },
    canvas: {
      width: videoWidth,
      height: videoHeight
    }
  };

  // record the video and audio
  //navigator.getUserMedia({audio: true, video: { mandatory: {}, optional: []}}, function(pStream) {
  navigator.getUserMedia({audio: true, video: true}, function(pStream) {
    console.log('isFirefox: ' +isFirefox)
    stream = pStream;
    // setup video
    video = $("video.recorder")[0];

    video.src = window.URL.createObjectURL(stream);
    video.width = videoWidth;
    video.height = videoHeight;

    // init recorders
    audio_recorder = RecordRTC(stream, { type: "audio", bufferSize: 16384 });
    video_recorder = RecordRTC(stream, videoOptions);

    // update UI
    $("#record_button").show();
  }, function(){});

  // start recording
  var startRecording = function() {
    // record the audio and video
    video_recorder.startRecording();
    audio_recorder.startRecording();


    // update the UI
    $("#play_button").hide();
    $("#upload_button").hide();
    $("video.recorder").show();
    $("#video-player").remove();
    $("#audio-player").remove();
    $("#record_button").text("Stop recording");

    // toggle boolean
    recording = true;
  
    console.log("video_recorder.getBlob(): " +video_recorder.getBlob())

  }

  // stop recording
  var stopRecording = function() {
    var audio_blob;
    var video_blob;
    formData = new FormData();
    
    // stop recorders
    audio_recorder.stopRecording(function(blob){
      audio_blob = blob;
      formData.append("audio", audio_blob);
      formData.append("audio_type", audio_recorder.type);

      // add players
      var audio_player = document.createElement("audio");
      audio_player.id = "audio-player";
      //audio_player.src = URL.createObjectURL(audio_blob);
      audio_player.src = audio_blob;
      $("#players").append(audio_player);
      onStopRecording();
    });

    video_recorder.stopRecording(function(blob){
      video_blob = blob;
      formData.append("video", video_blob);
      formData.append("video_type", videoOptions.type);
      
      var video_payer = document.createElement("video");
      video_payer.id = "video-player";
      //video_payer.src = URL.createObjectURL(video_blob);
      video_payer.src = video_blob;
      $("#players").append(video_payer);
      onStopRecording();
    });


    function onStopRecording(){
      video_recorder.getDataURL(function(videoDataURL) {
        formData.append("video", video_recorder.blob);
        //postFiles(audioDataURL, videoDataURL);
      });
      audio_recorder.getDataURL(function(audioDataURL) {
        formData.append("audio", audio_recorder.blob);
        //postFiles(audioDataURL, videoDataURL);
      });
    }
    // set form data
    //formData = new FormData();

    //var audio_blob = audio_recorder.getBlob();
    //formData.append("audio", audio_blob);

    //var video_blob = video_recorder.getBlob();
    //formData.append("video", video_blob);

    // add players
    //var audio_player = document.createElement("audio");
    //audio_player.id = "audio-player";
    //audio_player.src = URL.createObjectURL(audio_blob);
    //$("#players").append(audio_player);

    //var video_payer = document.createElement("video");
    //video_payer.id = "video-player";
    //video_payer.src = URL.createObjectURL(video_blob);
    //$("#players").append(video_payer);

    // update UI
    $("video.recorder").hide();
    $("#play_button").show();
    $("#upload_button").show();
    $("#record_button").text("Start recording");

    // toggle boolean
    recording = false;
  }

  // handle recording
  $("#record_button").click(function(){
    if (recording) {
      stopRecording();
    } else {
      startRecording();
    }
  });

  // stop playback
  var stopPlayback = function() {
    // controlling
    video = $("#video-player")[0];
    video.pause();
    video.currentTime = 0;
    audio = $("#audio-player")[0];
    audio.pause();
    audio.currentTime = 0;

    // update ui
    $("#play_button").text("Play");

    // toggle boolean
    playing = false;
  }

  // start playback
  var startPlayback = function() {
    // video controlling
    video = $("#video-player")[0];
    video.play();
    audio = $("#audio-player")[0];
    audio.play();
    $("#video-player").bind("ended", stopPlayback);

    // Update UI
    $("#play_button").text("Stop");

    // toggle boolean
    playing = true;
  }

  // handle playback
  $("#play_button").click(function(){
    if (playing) {
      stopPlayback();
    } else {
      startPlayback();
    }
  });

  // Upload button
  $("#upload_button").click(function(){
    var request = new XMLHttpRequest();

    request.onreadystatechange = function () {
      if (request.readyState == 4 && request.status == 200) {
        window.location.href = "/video/"+request.responseText;
      }
    };

    request.open('POST', "/upload");
    request.send(formData);
  });
});

