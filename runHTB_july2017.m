function runHTB_july2017(varargin)

% This version last updated on: July 20th, 2017

% Randomize matlab - this is not default
rng('default');
rng('shuffle');

KbName('UnifyKeyNames');


%% Base Directory
ROOT = [pwd '/'];

%% USER INPUT
if isempty(varargin)
    %message pops up in the command window to ask for subject number and current stimulation site
    [subject, day, session] = userInputRequest();
elseif length(varargin) == 3
    subject = varargin{1};
    day = varargin{2};
    session = varargin{3};
end

SUBJECTDATA = [ROOT 'SubjectData/']; %puts the information about the subject in the current directory
if exist(SUBJECTDATA,'dir')~=7% if SUBJECTDATA is not equal to 7 (in other words if it does not exist create it)
    mkdir(SUBJECTDATA);
end
SUBDIR = [SUBJECTDATA subject '/'];
if exist(SUBDIR,'dir')~=7
    mkdir(SUBDIR);
end

c = clock;%gives the current date and time as a six element vector with [year month day hour minute seconds]
shortDate = sprintf('%i_%i',c(2),c(3)); %grabs the date [month day]

% Experiment loop to check for file existence
startExperimentFlag = 0;
while ~startExperimentFlag%while startExperimentFlag is NOT the case
    %name of data output file
    subDataFilename = ['results_HTB_' subject '_' day '_' session '_' shortDate '.mat'];
    subDataFile = [SUBDIR subDataFilename];
    %if a file with that same info already exists, lets you give a
    %new subject #, or overwrite the existing file
    if exist(subDataFile,'file')==2
        fprintf('Wait a sec... A file with this name already exists\n')
        overwrite = input('File already exists! Overwrite? (y or n): ', 's');
        if strcmpi(overwrite, 'n')
            [subject, day, session] = userInputRequest();
        else
            % copy file to save and delete old file
            copyVersionOfFile = [subDataFile(end-4:end) '_copy.mat'];
            if exist(copyVersionOfFile,'file')==2
                delete(copyVersionOfFile);
            end
            copyfile(subDataFile,copyVersionOfFile);
            delete(subDataFile);
        end
    else
        startExperimentFlag = 1;
    end
end

%% Generate Taskmaps & TMS Timing Files
%THIS IS important because it generates the task map files
[taskMapFile] = generateTaskAndTiming(subject,day, session);
taskmap=load(taskMapFile);

% date
c = clock;
date = [num2str(c(2)) '/' num2str(c(3)) '/' num2str(c(1))];
time = [num2str(c(4)) ':' num2str(c(5))];

% Results output struct
% first include information about this session
results_subInfoStruct = struct('subject',subject,...
    'day',day,...
    'session',session,...
    'date',date,...
    'time',time);

%% Screen setup
AssertOpenGL; % AssertPsychOpenGL - will error if not able to assert
HideCursor;
WaitSecs(0.5);
% Reset the computer if you exit the script midway - for debug purposes
alwaysCloseScreen = onCleanup(@() sca);
alwaysRevealCursor = onCleanup(@() ShowCursor);
if strcmp(day,'EEG')
    Screen('Preference', 'SkipSyncTests',0);
%     % probably should comment out the code below...
%     % Enforce use of DWM on Windows-Vista and later: This simulates the
%     % situation of Windows-8 or later on Windows-Vista and Windows-7:
%     Screen('Preference','ConserveVRAM', 16384); % Force use of DWM.
%     % Query nominal framerate as returned by Operating system:
%     % If OS returns 0, then we assume that we run on a flat-panel with
%     % fixed 60 Hz refresh interval.
%     framerate=Screen('NominalFramerate', window);
%     if (framerate==0)
%         framerate=60;
%     end
%     ifinominal=1 / framerate;
%     fprintf('The refresh interval reported by the operating system is %2.5f ms.\n', ifinominal*1000);
else
    Screen('Preference', 'SkipSyncTests',3); %change to 0 before running for real
end
Screen('Preference', 'VBLTimestampingMode', 1);
screenNumber=max(Screen('Screens'));
%give values for screen elements
screenColor = [0 0 0];
fixColor = [255 255 255];
%black = BlackIndex(0);
white = WhiteIndex(screenNumber);
[window, wRect]=Screen('OpenWindow',screenNumber, screenColor);%opens the window
priorityLevel=MaxPriority(window);
Priority(priorityLevel);
Screen('TextSize', window, 42);
Screen('TextFont', window, 'Arial');
Screen('TextColor', window, fixColor);
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
screenWidth = wRect(3);
screenHeight = wRect(4);
centerY = wRect(4)/4;
% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(wRect);

%% TIMING - Baseline & TMS-fMRI
% stimulus, then delay, then probe
responseWindow = 2;

% Number of blocks and trials
if strcmp(session(1),'p')
    numBlocks = 5;
    blockIdx = str2double(session(2));
