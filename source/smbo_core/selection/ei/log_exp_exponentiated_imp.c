#include "mex.h"
#include <math.h>

#if !defined(MAX)
#define	MAX(A, B)	((A) > (B) ? (A) : (B))
#endif

#if !defined(MIN)
#define	MIN(A, B)	((A) < (B) ? (A) : (B))
#endif

void printMatrixDouble(const double* X,int nRows, int nCols)
{
    int i,j;
    
    for(i = 0; i < nRows; i++) {
        printf("< ");
        for(j = 0; j < nCols; j++) {
            printf("%lf ",X[i+nRows*j]);
        }
        printf(">\n");
    }
}

void printMatrixInt(int* X,int nRows, int nCols)
{
    int i,j;
    
    for(i = 0; i < nRows; i++) {
        printf("< ");
        for(j = 0; j < nCols; j++) {
            printf("%d ",X[i+nRows*j]);}
        printf(">\n");}
}

/* Approximation of Normal CDF from http://www.sitmo.com/doc/Calculating_the_Cumulative_Normal_Distribution */
double normcdf(const double x)
{
    const double b1 =  0.319381530;
    const double b2 = -0.356563782;
    const double b3 =  1.781477937;
    const double b4 = -1.821255978;
    const double b5 =  1.330274429;
    const double p  =  0.2316419;
    const double c  =  0.39894228;

    if(x >= 0.0) {
        double t = 1.0 / ( 1.0 + p * x );
        return (1.0 - c * exp( -x * x / 2.0 ) * t * ( t *( t * ( t * ( t * b5 + b4 ) + b3 ) + b2 ) + b1 ));
    } else {
        double t = 1.0 / ( 1.0 - p * x );
        return ( c * exp( -x * x / 2.0 ) * t * ( t *( t * ( t * ( t * b5 + b4 ) + b3 ) + b2 ) + b1 ));
    }
}

/* Compute log of normal cumulative density function.
 * Translated and shortened from Tom Minka's Matlab lightspeed 
 * implementation by Frank Hutter.
 * More accurate than log(normcdf(x)) when x is small.
 * The following is a quick and dirty approximation to normcdfln:
 * normcdfln(x) =approx -(log(1+exp(0.88-x))/1.5)^2 */
double normcdfln(const double x){
    double y, z, pi = 3.14159265358979323846264338327950288419716939937510;
    if( x > -6.5 ){
        return log( normcdf(x) );
    }
    z = pow(x, -2);
/*    c = [-1 5/2 -37/3 353/4 -4081/5 55205/6 -854197/7];
    y = z.*(c(1)+z.*(c(2)+z.*(c(3)+z.*(c(4)+z.*(c(5)+z.*(c(6)+z.*c(7)))))));*/
    y = z*(-1+z*(5.0/2+z*(-37.0/3+z*(353.0/4+z*(-4081.0/5+z*(55205.0/6+z*-854197.0/7))))));
    return y - 0.5*log(2*pi) - 0.5*x*x - log(-x);
}


/* Univariate Normal PDF */
double normpdf(const double x)
{
    double pi = 3.14159265358979323846264338327950288419716939937510;
    return 1/sqrt(2*pi) * exp(-x*x/2);
}

/* Compute negative EI for Gaussians, lower-bounded by zero */
void log_exp_exponentiated_imp( const int numSamples, const int numMus, const double* fmin_samples, const double* mus, const double* sigmas, double* log_expEI ){
    int i,s;
    double cdfln_1, cdfln_2, c, d;
    /* Formula from .m file: 
     *  c = f_min + normcdfln((f_min-mu(i))/sigma(i));
     *  d = (sigma(i)^2/2 + mu(i)) + normcdfln((f_min-mu(i))/sigma(i) - sigma(i));*/

    if (numSamples > 1){
        mexErrMsgTxt("log_exp_exponentiated_imp not yet implemented for numSamples>1; can do that based on logsumexp trick.");
    }

    for (i=0; i<numMus; i++){
        log_expEI[i] = 0;        
        
        for (s=0; s<numSamples; s++){
            cdfln_1 = normcdfln((fmin_samples[s]-mus[i])/sigmas[i]);
            cdfln_2 = normcdfln((fmin_samples[s]-mus[i])/sigmas[i] - sigmas[i]);
            c = fmin_samples[s] + cdfln_1;
            d = (sigmas[i]*sigmas[i]/2 + mus[i]) + cdfln_2;
            if (c<=d){
/*                if (c < d-1e-6){
                    printf("c=%lf, d=%lf\n", c, d);
                    mexErrMsgTxt("Error -- due to approx. errors with normcdfln?");
                } else {*/
                    log_expEI[i] = d;
/*                }*/
            } else {
                log_expEI[i] = d + log(exp(c-d)-1); /* for multiple samples, would collect these values in array, and then apply logsumexp */
            }
        }
    }
}

void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
    int numMus, numSamples, mrows, ncols;
    double *fmin_samples, *mus, *sigmas, *log_expEI;
    int dims[2];
    
    /* Check for proper number of arguments. */
    if(nrhs!=3 || nlhs != 1) {
        mexErrMsgTxt("Usage: log_expEI = log_exp_exponentiated_imp( fmin_samples, mus, sigmas ).");
    }

    /* Check each argument for proper form and dimensions. */
    numSamples = mxGetM(prhs[0]);
    ncols = mxGetN(prhs[0]);
    if( !mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) || !(ncols==1) ) {
        mexErrMsgTxt("fmin_samples must be a noncomplex double column vector.");
    }
    fmin_samples = mxGetPr(prhs[0]);

    numMus = mxGetM(prhs[1]);
    ncols = mxGetN(prhs[1]);
    if( !mxIsDouble(prhs[1]) || mxIsComplex(prhs[1]) || !(ncols==1) ) {
        mexErrMsgTxt("mus must be a noncomplex double column vector.");
    }
    mus = mxGetPr(prhs[1]);

    mrows = mxGetM(prhs[2]);
    ncols = mxGetN(prhs[2]);
    if( !mxIsDouble(prhs[2]) || mxIsComplex(prhs[2]) || !(ncols==1) || !(mrows==numMus)) {
        mexErrMsgTxt("sigmas must be a noncomplex double column vector.");
    }
    sigmas = mxGetPr(prhs[2]);
    
    /* Outputs */
    dims[0] = numMus;
    dims[1] = 1;

    plhs[0] = mxCreateNumericArray(2, dims, mxDOUBLE_CLASS, mxREAL);
    log_expEI = mxGetPr(plhs[0]);
    
    /* Do the actual work. */
    log_exp_exponentiated_imp( numSamples, numMus, fmin_samples, mus, sigmas, log_expEI );
}