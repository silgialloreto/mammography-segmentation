%% dividi in training e test
clear all; close all; clc;

[path_im]=uigetdir(pwd,'Select the directory with images...');  %apre finestra per selezionare cartella
[path_gt]=uigetdir(pwd,'Select the directory with gt...');
images_list=dir(fullfile(path_im,'\*.pgm')); %array di strutture
gt_list=dir(fullfile(path_gt,'\*.pgm'));

%verifica visiva
%for i = 1 : 200 : length(images_list)
    %I=im2double(imread(fullfile(images_list(i).folder,images_list(i).name)));
    %GT=im2double(imread(fullfile(gt_list(i).folder,gt_list(i).name)));
    %imshowpair(I,GT);
    %pause(0.5); 
    %hold off;
%end

%% metodo  
Ndata=length(images_list);

idx_train=1: 600;
idx_test=601:Ndata;

images_train=images_list(idx_train);
gt_train=gt_list(idx_train);

images_test=images_list(idx_test);
gt_test=gt_list(idx_test);

%% commenta tutto
close all; 
for i = 1 : length(images_train)
    I=im2double(imread(fullfile(images_train(i).folder,images_train(i).name)));
    GT=im2double(imread(fullfile(gt_train(i).folder,gt_train(i).name)));
    subplot(1,2,1); imshow(I);
    subplot(1,2,2); imagesc(GT); axis equal; axis ij; 
    pause(); 
    hold off;
end

 
close all; 
for i = 1 : length(images_test)
    I=im2double(imread(fullfile(images_test(i).folder,images_test(i).name)));
    GT=im2double(imread(fullfile(gt_test(i).folder,gt_test(i).name)));
    subplot(1,2,1); imshow(I);
    subplot(1,2,2); imagesc(GT); axis equal; axis ij; 
    pause(); 

    hold off;
end

%% Salvataggio delle immagini GT_train
close all;
for i = 1 : length(gt_train)
    GT=im2double(imread(fullfile(gt_train(i).folder, gt_train(i).name))); 
    [~, name, ~] = fileparts(gt_train(i).name); % Ottieni il nome del file senza estensione
    imwrite(GT,fullfile('C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\gt_train2',[name '.png']));
    A=imshow(GT);
end

%% Salvataggio delle immagini GT_test
close all;
for i = 1 : length(gt_test)
    GT=im2double(imread(fullfile(gt_test(i).folder, gt_test(i).name))); 
    [~, name, ~] = fileparts(gt_test(i).name); % Ottieni il nome del file senza estensione
    imwrite(GT,fullfile('C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\gt_test2',[name '.png']));
    A=imshow(GT);
end

%% Salvataggio images_train
close all;
for i = 1 : length(images_train)
    IMAGES=im2double(imread(fullfile(images_train(i).folder,images_train(i).name)));
    IMAGES_adjusted = imadjust(IMAGES);
    figure()
    
   [~, name, ~] = fileparts(images_train(i).name);
   imwrite(IMAGES_adjusted, fullfile('C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\im_train2', [name '.png']));  
   %pause(0.01);
   hold off;  
end

%% Aumento contrasto e salvataggio TEST
close all;
for i = 1 : length(images_test)
    IMAGES=im2double(imread(fullfile(images_test(i).folder,images_test(i).name)));
    IMAGES_adjusted = imadjust(IMAGES);
    figure()
   
   [~, name, ~] = fileparts(images_test(i).name);
   imwrite(IMAGES_adjusted, fullfile('C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\im_test2', [name '.png']));
   %pause(0.1);
   hold off;  
end