else
    numBlocks = 8;
    blockIdx = str2double(session);
end

%% Finger Mapping
fingerMapping = {'A','S','D','F','J','K','L',';'};
numFingers = length(fingerMapping);
allResponses = NaN(1,numFingers);
for fingerIdx = 1:numFingers
    allResponses(fingerIdx) = KbName(fingerMapping{fingerIdx});
end
SecretKey = KbName('6^');

%----------------------------------------------------------------------
%                        Fixation Cross
%----------------------------------------------------------------------

% Screen Y fraction for fixation cross
crossFrac = 0.0167;

% Here we set the size of the arms of our fixation cross
fixCrossDimPix = wRect(4) * crossFrac;

% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
FixCross = [xCoords; yCoords];

% Set the line width for our fixation cross
lineWidthPix = 4;

%% Load Stimuli
STIMULI_DIR = [ROOT 'Stimuli/'];


%% Instructions
if blockIdx == 1
    instruct='Welcome to this experiment! \n\n\n\n\n Hierarchy Task ready to start \n\n\n Press left pointer finger';
else
    instruct='\n\n\n\n\n Press left pointer finger';
end
%% Wait for 'match' key press - confirms subject is using the correct button
DrawFormattedText(window, instruct, 'center', centerY/2, 255);
Screen('Flip', window);
% loop for the button press
waitForKeyPress = 1;
while waitForKeyPress
    [keyIsDown,~,keyCode] = KbCheck(-1);
    if keyIsDown && keyCode(allResponses(4))
        waitForKeyPress = 0;
    end
end

%% Wait for new instructions from Experimenter
%----------------------------------------------------------------------
%                        Task Instructions
%----------------------------------------------------------------------
% print my own instructions
% image with instructions called "Imageinstr" & a bit of text called "davidinstr"
%sca;

% First define a presentation boundary - 1/8 in on the sides and squarify
% the presentation screen
% variables to manipulate:
% how far in should the presentation square be
% Once we square the screen - how far in to present the stimuli
presentationWindowRatio = 1/20;
ratioOfLayerFromSquaresForText = 1/3;
instructionEdgeRatio = 1/8;

% nothing else should be editted
leftEdge = (screenWidth - screenHeight) / 2;
presentationEdge = screenHeight * presentationWindowRatio; % presentation edge
% cut the presentation sqaure into quarters
pSquare_side = screenHeight - (presentationEdge*2);
% 3 layers
%   1 - the text for the experiment
%   2 - the squares
%   3 - the fingers
pLayer_height = (pSquare_side / 3);

condition = taskmap.condition;
summaryInfo = load([SUBDIR 'summary_' subject '_' day '.mat']);
if strcmp(condition(1),'R')
    
    numStim = str2double(condition(2));
    stimMapping = summaryInfo.([condition '_stimMapping']);
    respMapping = summaryInfo.([condition '_responseMapping']);
    
    % Display the overall text
    instructions = ['Memorize the response mapping below\n'...
        'when you see the colored square\n',...
        'press the corresponding button'];
    % display each finger and the response for that finger
    for stimIdx = 1:numStim
        % leave a blank spot between the two hands
        if stimIdx > (numStim/2)
            extraIdx = 1;
        else
            extraIdx = 0;
        end
        pLayer_increment = pSquare_side / (numStim+1);
        miniP_edge = (pLayer_height - pLayer_increment) / 2;
        superMini_corner = (pLayer_increment / 8);
        actual_side = pLayer_increment - (superMini_corner*2);
        layer2_X = leftEdge + presentationEdge + (pLayer_increment * (stimIdx+extraIdx-1));
        layer2_Y = presentationEdge + pLayer_height;
        % we now have the rectangle within which to present the square
        % go a fraction within the rectangle
        actualX = layer2_X + superMini_corner;
        actualY = layer2_Y + miniP_edge + superMini_corner;
        
        % stimulus destination square
        stimuli_destination = [actualX actualY actualX+actual_side actualY+actual_side];
        
        % draw text on the next layer
        text_destination = stimuli_destination;
        stimTextOffset = (((pLayer_height-actual_side)*ratioOfLayerFromSquaresForText)+actual_side);
        text_destination([2 4]) = text_destination([2 4]) + stimTextOffset;
        
        % prepare stimuli images and text to be presented
        stimulusImage = [STIMULI_DIR 'Resp_Stim' num2str(stimMapping(stimIdx)) '.jpg'];
        stimulusMatrix = imread(stimulusImage);
        textureToDisplay = Screen('MakeTexture',window,stimulusMatrix);
        thisFinger = fingerMapping{respMapping(stimIdx)};
        responseText = thisFinger(1);
        % draw stimuli on the screen
        Screen('DrawTexture', window, textureToDisplay, [], stimuli_destination, 0);
        DrawFormattedText(window, responseText, 'center', 'center',255,20,0,0,1,0,text_destination);
    end
    
