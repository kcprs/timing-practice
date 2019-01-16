% Kacper Sagnowski, Musical Performance Analysis Systems assignment

classdef CircularBuffer < handle
    % CircularBuffer A circular buffer with memory of past states
    %   When written to, appends the given vector to its data vector.
    %   If the given vector is longer than the remaining space in
    %   the data vector, the given vector is split in two parts so that
    %   the first parts fills the remaining space in the data vector.
    %   The fully filled data vector is moved to the previousData vector,
    %   the data vector is erased and the second part of the given vector
    %   is written to the newly cleared data vector.
    %
    %   EXAMPLE:
    %
    %   Initial state:
    %   buffer = CircularBuffer(10)
    %     (prepreviousData)     (previousData)         (data)
    %   |0,0,0,0,0,0,0,0,0,0|0,0,0,0,0,0,0,0,0,0|0,0,0,0,0,0,0,0,0,0|
    %
    %   buffer.add([1,1,1,1,1,1,1,1]):
    %     (prepreviousData)     (previousData)         (data)
    %   |0,0,0,0,0,0,0,0,0,0|0,0,0,0,0,0,0,0,0,0|1,1,1,1,1,1,1,1,0,0|
    %
    %   buffer.add([2,2,2,2,2,2,2,2]):
    %     (prepreviousData)     (previousData)         (data)
    %   |0,0,0,0,0,0,0,0,0,0|1,1,1,1,1,1,1,1,2,2|2,2,2,2,2,2,0,0,0,0|
    %
    %   buffer.add([3,3,3,3,3,3,3,3]):
    %     (prepreviousData)     (previousData)         (data)
    %   |1,1,1,1,1,1,1,1,2,2|2,2,2,2,2,2,3,3,3,3|3,3,3,3,0,0,0,0,0,0|

    properties
        data;               % Vector to be written to
        previousData;       % Vector containing the last fully filled data vector
        prepreviousData;    % Vector containing the previous value of previousData vector
        bufferSize;         % Size of the buffer (i.e. the above data vectors)
    end

    properties (Access = private)
        cursor;             % Cursor for keeping track of write position
    end

    methods

        function self = CircularBuffer(bufferSize)
            % CircularBuffer Constructor for the CircularBuffer class

            % Initialise all properties
            self.bufferSize = bufferSize;
            self.data = zeros(bufferSize, 1);
            self.previousData = zeros(bufferSize, 1);
            self.prepreviousData = zeros(bufferSize, 1);
            self.cursor = 1;
        end

        function filled = add(self, newData)
            % add Adds (appends) newData to the buffer.
            %   If the given data filled the buffer, returns true,
            %   otherwise returns false.

            % Save the length of the given data vector
            dataLen = length(newData);

            % Check if the data vector will be filled fully
            if self.cursor + dataLen > self.bufferSize
                % If the buffer will be filled, find out how to split the newData vector
                numToBufferEnd = self.bufferSize - self.cursor + 1;
                numRemaining = length(newData) - numToBufferEnd;

                % Write the first part of newData to the buffer
                self.data(self.cursor:self.cursor + numToBufferEnd - 1) = newData(1:numToBufferEnd);

                % Move data and previousData vectors down the memory chain
                self.prepreviousData = self.previousData;
                self.previousData = self.data;

                % Clear the data vector and write the second part of newData to it
                self.data = zeros(self.bufferSize, 1);
                self.data(1:numRemaining) = newData(numToBufferEnd + 1:end);
                
                self.cursor = numRemaining + 1;
                filled = true;
            else
                % If the buffer won't be filled, simply write newData at cursor position
                self.data(self.cursor:self.cursor + dataLen - 1) = newData;

                self.cursor = self.cursor + dataLen;
                filled = false;
            end

        end

    end

end
