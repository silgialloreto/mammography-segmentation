%% Visualizzazione della rete
clear; close all; clc;
load('rete_addestrata2A.mat', 'net_2A')

%% Test su immagini di test
% Definizione delle cartelle
testFolder = 'C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\im_test2\';
gtFolder = 'C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\gt_test2\';
f_test = dir(fullfile(testFolder, '*.png'));
gt_test = dir(fullfile(gtFolder, '*.png'));
imageSize = net_2A.Layers(1).InputSize(1:2); %prende primi due elementi di [H W C]
% vettori metriche inizializzati a 0
numImages = length(f_test);
FM = zeros(numImages, 1); 
Correctness = zeros(numImages, 1);
Completeness = zeros(numImages, 1);
for l = 1:numImages
    fprintf('Processing test image %d/%d...\n', l, numImages);
    
    % Lettura dell'immagine di test e ground truth
    testImage = imresize(imread(fullfile(testFolder, f_test(l).name)), imageSize);
    GTImage = imresize(imread(fullfile(gtFolder, gt_test(l).name)), imageSize);
    
    % Segmentazione con la rete neurale
    C_test = semanticseg(testImage, net_2A); %immagine in INTERI
    D = C_test == 'B'; %crea maschera logica con B=true
    E = imfill(D, 'holes');
    F = imclose(E, strel('disk', 3));
    G = bwareafilt(F, 1);
    if ~isequal(size(G), size(GTImage))
        GTImage = imresize(GTImage, size(G));
    end
   
    [TP, FP, FN, Correctness(l), Completeness(l), FM(l)] = evaluation_segmentation(G, GTImage);
    imshowpair(testImage, G);
    title(sprintf('Segmentazione Test - Frame %d', l));
    pause();
end
%% Migliori 3 risultati su Test
numPatientsTest = 11; 
framesPerPatientTest = 20; % Numero di frame per paziente
patientID_test = repelem(1:numPatientsTest, framesPerPatientTest); % Associazione frame-pazienti
% Gestione dei Valori NaN
% Trova i frame validi (senza NaN)
validIdx = ~isnan(FM) & ~isnan(Correctness) & ~isnan(Completeness);
% Filtra le metriche e le associazioni dei pazienti
FM_valid = FM(validIdx);
Correctness_valid = Correctness(validIdx);
Completeness_valid = Completeness(validIdx);
patientID_test_valid = patientID_test(validIdx);
% Ordina solo i frame validi
[~, sortedIdxTest] = sort(FM_valid, 'descend'); %indici elementi ordinati
% Selezione dei migliori 3 risultati associati a pazienti diversi
selectedFramesTest = [];
selectedPatientsTest = [];
for idx = sortedIdxTest' % Scorri attraverso i frame ordinati
    currentPatient = patientID_test_valid(idx); % Paziente associato al frame corrente
    
    if ~ismember(currentPatient, selectedPatientsTest) % Se il paziente non è già stato selezionato
        % Trova l'indice originale del frame nel dataset completo
        originalIdx = find(validIdx);
        selectedFramesTest(end+1) = originalIdx(idx); % Indice originale del frame
        selectedPatientsTest(end+1) = currentPatient; % Segna il paziente come selezionato
    end
    
    if length(selectedFramesTest) == 3 % Interrompi quando hai selezionato 3 frame
        break;
    end
end
% Visualizzazione dei Migliori Risultati
disp('Migliori risultati Test:');
for i = 1:3
    idx = selectedFramesTest(i);
    fprintf('Frame %d (Paziente %d) - FM: %.4f, Correttezza: %.4f, Completezza: %.4f\n', ...
            idx, patientID_test(idx), FM(idx), Correctness(idx), Completeness(idx));
    
    % Visualizzazione del miglior risultato
    testImage = imresize(imread(fullfile(testFolder, f_test(idx).name)), imageSize);
    GTImage = imresize(imread(fullfile(gtFolder, gt_test(idx).name)), imageSize);
    C_test = semanticseg(testImage, net_2A);
    G = C_test == 'B'; %mette massa in bianco
    
    figure;
    imshowpair(GTImage, G);
    title(sprintf('Miglior risultato Test - Frame %d (Paziente %d)', idx, patientID_test(idx)));
end
%% Peggiori 3 risultati su Test
% Ordina i frame validi in ordine crescente di FM (per selezionare i peggiori)
[~, sortedIdxTestWorst] = sort(FM_valid, 'ascend');
% Selezione dei peggiori 3 risultati associati a pazienti diversi
selectedFramesTestWorst = [];
selectedPatientsTestWorst = [];
for idx = sortedIdxTestWorst' % Scorri i frame ordinati in ordine crescente
    currentPatient = patientID_test_valid(idx);
    
    if ~ismember(currentPatient, selectedPatientsTestWorst)
        originalIdx = find(validIdx);
        selectedFramesTestWorst(end+1) = originalIdx(idx);
        selectedPatientsTestWorst(end+1) = currentPatient;
    end
    
    if length(selectedFramesTestWorst) == 3
        break;
    end
