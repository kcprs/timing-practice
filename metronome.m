tempo = 120;

timeInterval = 60 / tempo;

tickAudio = audioread('tick.wav');

t = timer;
t.Period = timeInterval;
t.TimerFcn = @metronomeTick;
t.ExecutionMode = 'fixedRate';
t.TasksToExecute = 60;
start(t);

function metronomeTick(~, ~)
    disp('tick')
end