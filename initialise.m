function initialise(app)
    % initialise Sets the initial values for the app object.
    %   This function is called right after the app starts.

    app.session = PracticeSession(app);
    app.player = 0;

    %% Find available I/O devices and fill the corresponding DropDown boxes
    % Outputs
    deviceInfo = audiodevinfo;
    outputDevices = deviceInfo.output;

    app.OutputDeviceDropDown.Items = strings(length(outputDevices), 0);
    app.OutputDeviceDropDown.ItemsData = zeros(length(outputDevices), 0);

    for iter = 1:length(outputDevices)
        app.OutputDeviceDropDown.Items(iter) = cellstr(outputDevices(iter).Name);
        app.OutputDeviceDropDown.ItemsData(iter) = outputDevices(iter).ID;
    end

    % Inputs
    app.deviceReader = audioDeviceReader('SampleRate', str2double(app.SampleRateDropDown.Value), 'SamplesPerFrame', str2double(app.BufferSizeDropDown.Value));
    inputDevices = app.deviceReader.getAudioDevices();
    app.InputDeviceDropDown.Items = strings(length(inputDevices), 0);
    app.InputDeviceDropDown.Items = inputDevices;

    %% Load previously saved settings, if exist
    if exist('resources/IOSettings.mat', 'file')
        lagStruct = load('resources/IOSettings.mat');
        app.InputDeviceDropDown.Value = lagStruct.inputDevice;
        app.OutputDeviceDropDown.Value = lagStruct.outputDevice;
    end

    if exist('resources/sessionSettings.mat', 'file')
        sessionSettingsStruct = load('resources/sessionSettings.mat');
        app.DetectionSensitivityKnob.Value = sessionSettingsStruct.sensitivity;
        app.TempoField.Value = sessionSettingsStruct.sessionTempo;
        app.DurationField.Value = sessionSettingsStruct.sessionDuration;
        app.PermissibleErrorField.Value = sessionSettingsStruct.tolerance;
    end

end
