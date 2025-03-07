***create dataset with 10 individuals in each of 100 practices (1000 individuals in total) 

clear 

set obs 1000

gen id = _n 

egen prac = seq(), from(1) to (100) block(10) 

  

***positive cases randomly distributed 

gen sim90=uniform()<0.9 

*simple proportion in sample of 100 

proportion sim90 if id <= 100, citype(exact) 

*accounting for clustering by practice in sample of 100 

proportion sim90 if id <= 100, vce(cluster prac) citype(exact) 

***positive cases clustered by practice 

gen sim90_clust = . 

forvalues prac = 1/100 { 

*local for random number between 0.7 and 0.9 

local prop = runiform(0.7,0.9) 

di `prop' 

*random proportion of 0.7 to 0.9 per practice 

replace sim90_clust = uniform()<`prop' if prac == `prac' 

} 

   

*accounting for clustering by practice 

proportion sim90_clust if id <= 100, vce(cluster prac) citype(exact) 
proportion sim90_clust if id <= 150, vce(cluster prac) citype(exact) 