end
% Visualizzazione dei Peggiori 3 Risultati nei Test
disp('Peggiori risultati Test:');
for i = 1:3
    idx = selectedFramesTestWorst(i);
    fprintf('Frame %d (Paziente %d) - FM: %.4f, Correttezza: %.4f, Completezza: %.4f\n', ...
            idx, patientID_test(idx), FM(idx), Correctness(idx), Completeness(idx));
    
    % Visualizzazione del peggior risultato
    testImage = imresize(imread(fullfile(testFolder, f_test(idx).name)), imageSize);
    GTImage = imresize(imread(fullfile(gtFolder, gt_test(idx).name)), imageSize);
    C_test = semanticseg(testImage, net_2A);
    G = C_test == 'B';
    
    figure;
    imshowpair(GTImage, G);
    title(sprintf('Peggior risultato Test - Frame %d (Paziente %d)', idx, patientID_test(idx)));
end
%% Test su immagini di training
close all;
training_testFolder = 'C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\im_train2';
training_gtFolder = 'C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\gt_train2';
f_train = dir(fullfile(training_testFolder, '*.png'));
gt_train = dir(fullfile(training_gtFolder, '*.png'));
numImagesTrain = length(f_train);
FM_train = zeros(numImagesTrain, 1);
Correctness_train = zeros(numImagesTrain, 1);
Completeness_train = zeros(numImagesTrain, 1);
for l = 1:numImagesTrain
    fprintf('Processing training image %d/%d...\n', l, numImagesTrain);
    
    % Lettura dell'immagine di training e ground truth
    trainImage = imresize(imread(fullfile(training_testFolder, f_train(l).name)), imageSize);
    GTImage = imresize(imread(fullfile(training_gtFolder, gt_train(l).name)), imageSize);
    
    % Segmentazione con la rete neurale
    C_train = semanticseg(trainImage, net_2A);
    D = C_train == 'B';
    E = imfill(D, 'holes');
    F = imclose(E, strel('disk', 3));
    G = bwareafilt(F, 1);
    if ~isequal(size(G), size(GTImage))
        GTImage = imresize(GTImage, size(G));
    end
    % Valutazione della segmentazione
    [TP, FP, FN, Correctness_train(l), Completeness_train(l), FM_train(l)] = evaluation_segmentation(G, GTImage);
    % Visualizzazione dell'immagine segmentata
    imshowpair(trainImage, G);
    title(sprintf('Segmentazione Training - Frame %d', l));
    pause(0.001);
end
%% Migliori 3 risultati su Training
% Mappatura tra frame e pazienti per il dataset di training
numPatientsTrain = 30; % Numero totale di pazienti nel training
framesPerPatientTrain = 20; % Numero di frame per paziente
patientID_train = repelem(1:numPatientsTrain, framesPerPatientTrain); % Associazione frame-pazienti
% Gestione dei Valori NaN
% Trova i frame validi (senza NaN)
validIdx = ~isnan(FM_train) & ~isnan(Correctness_train) & ~isnan(Completeness_train);
% Filtra le metriche e le associazioni dei pazienti
FM_train_valid = FM_train(validIdx);
Correctness_train_valid = Correctness_train(validIdx);
Completeness_train_valid = Completeness_train(validIdx);
patientID_train_valid = patientID_train(validIdx);
% Ordina solo i frame validi
[~, sortedIdxTrain] = sort(FM_train_valid, 'descend');
% Selezione dei migliori 3 risultati associati a pazienti diversi
selectedFramesTrain = [];
selectedPatientsTrain = [];
for idx = sortedIdxTrain' % Scorri attraverso i frame ordinati
    currentPatient = patientID_train_valid(idx); % Paziente associato al frame corrente
    
    if ~ismember(currentPatient, selectedPatientsTrain) % Se il paziente non è già stato selezionato
        % Trova l'indice originale del frame nel dataset completo
        originalIdx = find(validIdx);
        selectedFramesTrain(end+1) = originalIdx(idx);
        selectedPatientsTrain(end+1) = currentPatient; % Segna il paziente come selezionato
    end
    
    if length(selectedFramesTrain) == 3 % Interrompi quando hai selezionato 3 frame
        break;
    end
