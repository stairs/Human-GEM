%
% FILE NAME:    Recon3Rxns2HMR.m
% 
% DATE CREATED: 2018-05-28
% 
% PROGRAMMER:   Hao Wang
%               Department of Biology and Biological Engineering
%               Chalmers University of Technology
% 
% 
% PURPOSE: This script attempts to assign proper HMR id(s) to each
%          Recon3D rxn, and output the association into a defined
%          array structure.
%

% Load rxn association from HMR2 and Recon3D to MNX
load('Recon3Rxns2MNX.mat');    %Recon3D rxn association to MNX
load('ihumanRxns2MNX.mat');    %HMR rxn association to MNX

% Add assocation based on BiGG database
Recon3D.BiGG2HMR=cell(numel(Recon3D.rxns),1);
Recon3D.BiGG2HMR(:)={''};
index=find(~cellfun(@isempty,Recon3D.rxnBiGGID));
[a, b]=ismember(Recon3D.rxnBiGGID(index),ihuman.HMR2BiGG);
I=find(a);
Recon3D.BiGG2HMR(index(I))=ihuman.rxns(b(I));
numel(find(~cellfun(@isempty,Recon3D.BiGG2HMR)))  % ans = 4522
% Check consistency
indexBiGG=find(~cellfun(@isempty,Recon3D.BiGG2HMR));
indexHMR=find(~cellfun(@isempty,Recon3D.rxnHMRID));
overlap=intersect(indexBiGG,indexHMR);
ind=find(~cellfun(@isequal,Recon3D.BiGG2HMR(overlap),Recon3D.rxnHMRID(overlap)));
fprintf('%s: %s-%s\n',num2str(overlap(ind)),Recon3D.BiGG2HMR{overlap(ind)},Recon3D.rxnHMRID{overlap(ind)});
% 11741: HMR_8671-HMR_6533
% Keep the direct association based on Recon3 rxn id and remove the other one
Recon3D.BiGG2HMR{11741}='';
% These BiGG association seem to be problematic


% Add assocation based on MNX database

% Prepare the rxnCompIdx field to represent the rxn compartment info, 
% because the rxnComps field cannot accurately descirbe cases, such as
% the reactions involve multiple compartments (e.g. exchagne/transport)

load('Recon3DRaven.mat');    %Load Recon3D in RAVEN format
Recon3D.rxnCompIdx=addRxnCompIdx(Recon3DRaven);
ihuman.rxnCompIdx=addRxnCompIdx(ihuman);

% Get additional Recon3D-HMR2 association using MNX association and
% compartment info, and then assign mapping results to rxnHMRID field
load('mergedModel.mat');
checkOccur=zeros(numel(Recon3D.rxns),1);
for i=1:numel(Recon3D.rxns)
		% Consider the rxns with MNX association and without HMR association
		if isempty(Recon3D.rxnHMRID{i}) && ~isempty(Recon3D.rxnMNXID{i})
				%attempt to get the HMR assoc
				for j=1:numel(mergedModel.rxns)
						if ismember(Recon3D.rxnMNXID{i},mergedModel.confirmedMNXID{j})
								rxns=[{};mergedModel.rxns{j}];
								if ~isempty(mergedModel.duplicateRxns{j}) && ~ismember(mergedModel.rxns{j},{'HMR_8771','HMR_1592'})
										rxns=[rxns;transpose(strsplit(mergedModel.duplicateRxns{j},';'))];
								end
								
								% Specify rxn assoc using compartment index
								for k=1:numel(rxns)
										index=find(strcmp(rxns{k},ihuman.rxns));
										if isequal(ihuman.rxnCompIdx{index},Recon3D.rxnCompIdx{i})

												if isempty(Recon3D.rxnHMRID{i})
														Recon3D.rxnHMRID{i}=ihuman.rxns{index};
												else
														%Allow multiple HMR associations to one Recon3D rxn
														Recon3D.rxnHMRID{i}=strcat(Recon3D.rxnHMRID{i},';',ihuman.rxns{index});
												end
										end		
								end
								
						end
				end
		end		
end
numel(find(~cellfun(@isempty,Recon3D.rxnHMRID)))  % ans = 4998

save('Recon3Rxns2HMR.mat','Recon3D');    %Save the information for merging

%===============
%% sub functions
% add compIdx field to accurately represent the rxn compartment info
function compIdx = addRxnCompIdx(model)
		compIdx=cell(numel(model.rxns),1);
		compIdx(:)={''};
		for i=1:numel(model.rxns)
				compIdx{i}=unique(model.metComps(find(model.S(:,i))));
		end
end
