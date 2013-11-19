$("#validation-footer").html(Modernizr.video ? "Video is supported by your browser!!!" : "Ops, you did it again, you have a bad browser, lalala");

//var myVideo = $("#video_w_commands")[0]; 
var myVideo = document.getElementById("video_w_commands");

function playPause(){ myVideo.paused ? myVideo.play() : myVideo.pause(); } 

function makeBig(){ myVideo.width = 560; } 

function makeSmall(){ myVideo.width = 320; } 

function makeNormal(){ myVideo.width = 420; } 