elseif strcmp(condition(1),'D')
    
    Dim_responseMapping = summaryInfo.Dim_responseMapping;
    MATCH = {'Match','Non-match'};
    numMatch = length(MATCH);
    DIMENSIONS = {'Shape','Texture'};
    numDim = length(DIMENSIONS);
    
    % Dimension match-nonmatch mapping
    numDimImages = 8;
    % 1 = match, 0 = non-match
    ShapeMatch =   [1 0 1 0 0 1 0 1];
    TextureMatch = ~ShapeMatch;
    
    % needed for both D
    halfLayer_width = pSquare_side/2;
    colorMapping = summaryInfo.([condition '_colorMapping']);
    if strcmp(condition(2),'1')
        % D1 - has a fixed dimension to evaluate stimuli
        % Display the overall text
        thisDimension = taskmap.dimension{1};
        instructions = sprintf(['Ignore the colored square\n',...
            'evalute the stimuli based on %s only\n',...
            'Respond match or non-match'],thisDimension);
        
        % present 2 stimuli - one is a match and the other is a
        % non-match the colors are randomly selected - but both are
        % presented
        leftEdge_stim = (halfLayer_width - pLayer_height)/2;
        miniCorner = pLayer_height * (1/8);
        stimSide = pLayer_height - (miniCorner*2);
        
        % randomize which color is match or non-match
        randomColor = randperm(2);
        
        for stimIdx = 1:2
            % find the two stimuli that you want to present
            actualX = leftEdge + presentationEdge + leftEdge_stim + (halfLayer_width*(stimIdx-1)) + miniCorner;
            actualY = presentationEdge + pLayer_height + miniCorner;
            stimuli_destination = [actualX actualY actualX+stimSide actualY+stimSide];
            
            thisColor = colorMapping(randomColor(stimIdx));
            stimOptions = eval([thisDimension 'Match']);
            if (Dim_responseMapping(stimIdx) - 3) == 1
                stimOptsIdx = find(stimOptions);
            else
                stimOptsIdx = find(~stimOptions);
            end
            exampleStimIdx = stimOptsIdx(randi(length(stimOptsIdx)));
            thisStimIdx = exampleStimIdx + ((thisColor-1) * numDimImages);
            
            stimulusImage = [STIMULI_DIR 'Dim_Stim' num2str(thisStimIdx) '.jpg'];
            stimulusMatrix = imread(stimulusImage);
            textureToDisplay = Screen('MakeTexture',window,stimulusMatrix);
            Screen('DrawTexture', window, textureToDisplay, [], stimuli_destination, 0);
        end
    elseif strcmp(condition(2),'2')
        
        % Display the overall text
        instructions = ['Memorize the dimension to color mapping below.\n'...
            'When you see the colored square\n',...
            'evalute the stimuli based on texture or shape.\n'];
        
        % presents 4 stimuli - match and non-match of each kind
        textureMatchOpts = find(TextureMatch);
        TextureMatchStimIdx = textureMatchOpts(randi(4));
        shapeMatchOpts = find(ShapeMatch);
        ShapeMatchStimIdx = shapeMatchOpts(randi(4));
        
        % Half of each quarter
        halfLayer_height = pLayer_height / 2;
        
        for matchIdx = 1:numMatch
            thisMatchIdx = Dim_responseMapping(matchIdx) - 3;
            matchText = MATCH{thisMatchIdx};
            for dimIdx = 1:numDim
                dimText = DIMENSIONS{dimIdx};
                %                interactionText = [matchText ' ' dimText];
                interactionText = dimText;
                
                % pick  the stimulus image
                thisColor = colorMapping(dimIdx);
                if strcmp('Match',matchText)
                    exampleStimIdx = eval([dimText 'MatchStimIdx']);
                else
                    otherDimIdx = dimIdx + 1;
                    if otherDimIdx > numDim
                        otherDimIdx = 1;
                    end
                    exampleStimIdx = eval([DIMENSIONS{otherDimIdx} 'MatchStimIdx']);
                end
                thisStimIdx = exampleStimIdx + ((thisColor-1) * numDimImages);
                
                %                 % Destination for text and stimuli
                %                 quarterX = leftEdge + presentationEdge + ((matchIdx-1)*halfLayer_width);
                %                 quarterY = presentationEdge + pLayer_height + ((dimIdx-1)*halfLayer_height);
                %                 stimSide = halfLayer_height * (2/3);
                %                 miniCorner = (halfLayer_width - stimSide) / 2;
                
                % I need to make the center layer larger for D2.
                % old code above
                quarterX = leftEdge + presentationEdge + ((matchIdx-1)*halfLayer_width);
                % let's try doubling the middle layer
                % cut a fraction into the top layer
                newpLayerHeight = pLayer_height * (3/4);
                newHalfLayer_height = pLayer_height * (3/4); % cutting into half of top and bottom layer
                quarterY = presentationEdge + newpLayerHeight + ((dimIdx-1)*newHalfLayer_height);
                stimSide = newHalfLayer_height * (2/3);
                miniCorner = (halfLayer_width - stimSide) / 2;
                
                interaction_destination = [quarterX+miniCorner quarterY quarterX+miniCorner+stimSide quarterY+stimSide];
                % need to move the interaciton up
                moveInteractionUp = 1/5;
                interaction_destination([2 4]) = interaction_destination([2 4]) - (moveInteractionUp * stimSide);
                stimuli_destination = [quarterX+miniCorner quarterY+(newHalfLayer_height-stimSide) quarterX+miniCorner+stimSide quarterY+newHalfLayer_height];
                
                stimulusImage = [STIMULI_DIR 'Dim_Stim' num2str(thisStimIdx) '.jpg'];
                stimulusMatrix = imread(stimulusImage);
                textureToDisplay = Screen('MakeTexture',window,stimulusMatrix);
                Screen('DrawTexture', window, textureToDisplay, [], stimuli_destination, 0);
                DrawFormattedText(window, interactionText,'center','center',255,10,0,0,1,0,interaction_destination);
            end
        end
    end
    
    if strcmp(condition,'D2')
        moveResponseDown = 1/4;
    else
        moveResponseDown = 0;
    end
    
    % Response mapping is the same for both
    Dim_responseMapping = summaryInfo.Dim_responseMapping;
    for fingerIdx = 1:2
        respIdx = fingerIdx+3;
        thisMatchIdx = find(Dim_responseMapping==respIdx,1);
        matchText = MATCH{thisMatchIdx};
        fingerText = fingerMapping{respIdx};
        fingerText = fingerText(1);
        
        halfLayer_height = pLayer_height/2;
        superMiniCorner = halfLayer_height/8;
        actual_matchWidth = halfLayer_width - (superMiniCorner*2);
        actual_matchHeight = halfLayer_height - (superMiniCorner*2);
        actualX = leftEdge + presentationEdge + ((fingerIdx - 1) * halfLayer_width) + superMiniCorner;
        actualY = presentationEdge + (pLayer_height*2) + superMiniCorner;
        matchName_destination = [actualX actualY actualX+actual_matchWidth actualY+actual_matchHeight];
        matchName_destination([2 4]) = matchName_destination([2 4]) + (moveResponseDown * pLayer_height);
        respText_destination = matchName_destination;
        respText_destination([2 4]) = respText_destination([2 4]) + (halfLayer_height*(1/2));
        % draw the match name and corresponding finger
        DrawFormattedText(window, matchText,'center','center',255,10,0,0,1,0,matchName_destination);
        DrawFormattedText(window, fingerText,'center','center',255,10,0,0,1,0,respText_destination);
    end
