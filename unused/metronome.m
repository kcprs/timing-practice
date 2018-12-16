tempo = 140;

timeInterval = 60 / tempo;

[tickAudio, fs] = audioread('tick.wav');
player = audioplayer(tickAudio, fs);

t = timer;
t.Period = timeInterval;
t.TimerFcn = @metronomeTick;
t.ExecutionMode = 'fixedRate';
t.TasksToExecute = 10;
t.UserData = player;
start(t);

function metronomeTick(mTimer, ~)
    play(mTimer.UserData)
end