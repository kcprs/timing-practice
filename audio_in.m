frameLength = 256;
samplerate = 48000;

deviceReader = audioDeviceReader(samplerate, frameLength);
setup(deviceReader);

fileWriter = dsp.AudioFileWriter('test.wav', 'FileFormat', 'WAV');

disp('Recording...')
tic;

while toc < 10
    audioFromDevice = deviceReader();
    fileWriter(audioFromDevice);
end

disp('Done recording.');

release(deviceReader);
release(fileWriter);