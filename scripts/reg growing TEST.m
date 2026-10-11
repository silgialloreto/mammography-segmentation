%% region growing TEST
clear all; close all; clc;
[im_test2,dir_f]=uigetfile(pwd,'Select an image','*.*');
A=im2double(imread([dir_f,im_test2]));
if length(size(A))>2
    A=rgb2gray(A);
end
figure();
imshow(A);

[gt_test2,dir_f]=uigetfile(pwd,'Select an image','*.*');
GT=im2double(imread(fullfile(dir_f,gt_test2)));
 
figure();
imhist(A);
%% aumento contrasto

A_cont=imadjust(A,[0.7 0.85],[0 1], 8);
figure();
imshow(A_cont);

%% region growing

[xi]=drawpoint();
[seg_rg]=my_regiongrowing(A_cont,round(xi.Position(2)),round(xi.Position(1)),0.34);
hold off;
seg_rg=imfill(seg_rg,'holes'); 
figure(); 
imshowpair(seg_rg,GT); title('RG');


%% Valutazione parametri

[TP,FP,FN,CR_rg,CM_rg,FM_rg]=evaluation_segmentation(seg_rg,GT);

%% violin plot
%  11 valori per ogni metrica
FM_rg = [0.74, 0.085, 0.60, 0.76, 0.85, 0.87, 0.63, 0.79, 0.77, 0.79, 0.89];
CM_rg = [0.68, 0.04, 0.67, 0.77, 0.92, 0.92, 0.48, 0.82, 0.97, 0.67, 0.81];
CR_rg = [0.81, 1, 0.55, 0.76, 0.79, 0.82, 0.91, 0.76, 0.64, 0.97, 0.98];

FM_rg = FM_rg(:); % Assicuriamoci che sia una colonna
CM_rg = CM_rg(:); 
CR_rg = CR_rg(:); 
% Concatenazione di tutti i dati in un unico vettore numerico
ydata = [FM_rg; CR_rg; CM_rg]; % Deve essere un vettore DOUBLE (33x1)
% Creazione del vettore dei gruppi 
xgroupdata = categorical(repelem(["FM", "CR", "CM"], 11)); % Deve essere 33x1 e categorico, ripete 11 volte

% Creazione del violin plot
figure;
v = violinplot(xgroupdata, ydata); 

% Aggiungi etichette
title('Distribuzione delle metriche su 11 immagini di test');
ylabel('Valore');
xlabel('Metriche');
grid on;

%% box plot
FM_rg = [0.74, 0.085, 0.60, 0.76, 0.85, 0.87, 0.63, 0.79, 0.77, 0.79, 0.89];
CM_rg = [0.68, 0.04, 0.67, 0.77, 0.92, 0.92, 0.48, 0.82, 0.97, 0.67, 0.81];
CR_rg = [0.81, 1, 0.55, 0.76, 0.79, 0.82, 0.91, 0.76, 0.64, 0.97, 0.98];

% Organizzazione dei dati in una matrice
data_matrix = [FM_rg(:), CR_rg(:), CM_rg(:)]; % Ogni colonna rappresenta una metrica
% Creazione del Box Plot
figure;
boxplot(data_matrix, {'FM', 'CR', 'CM'}); 
title('Distribuzione delle metriche su 11 immagini di test');
ylabel('Valore');
xlabel('Metriche');
grid on;

%% POST-PROCESSAMENTO finale con variazione della maschera quadrata

eccentricity_vals = []; %crea vettore vuoto
circularity_vals = [];
solidity_vals = [];
extent_vals = [];
mask_sizes = 1:7; % Variazione della dimensione della maschera quadrata
figure;
subplot(3,3,1); imshow(seg_rg); title('Originale');
% Loop per variare la dimensione della maschera quadrata
for k = mask_sizes
    % Creazione della maschera quadrata
    B = strel('square', k);
    
    % Applica operazione morfologica di chiusura per ridurre piccoli buchi
    GT2 = imclose(seg_rg, B);
    
    % Calcola le proprietà dell'oggetto segmentato
    R = regionprops(logical(GT2), 'Area', 'BoundingBox', 'ConvexArea', 'Eccentricity', 'Perimeter');
    % Se non ci sono oggetti segmentati, salta l'iterazione
    if isempty(R)
        eccentricity_vals = [eccentricity_vals; NaN];
        circularity_vals = [circularity_vals; NaN];
        solidity_vals = [solidity_vals; NaN];
        extent_vals = [extent_vals; NaN];
        continue;
    end
    % Estrai le feature
    Area_seg = R.Area; % Area della massa
    Area_BB = R.BoundingBox(3) * R.BoundingBox(4); % Area del bounding box
    Area_CH = R.ConvexArea; % Area della busta convessa
    % Calcoli delle feature
    Extent = Area_seg / Area_BB; % Rapporto tra area della massa e bounding box
    Solidity = Area_seg / Area_CH; % Compattezza della massa
    Eccentricity = R.Eccentricity; % Quanto la massa è allungata
    Circularity = (4 * pi * Area_seg) / (R.Perimeter^2); % Quanto la forma è circolare
    % Salva i risultati nei vettori
    eccentricity_vals = [eccentricity_vals; Eccentricity];
    circularity_vals = [circularity_vals; Circularity];
    solidity_vals = [solidity_vals; Solidity];
    extent_vals = [extent_vals; Extent];
    % Mostra il risultato per ogni dimensione della maschera
    subplot(3,3,k+1);
    imshow(GT2);
    title(['Maschera ', num2str(k)]);
