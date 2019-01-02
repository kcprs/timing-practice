classdef CircularBuffer < handle

    properties
        data;
        previousData;
        prepreviousData;
        bufferSize;
        cursor;
    end

    methods

        function self = CircularBuffer(bufferSize)
            self.bufferSize = bufferSize;
            self.data = zeros(bufferSize, 1);
            self.previousData = zeros(bufferSize, 1);
            self.prepreviousData = zeros(bufferSize, 1);
            self.cursor = 1;
        end

        function filled = add(self, newData)
            dataLen = length(newData);

            if self.cursor + dataLen > self.bufferSize
                numToBufferEnd = self.bufferSize - self.cursor + 1;
                numRemaining = length(newData) - numToBufferEnd;
                self.data(self.cursor:self.cursor + numToBufferEnd - 1) = newData(1:numToBufferEnd);
                self.prepreviousData = self.previousData;
                self.previousData = self.data;
                self.data = zeros(self.bufferSize, 1);
                self.data(1:numRemaining) = newData(numToBufferEnd + 1:end);
                self.cursor = numRemaining + 1;
                filled = true;
            else
                self.data(self.cursor:self.cursor + dataLen - 1) = newData;
                self.cursor = self.cursor + dataLen;
                filled = false;
            end

        end

    end

end
