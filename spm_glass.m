function fig = spm_glass(X,pos,varargin)
% Glass brain plot
% FORMAT fig = spm_glass(X,pos,S)
%   X               - (REQUIRED) values to be painted
%   pos             - (REQUIRED) coordinates in MNI head (not voxel) space
%   S               - (optional) config structure
% Fields of S:
%   S.brush         - brush size                   - Default: 0
%   S.cmap          - colormap of plot             - Default: 'gray'
%   S.dark          - dark mode                    - Default: false
%   S.detail        - glass brain detail level:     
%                     0=LOW, 1=NORMAL, 2=HIGH      - Default: 1
% Output:
%   fig             - Handle for generated figure
%__________________________________________________________________________
% Copyright (C) 2020 Wellcome Centre for Human Neuroimaging

% George O'Neill
% $Id$

% prep
%---------------------------------------------------------------------
switch nargin
    case 1
        error('need at least two arguments, values, and positions!')
    case 2
        S = [];
    case 3
        S = varargin{1};
end

assert(length(X) == length(pos), ['number of values do not match '...
    'number of poistions!']);

if ~isfield(S, 'brush'),     S.brush = 0; end
if ~isfield(S, 'dark'),      S.dark = false; end
if ~isfield(S, 'cmap'),      S.cmap = 'gray'; end
if ~isfield(S, 'detail'),    S.detail = 1; end


V = spm_vol(fullfile(spm('dir'),'canonical','avg152T1.nii'));
pos = ceil(ft_warp_apply(inv(V.mat),pos));

if sum(X<0) & sum(X>0)
    div = 1;
    S.cmap = 'rdbu';
else 
    div = 0;
end

[~,id] = sort(abs(X),'ascend');
if div
    [~,bin] = histc(X,linspace(-max(abs(X)),max(abs(X)),65));
else
    [~,bin] = histc(X,linspace(min(abs(X)),max(abs(X)),65));
end

% saggital plane
%----------------------------------------------------------------------
p = NaN(V.dim(2),V.dim(3));

for ii = 1:length(id)
    
    pnt = [pos(id(ii),2),pos(id(ii),3)];
    bnd = -S.brush:S.brush;
    p(pnt(1)+bnd,pnt(2)+bnd) = bin(id(ii));
    
end

subplot(221);
imagesc(rot90(p,1))
overlay_glass_brain('side',S.dark,S.detail);

% coronal plane
%----------------------------------------------------------------------
p = NaN(V.dim(1),V.dim(3));

for ii = 1:length(id)
    
    pnt = [pos(id(ii),1),pos(id(ii),3)];
    bnd = -S.brush:S.brush;
    p(pnt(1)+bnd,pnt(2)+bnd) = bin(id(ii));
    
end

subplot(222);
imagesc(fliplr(rot90(p,1)))
overlay_glass_brain('back',S.dark,S.detail);

% axial plane
%----------------------------------------------------------------------
p = NaN(V.dim(2),V.dim(1));

for ii = 1:length(id)
    
    pnt = [pos(id(ii),2),pos(id(ii),1)];
    bnd = -S.brush:S.brush;
    p(pnt(1)+bnd,pnt(2)+bnd) = bin(id(ii));
    
end

subplot(223);
imagesc(rot90(p,1))
overlay_glass_brain('top',S.dark,S.detail);


% common features
%---------------------------------------------------------------------
for ii = 1:3
    subplot(2,2,ii)
    set(gca,'XTickLabel',{},'YTickLabel',{});
    axis image
    grid on
    caxis([0 64])
end

c = feval(S.cmap,64);
if S.dark
    c(1,:) = [0 0 0];
else
    c = flipud(c);
    c(1,:) = [1 1 1];
end
colormap(c);
if S.dark
    set(gcf,'color','k');
else
    set(gcf,'color','w');
end
fig = gcf;

end

% supporting functions
%---------------------------------------------------------------------

function overlay_glass_brain(orient,dark,detail)

load(fullfile(spm('dir'),'glass_brain.mat'));

dat = glass.(orient);

switch orient
    case 'top'
        xform = [0 -1 0; 1 0 0; 0 0 1]*[0.185 0 0; 0 0.185 0; 10.5 82 1];
    case 'back'
        xform = [0.185 0 0; 0 -0.185 0; 11 89 1];
    case 'side'
        xform = [0.185 0 0; 0 -0.185 0; 10.5 89 1];
end

