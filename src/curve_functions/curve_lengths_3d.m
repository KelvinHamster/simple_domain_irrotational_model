function v_seglens = curve_lengths_3d(V,interp_scheme)
%Calculates the interpolated curve lengths between each node.
% 
%   V - 3xN matrices, where each column represents a point in 3d space
%
%   interp_scheme - string to represent how V should be interpolated. The options are:
%       'linear' - does linear interpolation
%       'sliding3' - 3rd order (4 node) lagrange interpolation
%       'sliding5' - 5rd order (6 node) lagrange interpolation
%       'spline' - does spline interpolation
%
v_pts = size(V,2);
dims = size(V,1);

%handle scheme
mode = 0; mode_M = 0;
if strcmp(interp_scheme,'linear')
    mode = 1;
    sld_seg = get_interpolation_struct(1,0,1);
    mode_M = 1;
elseif strcmp(interp_scheme,'sliding3')
    mode = 1;
    sld_seg = get_interpolation_struct(3,0,3);
    mode_M = 3;
elseif strcmp(interp_scheme,'sliding5')
    mode = 1;
    sld_seg = get_interpolation_struct(5,0,5);
    mode_M = 5;
end

%spline; generate
if mode == 0
    v_spline = zeros(dims,v_pts-1,4);
    for i = 1:dims
        v_spline(i,:,:) = csape(1:v_pts,V(i,:)).coefs;
    end
end


%integrate segment lengths
%Gauss Legendre 16: integrate on [0,1]
LEN_QUAD_T = [0.0052995325041750333469603 0.0277124884633837102743126 0.0671843988060841224019271 0.1222977958224984867952045 0.1910618777986781147149031 0.2709916111713863151599924 0.3591982246103705422868302 0.4524937450811812866824368 0.5475062549188187688287144 0.6408017753896294577131698 0.7290083888286137403511589 0.8089381222013218852850969 0.8777022041775015548381589 0.9328156011939158220869217 0.9722875115366163001340283 0.9947004674958249692551249]';
LEN_QUAD_W = [0.0135762297058770482066636 0.0311267619693239468159351 0.0475792558412463928441127 0.0623144856277669384470030 0.0747979944082883679845608 0.0845782596975012679330064 0.0913017075224617918882686 0.0947253052275342510846201 0.0947253052275342510846201 0.0913017075224617918882686 0.0845782596975012679330064 0.0747979944082883679845608 0.0623144856277669384470030 0.0475792558412463928441127 0.0311267619693239468159351 0.0135762297058770482066636]';


%how long is the segment between index k and k+1? This will give good
%initial guesses for where to match points to lengths
v_seglens = zeros(v_pts - 1, 1);

for k = 1:(v_pts-1)
    if mode == 1 && mode_M == 1 %trivial case: linear
        v_seglens(k) = sqrt(sum((V(:,k+1) - V(:,k)).^2));
    elseif mode == 0 %spline; a bit more difficult; derivative of poly
        derivs = squeeze(v_spline(:,k,1:3)) * ((LEN_QUAD_T.^(2:-1:0))' .* (3:-1:1)');
        v_seglens(k) = dot(LEN_QUAD_W, vecnorm(derivs,2,1));
    elseif mode==1 %general sliding segments
        sld_pos = max(1, min(v_pts - sld_seg.M, k - floor(sld_seg.M/2)));
        sld_off = k - sld_pos;
        derivs = ((sld_off + LEN_QUAD_T).^(0:sld_seg.M-1) * sld_seg.Lagrange_prime') * V(:,sld_pos:(sld_pos + sld_seg.M))';
        v_seglens(k) = dot(LEN_QUAD_W, vecnorm(derivs,2,2));
    end
end
end

