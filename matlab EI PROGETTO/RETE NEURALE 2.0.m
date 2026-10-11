%%  
clear all; close all; clc;
%% Cartelle di input e output
maskFolder = 'C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\gt_train2';
imageFolder = 'C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\im_train2';

outputFolder = 'C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\gt_normalizzato_RETE';

fileList = dir(maskFolder); % Legge tutti i file nella cartella
fileList = fileList(~ismember({fileList.name}, {'.', '..'})); % Rimuove "." e ".."


%% Normalizza le maschere da [0, 255] a [0, 1]
% Svuota la cartella di output senza eliminarla
if exist(outputFolder, 'dir')
    delete(fullfile(outputFolder, '*')); % Cancella tutte tipologie di file nella cartella
end
for i = 1:length(fileList)
   
    maskPath = fullfile(maskFolder, fileList(i).name); %cartella che contiene percorso e immagini
    maskImage = imread(maskPath);  %legge immagine e la memorizza
    
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
classNames = ["N", "B"]; 
pixelValues = [0, 1]; 
% Crea il datastore delle maschere
pxds = pixelLabelDatastore(outputFolder, classNames, pixelValues, ...
    'FileExtensions', {'.png', '.jpg', '.tif', '.tiff'});
%% rete deeplabv3plusLayers
numClasses=2;
imageSize=[256 256 3]; 
pximds = pixelLabelImageDatastore(imds,pxds,'OutputSize',imageSize,'ColorPreprocessing','gray2rgb'); %datastore completo
lgraph = deeplabv3plusLayers(imageSize, numClasses, "resnet50"); %architettura di rete

%accorgimento per riconoscere pixel bianchi
tbl = countEachLabel(pximds); 
disp("Numero di pixel per classe:");
disp(tbl);

totalNumberOfPixels = sum(tbl.PixelCount);
frequency = tbl.PixelCount / totalNumberOfPixels;
classWeights = 1./frequency; %se frequenza alta, peso basso
pxLayer = pixelClassificationLayer('Name','classification','Classes',tbl.Name,'ClassWeights',classWeights);
lgraph = replaceLayer(lgraph,"classification",pxLayer); %aggiunge layer di classificazione
%% Opzioni di addestramento
options = trainingOptions('adam', ...
    'InitialLearnRate', 0.0005, ...  
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropFactor', 0.5, ...
    'LearnRateDropPeriod', 10, ...  %tasso di apprendimento dimezza ogni 10 epoche
    'MaxEpochs', 20, ...
    'MiniBatchSize', 4, ...
    'Shuffle', "every-epoch", ...
    'Plots', 'training-progress', ...
    'ValidationPatience', 15, ...
    'VerboseFrequency', 20);

disp("Datastore pronto per l'addestramento!");
disp(pximds);
%% Avvia l'addestramento
net_2A = trainNetwork(pximds, lgraph, options);
disp(" Addestramento completato con successo!");

%% salvataggio rete
save('rete_addestrata2A.mat', 'net_2A');

%% 
load('rete_addestrata2A.mat','net_2A');






 %% visualizzo rete

analyzeNetwork(net_2A.Layers);

%% test di tutti i frame 

im_test_RETE=dir('C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\im_test2\*.png');
gt_test_RETE=dir('C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\gt_test2\*.png');

for l = 1 : length(im_test_RETE)
    l;
testImage=imread(fullfile('C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\im_test2',im_test_RETE(l).name));
% Verifica la dimensione richiesta dalla rete
imageSize = net_2A.Layers(1).InputSize(1:2); % Ottiene la dimensione richiesta dalla rete
testImage=imresize(testImage,imageSize);
GTImage=imread(fullfile('C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\gt_test2',gt_test_RETE(l).name));
% Se GTImage è RGB, converti in scala di grigi e poi in binario
    if size(GTImage, 3) == 3
        GTImage = im2gray(GTImage);
    end
    GTImage = imbinarize(GTImage);
    % Ridimensionamento per far combaciare le dimensioni
    GTImage = imresize(GTImage, imageSize);

C_test = semanticseg(testImage,net_2A);
D=C_test=='B'; % per rendere logica l'immagine di uscita
E=imfill(D,'holes');
F=imclose(E,strel('disk',3));
G=bwareafilt(F,1);
[TP,FP,FN,CR,CM,FM(l)]=evaluation_segmentation(G,GTImage);

imshowpair(testImage,G);
pause(0.1);
clear C D testImage;
end

%% valuto prestazioni in training
close all;
im_train_RETE=dir('C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\im_train2\*.png');
gt_train_RETE=dir('C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\gt_train2\*.png');
for l = 1 : length(im_train_RETE)
    l;

testImage=imread(fullfile('C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\im_train2',im_train_RETE(l).name));
% Verifica la dimensione richiesta dalla rete
imageSize = net_2A.Layers(1).InputSize(1:2); % Ottiene la dimensione richiesta dalla rete
testImage=imresize(testImage,imageSize);
GTImage=imread(fullfile('C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\gt_train2',gt_train_RETE(l).name));
% Se GTImage è RGB, converti in scala di grigi e poi in binario
    if size(GTImage, 3) == 3
        GTImage = im2gray(GTImage);
    end
    GTImage = imbinarize(GTImage);
    % Ridimensionamento per far combaciare le dimensioni
    GTImage = imresize(GTImage, imageSize);

C_test = semanticseg(testImage,net_2A);
D=C_test=='B'; % per rendere logica l'immagine di uscita
E=imfill(D,'holes');
F=imclose(E,strel('disk',3));
G=bwareafilt(F,1);
[TP,FP,FN,CR,CM,FM(l)]=evaluation_segmentation(G,GTImage);

% imwrite(D,['FRAME_TEST_SEG_NEW\',f_test(l).name(1:end-5),'_seg.tiff']);
imshowpair(testImage,G,'montage');
pause(0.05);
clear C D testImage;
end

%% box plot per FM (sia training che test)
% Supponiamo di avere già i dati delle metriche
FM_test = FM;

% Organizzazione dei dati in una matrice
data_matrix = [FM_test(:)]; % Ogni colonna rappresenta una metrica
% Creazione del Box Plot
figure;
boxplot(data_matrix, {'FM'}); % Etichette delle metriche
title('Distribuzione della metrica FM sulle immagini di train');
ylabel('Valore');
xlabel('Metriche');
grid on;

