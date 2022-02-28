% Copyright 2018 Mark Debord <mjay.debord@gmail.com> GPLv3 (License.txt)
function xnext = logistic_map(r,x)
% Computes the logistic map at a given state x and multiplier r
% https://en.wikipedia.org/wiki/Logistic_map
    xnext = r.*x.*(1 - x);
end