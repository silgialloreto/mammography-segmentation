%% region growing TRAINING
clear all; close all; clc;
[im_train2,dir_f]=uigetfile(pwd,'Select an image','*.*');
A=im2double(imread([dir_f,im_train2]));
if length(size(A))>2
    A=rgb2gray(A);
end
figure();
imshow(A);

[gt_train2,dir_f]=uigetfile(pwd,'Select an image','*.*');
GT=im2double(imread(fullfile(dir_f,gt_train2)));

figure();
imhist(A);

%% aumento contrasto

A_cont=imadjust(A,[0.5 0.9],[0 1], 0.8);
figure();
imshow(A_cont);
%B=medfilt2(A_cont);
%figure;
%imshow(B);
%figure;
%imshow(GT)

%% region growing
[xi]=drawpoint();
[seg_rg]=my_regiongrowing(A_cont,round(xi.Position(2)),round(xi.Position(1)),0.1);
hold off;
seg_rg=imfill(seg_rg,'holes'); 
figure(); 
imshowpair(seg_rg,GT); title('RG');

%% Valutazione parametri

[TP,FP,FN,CR_rg,CM_rg,FM_rg]=evaluation_segmentation(seg_rg,GT);


%% Violin Plot
% Abbiamo i 30 valori per ogni metrica
FM_rg = [0.84, 0.54, 0.84, 0.88, 0.79, 0.84, 0.92, 0.7, 0.78, 0.78, ...
         0.9, 0.89, 0.89, 0.61, 0.81, 0.87, 0.51, 0.63, 0.80, 0.81, ...
         0.92, 0.85, 0.83, 0.72, 0.61, 0.6, 0.8, 0.95, 0.7, 0.86];
CM_rg = [0.76, 0.54, 0.8, 0.88, 0.8, 0.82, 0.91, 0.69, 0.69, 0.68, ...
         0.84, 0.75, 0.83, 0.44, 0.77, 0.84, 0.37, 0.63, 0.8, 0.78, ...
         0.93, 0.9, 0.84, 0.57, 0.51, 0.45, 0.71, 0.93, 0.63, 0.92];
CR_rg = [0.94, 0.8, 0.89, 0.89, 0.78, 0.85, 0.92, 0.72, 0.9, 0.91, ...
         0.98, 0.9, 0.97, 0.99, 0.85, 0.91, 0.85, 0.63, 0.8, 0.85, ...  
         0.9, 0.81, 0.81, 0.97, 0.76, 0.94, 0.9, 0.96, 0.8, 0.8];
% Dati delle metriche (FM, CR, CM)
FM_rg = FM_rg(:); % Assicuriamoci che sia una colonna
CM_rg = CM_rg(:); % Assicuriamoci che sia una colonna
CR_rg = CR_rg(:); % Assicuriamoci che sia una colonna
% Concatenazione di tutti i dati in un unico vettore numerico
ydata = [FM_rg; CR_rg; CM_rg]; % Deve essere un vettore DOUBLE (90x1)
% Creazione del vettore dei gruppi (categorico)
xgroupdata = categorical(repelem(["FM", "CR", "CM"], 30)); % crea variabili categoriche (stringhe) e le ripete 30 volte

% Creazione del violin plot
figure;
v = violinplot(xgroupdata, ydata); % Creazione del violin plot

% Aggiungi etichette
title('Distribuzione delle metriche su 30 immagini di training');
ylabel('Valore');
xlabel('Metriche');
grid on;

%% Box plot

FM_rg = [0.84, 0.54, 0.84, 0.88, 0.79, 0.84, 0.92, 0.7, 0.78, 0.78, ...
         0.9, 0.89, 0.89, 0.61, 0.81, 0.87, 0.51, 0.63, 0.80, 0.81, ...
         0.92, 0.85, 0.83, 0.72, 0.61, 0.6, 0.8, 0.95, 0.7, 0.86];
CM_rg = [0.76, 0.54, 0.8, 0.88, 0.8, 0.82, 0.91, 0.69, 0.69, 0.68, ...
         0.84, 0.75, 0.83, 0.44, 0.77, 0.84, 0.37, 0.63, 0.8, 0.78, ...
         0.93, 0.9, 0.84, 0.57, 0.51, 0.45, 0.71, 0.93, 0.63, 0.92];
CR_rg = [0.94, 0.8, 0.89, 0.89, 0.78, 0.85, 0.92, 0.72, 0.9, 0.91, ...
         0.98, 0.9, 0.97, 0.99, 0.85, 0.91, 0.85, 0.63, 0.8, 0.85, ...  
         0.9, 0.81, 0.81, 0.97, 0.76, 0.94, 0.9, 0.96, 0.8, 0.8];

% Organizzazione dei dati in una matrice
data_matrix = [FM_rg(:), CR_rg(:), CM_rg(:)]; 

% Creazione del Box Plot
figure;
boxplot(data_matrix, {'FM', 'CR', 'CM'}); 
title('Distribuzione delle metriche su 30 immagini di training');
ylabel('Valore');
xlabel('Metriche');
grid on;