for ii = 1:length(dat.paths)
    pth = dat.paths(ii);
    % see if we need to draw based on the complexity option
    switch detail
        case 0
            draw = pth.linewidth > 1 & sum(hex2rgb(pth.edgecolor))==0;
        case 1
            draw = sum(hex2rgb(pth.edgecolor))==0;
        otherwise
            draw = 1;
    end
    
    if draw
        for jj = 1:length(pth.items)
            pts = pth.items(jj).pts;
            v = [generate_bezier(pts) ones(10,1)];
            v2 = v*xform;
            f = [1:(length(v)-1); 2:length(v)]';
            
            if dark
                c = 1 - hex2rgb(pth.edgecolor);
            else
                c = hex2rgb(pth.edgecolor);
            end
            
            patch('faces',f,'vertices',v2(:,1:2),'linewidth',pth.linewidth,'edgecolor',c);
        end
    end
end

end

function [points, t] = generate_bezier(controlPts, varargin)

% bezier generation from control poits based on code by
% Adrian V. Dalca, https://www.mit.edu/~adalca/
% https://github.com/adalca/bezier

% estimate nDrawPoints
if nargin == 1
    nCurvePoints = 10;
else
    nCurvePoints = varargin{1};
end

% curve parametrization variable
t = linspace(0, 1, nCurvePoints)';

% detect the type of curve (linear, quadratic, cubic) based on the
% number of points given in controlPts.
switch size(controlPts, 1)
    case 1
        error('Number of Control Points should be at least 2');
        
    case 2
        % linear formula
        points = (1 - t) * controlPts(1, :) + ...
            t * controlPts(2, :);
        
    case 3
        % quadratic formula
        points = ((1 - t) .^ 2) * controlPts(1, :) + ...
            (2 * (1 - t) .* t) * controlPts(2, :) + ...
            (t .^ 2) * controlPts(3, :);
        
    case 4
        % cubic formula
        points =  ((1 - t) .^ 3) * controlPts(1, :) + ...
            (3 * (1 - t) .^ 2 .* t) * controlPts(2, :) + ...
            (3 * (1 - t) .* t .^ 2) * controlPts(3, :) + ...
            (t .^ 3) * controlPts(4, :);
        
        %     otherwise
        %         % compute using the recursive formula (but avoid recursion)
        %         [count, dim] = size(controlPts);
        %
        %         % compute 4th diagonal
        %         ptscomp = cell(count, count);
        %         for i = 1:(count - 4 + 1)
        %             ptscomp{i, i+3} = generate_bezier(controlPts(i:i+4-1, :), nCurvePoints);
        %         end
        %
        %         % compute every diagonal after that
        %         for i = 5:count
        %             for j = 1:(count - i + 1)
        %                 % use the entry to the left (ptscomp{j, i+j-2}) and below (ptscomp{j+1, i+j-1})
        %                 ptscomp{j, i+j-1} =  repmat(1 - t, [1, dim]) .* ptscomp{j, i+j-2} + ...
        %                     repmat(t, [1, dim]) .* ptscomp{j+1, i+j-1};
        %
        %                 % clean up the entry to the left (this is necessary if we have huge number of control pts)
        %                 ptscomp{j, i + j - 2} = [];
        %             end
        %         end
        %
        %         % finally, get our points:
        %         points = ptscomp{1, end};
end

% verify dimensions
assert(size(points, 2) == size(controlPts, 2));
end

function dst = ssd(v1, v2)
% sum of squared difference
ds = (v1 - v2) .^ 2;
dst = sum(ds);
end

function rgb = hex2rgb(hex)
% converts hex string to matlab rgb triplet
if strcmpi(hex(1,1),'#')
    hex(:,1) = [];
end
rgb = reshape(sscanf(hex.','%2x'),3,[]).'/255;
end

function cmap = rdbu(varargin)

if ~nargin
    ncols = 256;
else
    ncols = varargin{1};
end

cmaptemp = [178,24,43
    214,96,77
    244,165,130
    253,219,199
    247,247,247
    209,229,240
    146,197,222
    67,147,195
    33,102,172]./255;

len = length(cmaptemp);
oldsteps = linspace(0, 1, len);
newsteps = linspace(0, 1, ncols);
cmap = zeros(ncols, 3);

for i=1:3
    % Interpolate over RGB spaces of colormap
    cmap(:,i) = min(max(interp1(oldsteps, cmaptemp(:,i), newsteps)', 0), 1);
end

end