end

pInst_edge = pSquare_side*instructionEdgeRatio;
pInst_width = pSquare_side - (pInst_edge*2);
pInst_height = pLayer_height - (pInst_edge*2);
pInstX = leftEdge + presentationEdge + pInst_edge;
pInstY = presentationEdge + pInst_edge;
inst_destination = [ pInstX pInstY pInstX+pInst_width pInstY+pInst_height];
DrawFormattedText(window, instructions, 'center', 'center',255,1000,0,0,1,0,inst_destination);
Screen('Flip',window);

% don't advance until the secret key is pressed
waitForKeyPress = 1;
while waitForKeyPress
    [keyIsDown,secs,keyCode] = KbCheck(-1);
    if keyIsDown && keyCode(SecretKey)
        waitForKeyPress = 0;
    end
end

% load up textures
if strcmp(condition(1),'R')
    condStr = 'Resp';
elseif strcmp(condition(1),'D')
    condStr = 'Dim';
end
stimulusNumber = taskmap.stimulusNumber;
allStimuli = unique(stimulusNumber);
numStimuli = length(allStimuli);
allTextures = cell(1,numStimuli);
for stimulusIdx = 1:numStimuli
    stimulusImage = [STIMULI_DIR condStr '_Stim' num2str(stimulusNumber(stimulusIdx)) '.jpg'];
    stimulusMatrix = imread(stimulusImage);
    textureToDisplay = Screen('MakeTexture',window,stimulusMatrix);
    allTextures{stimulusIdx} = textureToDisplay;
end

if strcmp(day,'EEG')
    % Initialize connection to EEg
    lptwrite(53504,0);
    WaitSecs(0.001);
    % Start recording from EEG
    lptwrite(53504,256); % this is 1 indexed and computer is listening for a 0 indexed value
    WaitSecs(0.001);
    lptwrite(53504,0);
end

if strcmp(day,'EEG')
    % synchronize to the screen
    TIME_start = Screen('Flip',window);
