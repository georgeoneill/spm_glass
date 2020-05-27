function test_spm_glass

spm defaults eeg

h = spm_glass([1 2 4],[10 20 30;-5 12 35;6 -5 40]);
