function initialise(app)
    app.session = PracticeSession(app);

    %% Find available I/O devices
    deviceInfo = audiodevinfo;
    outputDevices = deviceInfo.output;

    app.OutputDeviceDropDown.Items = strings(length(outputDevices), 0);
    app.OutputDeviceDropDown.ItemsData = zeros(length(outputDevices), 0);

    for iter = 1:length(outputDevices)
        app.OutputDeviceDropDown.Items(iter) = cellstr(outputDevices(iter).Name);
        app.OutputDeviceDropDown.ItemsData(iter) = outputDevices(iter).ID;
    end

    app.deviceReader = audioDeviceReader('SampleRate', str2double(app.SampleRateDropDown.Value), 'SamplesPerFrame', str2double(app.BufferSizeDropDown.Value));
    inputDevices = app.deviceReader.getAudioDevices();
    app.InputDeviceDropDown.Items = strings(length(inputDevices), 0);
    app.InputDeviceDropDown.Items = inputDevices;

    if exist('resources/IOSettings.mat', 'file')
        lagStruct = load('resources/IOSettings.mat');
        app.InputDeviceDropDown.Value = lagStruct.inputDevice;
        app.OutputDeviceDropDown.Value = lagStruct.outputDevice;
    end

end
