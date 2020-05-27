function test_spm_glass

Z = [1 1 4 3];
XYZmm = [40 38 6;-40 38 6;5 -75 6;-45 -23 41];

h = spm_glass(Z, XYZmm); close(h);

h = spm_glass(Z, XYZmm, struct('brush',5)); close(h);

h = spm_glass(Z, XYZmm, struct('cmap','hot')); close(h);

h = spm_glass(Z, XYZmm, struct('dark',true)); close(h);

h = spm_glass(Z, XYZmm, struct('detail',0)); close(h);
h = spm_glass(Z, XYZmm, struct('detail',2)); close(h);

h = spm_glass(Z, XYZmm, struct('grid',true)); close(h);