end
% Visualizzazione dei migliori 3 risultati
disp('Migliori risultati Training:');
for i = 1:3
    idx = selectedFramesTrain(i);
    fprintf('Frame %d (Paziente %d) - FM: %.4f, Correttezza: %.4f, Completezza: %.4f\n', ...
            idx, patientID_train(idx), FM_train(idx), Correctness_train(idx), Completeness_train(idx));
    
    % Visualizzazione del miglior risultato
    trainImage = imresize(imread(fullfile(training_testFolder, f_train(idx).name)), imageSize);
    GTImage = imresize(imread(fullfile(training_gtFolder, gt_train(idx).name)), imageSize);
    C_train = semanticseg(trainImage, net_2A);
    G = C_train == 'B';
    
    figure;
    imshowpair(GTImage, G);
    title(sprintf('Miglior risultato Training - Frame %d (Paziente %d)', idx, patientID_train(idx)));
end
%% Peggiori 3 risultati su Training
% Ordina i frame validi in ordine crescente di FM (per selezionare i peggiori)
[~, sortedIdxTrainWorst] = sort(FM_train_valid, 'ascend');
% Selezione dei peggiori 3 risultati associati a pazienti diversi
selectedFramesTrainWorst = [];
selectedPatientsTrainWorst = [];
for idx = sortedIdxTrainWorst'
    currentPatient = patientID_train_valid(idx);
    
    if ~ismember(currentPatient, selectedPatientsTrainWorst)
        originalIdx = find(validIdx);
        selectedFramesTrainWorst(end+1) = originalIdx(idx);
        selectedPatientsTrainWorst(end+1) = currentPatient;
    end
    
    if length(selectedFramesTrainWorst) == 3
        break;
    end
end
% Visualizzazione dei Peggiori 3 Risultati nel Training
disp('Peggiori risultati Training:');
for i = 1:3
    idx = selectedFramesTrainWorst(i);
    fprintf('Frame %d (Paziente %d) - FM: %.4f, Correttezza: %.4f, Completezza: %.4f\n', ...
            idx, patientID_train(idx), FM_train(idx), Correctness_train(idx), Completeness_train(idx));
    
    % Visualizzazione del peggior risultato
    trainImage = imresize(imread(fullfile(training_testFolder, f_train(idx).name)), imageSize);
    GTImage = imresize(imread(fullfile(training_gtFolder, gt_train(idx).name)), imageSize);
    C_train = semanticseg(trainImage, net_2A);
    G = C_train == 'B';
    
    figure;
    imshowpair(GTImage, G);
    title(sprintf('Peggior risultato Training - Frame %d (Paziente %d)', idx, patientID_train(idx)));
end
%% metriche test
figure;
boxplot([FM, Correctness, Completeness], 'Labels', {'FM', 'Correttezza', 'Completezza'});
title('Distribuzione delle metriche sulle immagini di TEST');
ylabel('Valori');
grid on;
%violinplot
% Normalizzazione delle metriche per risultato migliore
FM = (FM - min(FM)) / (max(FM) - min(FM));
Correctness= (Correctness - min(Correctness)) / (max(Correctness) - min(Correctness));
Completeness = (Completeness - min(Completeness)) / (max(Completeness) - min(Completeness));
% Concatenazione di tutti i dati in un unico vettore numerico
ydata = [FM; Correctness; Completeness];
% Creazione del vettore dei gruppi (categorico)
xgroupdata = categorical(repelem(["FM", "CR", "CM"], 220));
% Creazione del violin plot
figure;
v = violinplot(xgroupdata, ydata); 

title('Distribuzione delle metriche su immagini di training');
ylabel('Valore');
xlabel('Metriche');
grid on;
%% metriche training

figure;
boxplot([FM_train, Correctness_train, Completeness_train], 'Labels', {'FM', 'Correttezza', 'Completezza'});
title('Distribuzione delle metriche sulle immagini di TRAINING');
ylabel('Valori');
grid on;
%violinplot
% Normalizzazione delle metriche
FM_train = (FM_train - min(FM_train)) / (max(FM_train) - min(FM_train));
Correctness_train = (Correctness_train - min(Correctness_train)) / (max(Correctness_train) - min(Correctness_train));
Completeness_train = (Completeness_train - min(Completeness_train)) / (max(Completeness_train) - min(Completeness_train));
% Concatenazione di tutti i dati in un unico vettore numerico
ydata = [FM_train; Correctness_train; Completeness_train];
% Creazione del vettore dei gruppi (categorico)
xgroupdata = categorical(repelem(["FM", "CR", "CM"], 600));
% Creazione del violin plot
figure;
v = violinplot(xgroupdata, ydata); % Creazione del violin plot

title('Distribuzione delle metriche su immagini di training');
ylabel('Valore');
xlabel('Metriche');
grid on;