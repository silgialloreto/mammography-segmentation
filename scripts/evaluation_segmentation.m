function [TP,FP,FN,CR,CM,FM]=evaluation_segmentation(BW,GT)
% BW is the algorithm result
% GT is the ground truth

TP=sum(BW(:)==1 & GT(:)==1); % TP=sum(ALG(:).*BW(:));
FP=sum(BW(:)==1 & GT(:)==0); % sovrasegmentazione 
FN=sum(BW(:)==0 & GT(:)==1); % sottosegmentazione

CR=TP/(TP+FP); % metrica di sovrasegmentazione = 1 se non sovrasegmento
CM=TP/(TP+FN); % metrica di sottosegmentazione = 1 se non sottosegmento
FM=2*CM*CR/(CM+CR);