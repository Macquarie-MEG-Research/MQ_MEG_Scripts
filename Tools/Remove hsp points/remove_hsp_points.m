% remove_hsp_points: graphical selection of data points on a plot using the built in brush tool via mouse
% overwrites .hsp file and saves old one with the suffix _OLD
% Paul Sowman
% August 2018


function remove_hsp_points(f_name) %fname of .hsp without extension as a string

close all
pendStr2 = '.hsp';
f_name2  = [f_name,pendStr2];
copyfile(f_name2,[cd,'/',f_name,'_OLD',pendStr2]);

fid2             = fopen(f_name2);
C                = fscanf(fid2,'%c');
fclose(fid2);

E                = regexprep(C,'\r','xx'); %replace returns with "xx"
E                = regexprep(E,'\t','yy'); %replace tabs with "yy"
returnsi         = strfind(E,'xx');
tabsi            = strfind(E,'yy');
headshapestarti  = strfind(E,'position of digitized points');
headshapestartii = strfind(E(headshapestarti(1):end),'xx');
headshape        = E(headshapestarti(1)+headshapestartii(2)+2:end);
headshape        = regexprep(headshape,'yy','\t');
headshape        = regexprep(headshape,'xx','');
headshape        = str2num(headshape);

h = scatter3(xyz(:,1),xyz(:,2),xyz(:,3));
hold on
pause

selected   = [headshape(find(h.BrushData),1),headshape(find(h.BrushData),2),headshape(find(h.BrushData),3)];
headshape2 = setdiff(headshape,selected,'rows');
scatter3(headshape(find(h.BrushData),1),headshape(find(h.BrushData),2),headshape(find(h.BrushData),3),'*w')
hold off

close all
figure
subplot(2,1,1)
scatter3(headshape(:,1),headshape(:,2),headshape(:,3))
subplot(2,1,2)
scatter3(headshape2(:,1),headshape2(:,2),headshape2(:,3))

G = regexp(C,'\t3');
G = C(1:G+1);
G = strcat(G(1:regexp(C,'position of digitized points')+length('position of digitized points')-1),...
    sprintf('\r%g\t%g',[size(headshape2,1) size(headshape2,2)]));
for j = 1:length(headshape2)
G = strcat(G,sprintf('\r%g\t%g\t%g',headshape2(j,:)));
end

fid = fopen(f_name2,'w'); %Open file. Note that this will discard existing data!
fwrite(fid, G, 'uchar'); %write data
fclose(fid); %
end