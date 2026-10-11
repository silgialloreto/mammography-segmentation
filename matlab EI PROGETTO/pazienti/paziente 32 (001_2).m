%% region growing TRAINING
clear all; close all; clc;
[im_train2,dir_f]=uigetfile(pwd,'Select an image','*.*');
A=im2double(imread([dir_f,im_train2]));
if length(size(A))>2
    A=rgb2gray(A);
end
figure();
set(gcf,'WindowStyle','dock');
imshow(A);

[gt_train2,dir_f]=uigetfile(pwd,'Select an image','*.*');

figure(); 
histogram(A(:),256); 
figure();
imhist(A);

%% aumento contrasto

A_cont=imadjust(A,[0.95 1],[0 1], 3);
figure();
imshow(A_cont);

%% region growing
GT=im2double(imread(fullfile(dir_f,gt_train2)));
[xi]=drawpoint();
[seg_rg]=my_regiongrowing(A_cont,round(xi.Position(2)),round(xi.Position(1)),0.85);
hold off;
seg_rg=imfill(seg_rg,'holes'); 
figure(); 
set(gcf,'WindowStyle','dock');
imshowpair(seg_rg,GT); title('RG');

%% Valutazione parametri
%imshowpair(seg_rg,GT); title('RG');
[TP,FP,FN,CR_rg,CM_rg,FM_rg]=evaluation_segmentation(seg_rg,GT);