else
    % cannot get fine timing so do the best you can
    % This is the time that the task begins
    TIME_start = secs - 0.008; % subtract 8 ms for screen refresh delay
    % 60 hz refresh means 16.667 ms for each refresh
    % we cannot know when in the refresh the command to change screen is sent
    % there is an error margin of plus or minus 8ms
end

clear subResults;
TIME_trial = TIME_start;

%% Begin the trials
responseNumber = taskmap.responseNumber;
iti = taskmap.iti;
numTrials = length(stimulusNumber);
for trialIdx = 1:numTrials
    
    % Present the fixation cross
    Screen('FillRect', window, screenColor);
    Screen('DrawLines', window, FixCross, lineWidthPix, white, [xCenter yCenter], 2);
    TIME_actual = Screen('Flip', window,TIME_trial);
    actualTiming(1) = TIME_actual - TIME_trial;
    
    % the first iti is the dummy time
    TIME_trial = TIME_actual + iti(trialIdx);
    
    %% Displaying the Response and Dimension stimuli
    textureIdx = stimulusNumber(trialIdx)==allStimuli;
    Screen('DrawTexture', window, allTextures{textureIdx}, [], [], 0);
    Screen('DrawLines', window, FixCross, lineWidthPix, white, [xCenter yCenter], 2);
    
    % flip up probe
    TIME_actual = Screen('Flip', window,TIME_trial);
    % right after flipping the window for the stimulus - trigger the EEG
    % with a flag that is the trial index
    if strcmp(day,'EEG')
        % Send a flag to the EEG with the start of the trial
        lptwrite(53504,5); % this is 1 indexed and computer is listening for a 0 indexed value
        WaitSecs(0.100);
        lptwrite(53504,0);
    end
    % store actual timing
    actualTiming(2) = TIME_actual - TIME_trial;
    TIME_trial = TIME_actual;
    
    %% Check for subject response
    startProbeTime = TIME_trial;
    subjectResponded = 0;
    keyResponse = 0;
    TIME_trial = TIME_trial + responseWindow;
    
    % loop until subject responds or time runs out
    while (GetSecs < TIME_trial) && ~subjectResponded
        [keyIsDown,reactionTime,keyCode] = KbCheck(-1);
        if keyIsDown
            checkForResponse = find(keyCode(allResponses));
            if length(checkForResponse)==1
                subjectResponded = 1;
                keyResponse = checkForResponse;
            end
        end
    end
    % was this response the correct response?
    if subjectResponded
        reactionTime = reactionTime - startProbeTime;
        correctResponse = keyResponse == responseNumber(trialIdx);
    else
        reactionTime = NaN;
        correctResponse = 0;
    end
    
    if subjectResponded
        WaitSecs('UntilTime',TIME_trial-0.050);
    end
    
    %% Record trial data
    % these items are defined before the trial starts
    subTrialInfo.iti = iti(trialIdx);
    subTrialInfo.KeyResponse = keyResponse;
    subTrialInfo.imageName = stimulusNumber(trialIdx);
    subTrialInfo.responseNumber = responseNumber(trialIdx);
    subTrialInfo.correct = correctResponse;
    subTrialInfo.reactionTime = reactionTime;
    subTrialInfo.condition = condition;
    subTrialInfo.actualTiming = actualTiming;
    
    subResults.trialInfo(trialIdx) = subTrialInfo;
end

subResults.overview = results_subInfoStruct;
save(subDataFile,'-struct','subResults')

% Present the fixation cross
Screen('FillRect', window, screenColor);
Screen('DrawLines', window, FixCross, lineWidthPix, white, [xCenter yCenter], 2);
Screen('Flip', window);
WaitSecs(6);


% display remaining blocks in the experiment
if strcmp(session(1),'p')
    practiceBlockIdx = str2double(session(2));
    
    correct = [subResults.trialInfo.correct];
    accuracy = int64(round(100*mean(correct)));
    if practiceBlockIdx < 5
        message = sprintf('You are done with run %i of 5 of the practice',practiceBlockIdx);
    else
        message = 'You are now done with the practice';
    end
    message=sprintf('%s\n\n\nCall the experimenter over for further instruction\n\nAccuracy = %i%%\n\n',message,accuracy);
    anotherSession = 1;
    if practiceBlockIdx == 5
        nextSession = '1';
    else
        nextSession = ['p' num2str(practiceBlockIdx + 1)];
    end
elseif str2double(session) == numBlocks
    message=sprintf('You are now done with the experiment \n \n \n Thanks for participating! \n \n');
    anotherSession = 0;
else
    message = sprintf('You are done with run %s out of %i\n\n\n Press any key to begin the next run',session,numBlocks);
    anotherSession = 1;
    nextSession = num2str(str2double(session)+1);
end

DrawFormattedText(window, message, 'center', 'center', 255);
Screen('Flip', window);

if strcmp(day,'EEG')
    % Stop recording from EEG
    OFF = 255;
    lptwrite(53504,OFF); % this is 1 indexed and computer is listening for a 0 indexed value
    % clear the port after sending flag
    WaitSecs(0.001);
    lptwrite(53504,0);
