/* w_ham_dist - a mex function to compute a matrix of all pairwise weighted
   Hamming distances between two sets of vectors, stored in the columns of the two 
   matrices that are arguments to the function. The length of the vectors must
   agree. If the second vector is empty, it is taken to be identical to the first. 
   The third argument is a length scale for each dimension, in particular
   the squared inverse weight for each dimension.

   Frank Hutter, Dec 19, 2007
   Adapted from Carl Rasmussen's sq_dist.c */
 
#include "mex.h"
#include <math.h>
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  double *a, *b, *C, *w, z, t, eps=0.001;
  int    D, n, m, i, j, k;
  if (nrhs < 3 || nlhs > 1)
    mexErrMsgTxt("Usage: C = w_ham_dist(a,b,l), where the b matrix may be empty.");
  a = mxGetPr(prhs[0]);
  m = mxGetN(prhs[0]);
  D = mxGetM(prhs[0]);
  if (mxIsEmpty(prhs[1])) {
    b = a;
    n = m;
  } else {
    b = mxGetPr(prhs[1]);
    n = mxGetN(prhs[1]);
    if (D != mxGetM(prhs[1]))
      mexErrMsgTxt("Error: column lengths must agree");
  }

  w = mxGetPr(prhs[2]);
  if (D != mxGetM(prhs[2]) || 1 != mxGetN(prhs[2])){
    printf("Length scale vector is %d by %d (not %d by 1)", mxGetM(prhs[2]), mxGetN(prhs[2]), D);
    mexErrMsgTxt("Error: length scale vector must be D by 1");
  }
  for (i=0; i<D; i++) {w[i] = 1.0/(w[i]*w[i]);}

  plhs[0] = mxCreateDoubleMatrix(m, n, mxREAL);
  C = mxGetPr(plhs[0]);
  for (i=0; i<m; i++) for (j=0; j<n; j++) {
	z = 0.0;
	for (k=0; k<D; k++) {
      z += w[k]*(1- ((a[D*i+k] < b[D*j+k]+eps) && (a[D*i+k] > b[D*j+k]-eps)) );
    }
	C[i+j*m] = z;
  }
}