end
% Grafico delle feature rispetto alla dimensione della maschera
figure;
plot(mask_sizes, eccentricity_vals, '-o', 'LineWidth', 2, 'DisplayName', 'Eccentricità');
hold on;
plot(mask_sizes, circularity_vals, '-s', 'LineWidth', 2, 'DisplayName', 'Circolarità');
plot(mask_sizes, solidity_vals, '-d', 'LineWidth', 2, 'DisplayName', 'Solidity');
plot(mask_sizes, extent_vals, '-^', 'LineWidth', 2, 'DisplayName', 'Extent');
hold off;
xlabel('Dimensione della Maschera Quadrata');
ylabel('Valore della Feature');
title('Andamento delle Feature in base alla Dimensione della Maschera');
legend;
grid on;

%% POST-PROCESSAMENTO finale
% morphological
B=strel('square',4);
%GT1=imopen(seg_rg,B);
%figure();
%imshow(GT1);
figure();
imshow(seg_rg);
GT2=imclose(seg_rg,B);
figure();
imshow(GT2);

%% features extraction
R=regionprops(logical(GT2),'All');
close all;
imshow(GT2);
hold on;
drawrectangle('Position',R.BoundingBox);
Area_BB=R.BoundingBox(3)*R.BoundingBox(4);
Area_seg_rg=R.Area;
Extent = Area_seg_rg/Area_BB;
hold on;
drawpolygon('Position',R.ConvexHull);
Area_CH=R.ConvexArea;
Solidity = Area_seg_rg/Area_CH;

%% ribbon extraction (bordi)
Id=im2double(A_cont);

B=strel('square',4);
seg_rg_int=imerode(seg_rg,B);
seg_rg_ext=imdilate(seg_rg,B);
ribbon=seg_rg_ext-seg_rg_int;

figure(); imshow(ribbon);
figure(); imshow(Id.*ribbon);

Id_ribbon=Id.*ribbon; %ribbon dell'immagine in scala di grigio e non binaria
mean_rib=mean(Id_ribbon(ribbon == 1));
std_rib=std(Id_ribbon(ribbon == 1));

%cv  del ribbon
cv_ribbon = (std_rib / mean_rib) * 100;
fprintf('Coefficiente di Variazione del Ribbon: %.2f%%\n', cv_ribbon);

%% scatter plot circ e solidity
Circ_M = [0.2, 0.55, 0.4, 0.55, 0.3]; %0.65];
Circ_B = [0.5, 0.6, 0.65, 0.5, 0.8];

Ecc_M = [0.25, 0.7, 0.5, 0.65, 0.8]; %0.45];
Ecc_B = [0.55, 0.6, 0.65, 0.6, 0.6];

figure;
scatter(Circ_M, Ecc_M, 'ro', 'filled'); % Maligne in rosso
hold on;
scatter(Circ_B, Ecc_B, 'bo', 'filled'); % Benigne in blu
hold off;
xlabel('Circolarità');
ylabel('Eccentricità');
legend('Maligne', 'Benigne');
title('Scatter Plot: Circolarità vs Eccentricità');
grid on;

%% box plot di tutte e due
% Creazione di un unico vettore di feature con categorie
features = [Circ_M, Circ_B, Ecc_M, Ecc_B];
data_matrix = [Circ_M(:), Circ_B(:), Ecc_M(:), Ecc_B(:)]; % Ogni colonna rappresenta una metrica
% Creazione del Box Plot
figure;
boxplot(data_matrix, {'Circolarità_M', 'Circolarità_B', 'Eccentricità_M', 'Eccentricità_B'}); % Etichette delle metriche
title('Box plot Circolarità ed Eccentricità');
ylabel('Valore');
xlabel('Features');
grid on;

%% boxplot CV ribbon (non discriminante)
% Dati di Solidity per masse Maligne e Benigne
CVribbon_M = [0.78, 0.72, 0.38, 0.76, 0.68, 0.3]; % Maligne
CVribbon_B = [0.64, 0.74, 1.05, 0.37, 0.42]; % Benigne

% Unisci tutti i dati in un unico vettore
CVribbon_values = [CVribbon_M, CVribbon_B];

% Crea un vettore di etichette per ciascun valore
labels = [repmat("Maligne", 1, length(CVribbon_M)), repmat("Benigne", 1, length(CVribbon_B))];

% Converte le etichette in tipo categorico per il Box Plot
labels = categorical(labels);

% Creazione del Box Plot corretto
figure;
boxplot(CVribbon_values, labels);
ylabel('CV Ribbon');
xlabel('Tipo di Massa');
title('Distribuzione del CV del ribbon per Masse Benigne e Maligne');
grid on;