end

readyToBegin = 0;
while ~readyToBegin
    keyIsDown = KbCheck(-1);
    if keyIsDown
        readyToBegin = 1;
    end
end

ListenChar(0);
Screen('CloseAll');
ShowCursor;
FlushEvents;
fclose('all');
Priority(0);

if anotherSession
    if strcmp(session(1),'p')
        runAnother = 1;
    else
        % ask the experimenter if they want to continue to the next block
        validAnswer = 0;
        while ~validAnswer
            runAnother = input('Continue to the next block? (y or n): ','s');
            if strcmpi(runAnother,'y')
                validAnswer = 1;
                runAnother = 1;
            elseif strcmpi(runAnother,'n')
                validAnswer = 1;
                runAnother = 0;
            end
        end
    end
    if runAnother
        runHTB_july2017(subject,day,nextSession);
    end
end

end
% Some helper functions, don't worry about it
%------------------------------------------------------------------------
function [subject,day, session] = userInputRequest()

% request subject number
validAnswer = 0;
while ~validAnswer
    subjectNumStr = input('Subject number: ','s');
    subjectNum = str2double(subjectNumStr);
    if ~isnan(subjectNum) && subjectNum > 0 && subjectNum < 100
        validAnswer = 1;
    end
end
subject = sprintf('sub%02i',subjectNum);

% request day
validAnswer = 0;
while ~validAnswer
    dayStr = input('Day (B)aseline, (T)MS-fMRI, (E)EG: ','s');
    options = {'B','T','E'};
    dayNames = {'Baseline','TMS-fMRI','EEG'};
    dayIdx = find(strcmpi(dayStr,options));
    if ~isempty(dayIdx)
        validAnswer = 1;
    end
end
day = dayNames{dayIdx};

% request session number
validAnswer = 0;
numSessions = 8;
while ~validAnswer
    sessionNumStr = input(sprintf('Session number (1-%i, p): ',numSessions),'s');
    sessionNum = str2double(sessionNumStr);
    if ~isnan(sessionNum) && sessionNum > 0 && sessionNum <= numSessions
        validAnswer = 1;
    end
    if strcmpi(sessionNumStr,'p')
        validAnswer = 1;
        sessionNumStr = 'p1';
    end
end
session = sessionNumStr;

end

%------------------------------------------------------------------------
%GENERATING THE TASK MAP FILES
function [taskmapFileOut] = generateTaskAndTiming(subject,day, session)

% information on each condition
COND = {'R4','R8','D1','D2'};
numConditions = length(COND);
numCondIter = 2; % if we ever want to change this the code accounts for it
numBlocks = numConditions * numCondIter; % currently there are 8 total

% RESPONSE TASK INFORMATION
% how many options for stimulus within each of the main four task condtions?
% the response conditions just have 12 stimuli - randomly assign mapping
numRespStim = 12;
respMapping = randperm(numRespStim);
R4_stimMapping = respMapping(1:4);
R8_stimMapping = respMapping(5:12);

% finger mapping information
% 1 = pinky left hand
% 4 = poitner left hand
% 5 = pointer right hand
% 8 = pinky right hand
R4_responseMapping = [3 4 5 6];
R8_responseMapping = 1:8;


% DIMENSION TASK INFORMATION
if randi(2) == 1
    Dim_responseMapping = [4 5];
else
    Dim_responseMapping = [5 4];
end
MATCH = {'Match','Nonmatch'};
numMatchCond = length(MATCH);
% there are 4 colors - which two do pick for each task
numDimColors = 4;
colorMapping = randperm(numDimColors);
% For D2 - the first number is shape, second number is texture
D2_colorMapping = colorMapping(3:4);
% for D1 - the colors are random and not important
D1_colorMapping = colorMapping(1:2);
D1_shapeOrTexture = repmat([1 2],1,ceil(numCondIter/2)); % 1 = shape, 2 = texture
D1_shapeOrTexture = D1_shapeOrTexture(randperm(length(D1_shapeOrTexture)));
D1_shapeOrTexture = D1_shapeOrTexture(1:numCondIter);

% Dimension match-nonmatch mapping
numDimImages = 8;
% 1 = match, 0 = non-match
ShapeMatch =   [1 0 1 0 0 1 0 1];
TextureMatch = ~ShapeMatch; % if the texture matches then the shape does not match

SUBDIR = [pwd '/SubjectData/' subject '/'];
subDayStr = [subject '_' day];
taskmapFileStr = ['taskMap_HTB_' subDayStr '_'];
if strcmp(session(1),'p')
    practiceStr = 'practice_';
    session = session(2);
else
    practiceStr = '';
end
taskmapFileOut = [SUBDIR practiceStr taskmapFileStr session '.mat'];

