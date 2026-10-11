%%
clear; close all; clc;
load('rete_addestrata2A.mat','net_2A');

 %% velocizzo cpu
if isempty(gcp('nocreate'))  % Controlla se il pool è già attivo
    parpool;  % Avvia il parallel computing
end

numCores = feature('numcores');
fprintf(' MATLAB sta usando %d core della CPU.\n', numCores);

%% Cartelle di input e output
maskFolder = 'C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\gt_train2';
imageFolder = 'C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\im_train2';

outputFolder = 'C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\gt_normalizzato_RETE';
% Ottieni la lista dei file delle maschere
fileList = dir(maskFolder); % Legge tutti i file nella cartella
fileList = fileList(~ismember({fileList.name}, {'.', '..'})); % Rimuove "." e ".."
% Crea la cartella di output per le maschere normalizzate
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end


%% Normalizza le maschere da [0, 255] a [0, 1]
% Svuota la cartella di output senza eliminarla
if exist(outputFolder, 'dir')
    delete(fullfile(outputFolder, '*')); % Cancella tutti i file nella cartella
end
for i = 1:length(fileList)
    % Percorso della maschera originale
    maskPath = fullfile(maskFolder, fileList(i).name);
    maskImage = imread(maskPath);
    
    % Normalizza i valori: da [0, 255] a [0, 1]
    maskImage(maskImage == 255) = 1;
    
    % Salva la maschera normalizzata nella nuova cartella
    outputPath = fullfile(outputFolder, fileList(i).name);
    imwrite(uint8(maskImage), outputPath);
    disp(['Maschera normalizzata salvata in: ', outputPath]);
end
%% Caricamento dei dati in datastore
% Crea il datastore delle immagini
imds = imageDatastore(imageFolder, 'FileExtensions', {'.png', '.jpg', '.tif', '.tiff'});
% Definisci le classi e i relativi pixel per il pixelLabelDatastore
classNames = ["N", "B"]; % Sfondo e tumore
pixelValues = [0, 1]; % Valori binari nelle maschere
% Crea il datastore delle maschere
pxds = pixelLabelDatastore(outputFolder, classNames, pixelValues, ...
    'FileExtensions', {'.png', '.jpg', '.tif', '.tiff'});
%% rete deeplabv3plusLayers
numClasses=2;
imageSize=[256 256 3]; % dipende dalla rete che si usa
pximds = pixelLabelImageDatastore(imds,pxds,'OutputSize',imageSize,'ColorPreprocessing','gray2rgb');
lgraph = deeplabv3plusLayers(imageSize, numClasses, "resnet50");
%analyzeNetwork(lgraph); % queste blocco serve per bilanciare rispetto alle classi background e
% foreground
tbl = countEachLabel(pximds);
% Conta i pixel per classe
tbl = countEachLabel(pximds);
disp("Numero di pixel per classe:");
disp(tbl);

totalNumberOfPixels = sum(tbl.PixelCount);
frequency = tbl.PixelCount / totalNumberOfPixels;
classWeights = 1./frequency;
pxLayer = pixelClassificationLayer('Name','classification','Classes',tbl.Name,'ClassWeights',classWeights);
lgraph = replaceLayer(lgraph,"classification",pxLayer);


 %% riprendo addestramento rete net_2
options = trainingOptions('adam', ...
    'InitialLearnRate', 0.00001, ... 
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropFactor', 0.5, ...  % Learning rate dimezzato
    'LearnRateDropPeriod', 5, ...    % Riduzione ogni 5 epoche
    'MaxEpochs', 10, ...             
    'MiniBatchSize', 16, ...         % Batch più grande per stabilità
    'Shuffle', "once", ...
    'Plots', 'training-progress', ...
    'ValidationPatience', 8, ...
    'VerboseFrequency', 20, ...
    'ExecutionEnvironment', 'parallel');


 % Verifica che il datastore sia pronto
disp("Datastore pronto per l'addestramento!");
disp(pximds);
%% avvia addestramento
lgraph = layerGraph(net_2A);
net_2B = trainNetwork(pximds, lgraph, options);
disp("Addestramento completato con successo!");

%% salvataggio rete
save('rete_addestrata2B.mat', 'net_2B');