% Don't make it if it already exists
if exist(taskmapFileOut,'file')~=2
    
    % if one doesn't exist then remake all of them - they must all be made
    % at the same time to maintain counterbalancing
    oldTaskMapFndr = [SUBDIR taskmapFileStr '*.mat'];
    if ~isempty(dir(oldTaskMapFndr));
        delete(oldTaskMapFndr);
    end
    
    sessionSummaryFile = [SUBDIR 'summary_' subDayStr '.mat'];
    if exist(sessionSummaryFile,'file') == 2
        delete(sessionSummaryFile);
    end
    sessionSummary = struct(...
        'R4_stimMapping',R4_stimMapping,...             % colors to fingers mapping
        'R4_responseMapping',R4_responseMapping,...
        'R8_stimMapping',R8_stimMapping,...   % colors to fingers mapping
        'R8_responseMapping',R8_responseMapping,...
        'Dim_responseMapping',Dim_responseMapping,...   % which fingers match, non-match
        'D1_colorMapping',D1_colorMapping,...           % two colors, no association
        'D2_colorMapping',D2_colorMapping...            % first color shape, second texture
        );
    save(sessionSummaryFile,'-struct','sessionSummary');
    
    % Generate multiple sets of 4 blocks - randomized within each block
    % also enforce that the same task can not happen twice in a row
    randomizationCriteriaMet = 0;
    while ~randomizationCriteriaMet
        blockCondition = [];
        for iterIdx = 1:numCondIter
            blockCondition = [blockCondition randperm(numConditions)];
        end
        randomizationCriteriaMet = 1;
        for iterIdx = 2:numCondIter
            checkIdx = numConditions*(iterIdx-1);
            if blockCondition(checkIdx) == blockCondition(checkIdx+1)
                randomizationCriteriaMet = 0;
            end
        end
    end
    
    % many of the overall condition counter balancing needs to be held
    % constant throughout all the blocks on this day
    
    % color mapping for response and dimension tasks
    
    
    % add an extra loop to generate practice blocks
    for extraIdx = 1:2
        
        if extraIdx == 2
            % practice blocks
            numBlocks = 5;
            blockCondition = [1 2 3 3 4];
            numTrials = 16;
            practiceStr = 'practice_';
        else
            practiceStr = '';
            % This number is decided because it is divisible by our condition
            % types
            numTrials = 48; % hard-coded
        end
        
        % generate all task maps and timing files for every block when you
        % cannot find them for this current block
        for blockIdx = 1:numBlocks
            
            % every block gets a task map saved out
            taskmapFile = [SUBDIR practiceStr taskmapFileStr num2str(blockIdx) '.mat'];
            
            % which condition are we doing?
            condIdx = blockCondition(blockIdx);
            condName = COND{condIdx};
            
            % ITI needs to be jittered
            % exponential(ish) spread of ITI times
            % must be a multiple of 8 to divied evenly
            %             ITI = NaN(1,numTrials);
            %             assert(mod(numTrials,2)==0);%checks what the remainder is of the divion of numTrials divided by 4 or 8 or whatever. And then checks whether that is equal to 0. e.g. 40 trials divided by 8 gives a remainder of 0, thus 0 == 0 and thus will give no error message.
            %             shuffITI = [(ones(1,ceil(numTrials/2)-1)*3) (ones(1,ceil(numTrials/4))*4) (ones(1,ceil(numTrials/4))*5)]; %(ones(1,ceil(numTrials/4))*6)
            %             shuffITI = shuffITI(1:(numTrials-1));
            %             shuffITI = Shuffle(shuffITI);
            ITI = 3+((-log(rand(1,numTrials)))*2);
            stillSomeTooLarge = 1;
            while stillSomeTooLarge
                tooLarge = find(ITI>10);
                numTooLarge = length(tooLarge);
                if numTooLarge == 0
                    stillSomeTooLarge = 0;
                else
                    newValues = 3+((-log(rand(1,numTooLarge)))*3);
                    ITI(tooLarge) = newValues;
                end
            end
            %             hist(ITI,20); % delete this line later
            %             title(sprintf('Mean ITI: %0.2f seconds, Block durations: %0.2f minutes',mean(ITI),(sum(ITI)+(numTrials*2))/60));
            ITI(1) = 6;
            if strcmp(day,'EEG')
                % round ITI to the nearest 50 milliseconds
                ITI = round((ITI * 1000)/50)*(50/1000);
            end
            % probably multiply this by 2 for fMRI
            
            % Variables to counterbalance:
            %   4 Condition: R4,R8,D1,D2
            %       Wihtin each of these there are different variables to
            %       counterbalance:
            %       for R4 there are 4 colors
            %       for R8 there are 8 colors
            %       for D1 there are 5 stimuli options
            %           match & non-match
            %       for D2 there are 2 dimensions & 5 stimuli in each
            %           match & non-match
            
            % DO THIS LATER - not implimented
            %   If TMS day, then 3 frequency manipulations
            %   3 frequencies: Beta, Theta, Arrhythmic
            %       the conditions above need to be further divided
            
            % currently there is no difference between the taskmaps for
            % Baseline and EEG
            if strcmp(day,'Baseline') || strcmp(day,'EEG')
                
                % is this condition a response or dimension conditions?
                if strcmp(condName(1),'R')
                    stimOpts = str2double(condName(2));
                    stimOrder = repmat(1:stimOpts,1,numTrials/stimOpts);
                    stimOrder = stimOrder(randperm(numTrials));
                    stimOrder = stimOrder(1:numTrials);
                    
                    % if response then just grab the mapping to stimuli
                    thisStimulusMapping = eval([condName '_stimMapping']);
                    % assign each trial a stimulus number
                    stimulusNumber = thisStimulusMapping(stimOrder);
                    % what is the response mapping to this
                    thisResponseMapping = eval([condName '_responseMapping']);
                    responseNumber = thisResponseMapping(stimOrder);
                    % initialize task map structure - have to have
                    % something in there for it to run
                    taskmap = struct('condition',condName);
                    
                elseif strcmp(condName(1),'D')
                    
                    stimulusNumber = NaN(1,numTrials);
                    
                    % two colors for display
                    whichColor = [ones(1,numTrials/2) 2*ones(1,numTrials/2)];
                    whichColor = whichColor(randperm(length(whichColor)));
                    whichColor = whichColor(1:numTrials);
                    thisColorMapping = eval([condName '_colorMapping']);
                    whichColor = thisColorMapping(whichColor);
                    dimension = cell(1,numTrials);
                    
                    allMatchNonmatch = NaN(1,numTrials);
                    
                    for colorIdx = 1:2
                        % two colors per dimension - for d1 the color is
                        % irrelevant - but still changes - counterbalanced
                        % either way
                        
                        thisColor = thisColorMapping(colorIdx);
                        % use these then put the match-nonmatch distinction
                        % into these
                        colorIndices = find(whichColor == thisColor);
                        
                        % For dimension, first decide match or non-match
                        matchNonmatch = [ones(1,numTrials/4,1) 2*ones(1,numTrials/4)];
                        matchNonmatch = matchNonmatch(randperm(length(matchNonmatch)));
                        matchNonmatch = matchNonmatch(1:(numTrials/2));
                        
                        % for D1 - one of the two blocks is shape and the other
                        % is texture
                        if strcmp(condName,'D1')
                            thisShapeOrTexture = D1_shapeOrTexture(ceil(blockIdx / numConditions));
                            if extraIdx == 2
                                thisShapeOrTexture = D1_shapeOrTexture(ceil(blockIdx / 3));
                            end
                            if thisShapeOrTexture == 1
                                matchMapping = ShapeMatch;
                                dimension(:) = {'Shape'};
                            else
                                matchMapping = TextureMatch;
                                dimension(:) = {'Texture'};
                            end
                        elseif strcmp(condName,'D2')
                            % for D2 - the color determines if shape or texture is
                            % match
                            if colorIdx == 1
                                matchMapping = ShapeMatch;
                                dimension(whichColor==thisColor) = {'Shape'};
                            else
                                matchMapping = TextureMatch;
                                dimension(whichColor==thisColor) = {'Texture'};
                            end
                        end
                        
                        for matchIdx = 1:numMatchCond
                            if matchIdx == 1
                                stimNumbers = find(matchMapping);
                            else
                                stimNumbers = find(~matchMapping);
                            end
                            numStimByMatch = length(stimNumbers);
                            matchIndices = find(matchNonmatch == matchIdx);
                            numMatchByColor = length(matchIndices);
                            allStimNumbers = repmat(stimNumbers,1,ceil(numMatchByColor/numStimByMatch));
                            allStimNumbers = allStimNumbers(randperm(length(allStimNumbers)));
                            allStimNumbers = allStimNumbers(1:numMatchByColor);
                            % adjust by color
                            allStimNumbers = allStimNumbers + ((thisColor-1)*numDimImages);
                            % store the final stimulus image number
                            stimulusNumber(colorIndices(matchIndices)) = allStimNumbers;
                        end
                        allMatchNonmatch(colorIndices) = matchNonmatch;
                    end
                    responseNumber = Dim_responseMapping(allMatchNonmatch);
                    allMatchNonmatch_cellstr = MATCH(allMatchNonmatch);
                    taskmap = struct('matchNonmatch',{allMatchNonmatch_cellstr},...
                        'color',whichColor,...
                        'dimension',{dimension});
                end
            end
            
            % add the fields common to all conditions
            taskmap.condition = condName;
            taskmap.iti = ITI;
            taskmap.stimulusNumber = stimulusNumber;
            taskmap.responseNumber = responseNumber;
            % save task map file
            save(taskmapFile,'-struct','taskmap');
        end
    end
end
end

%------------------------------------------------------------------------

