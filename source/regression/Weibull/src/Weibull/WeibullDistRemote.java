/*
 * MATLAB Compiler: 4.13 (R2010a)
 * Date: Mon Jul 18 16:18:35 2011
 * Arguments: "-B" "macro_default" "-W" "java:Weibull,WeibullDist" "-T" "link:lib" "-d" 
 * "/ubc/cs/project/arrow/hutter/altuning/matlab/AClion_for_Jon/regression/javaregtrees/Weibull/src" 
 * "-w" "enable:specified_file_mismatch" "-w" "enable:repeated_file" "-w" 
 * "enable:switch_ignored" "-w" "enable:missing_lib_sentinel" "-w" "enable:demo_license" 
 * "-v" 
 * "class{WeibullDist:/cs/local/generic/lib/pkg/matlab-7.10/toolbox/stats/wblcdf.m,/cs/local/generic/lib/pkg/matlab-7.10/toolbox/stats/wblfit.m,/cs/local/generic/lib/pkg/matlab-7.10/toolbox/stats/wblinv.m,/cs/local/generic/lib/pkg/matlab-7.10/toolbox/stats/wblrnd.m}" 
 */

package Weibull;

import com.mathworks.toolbox.javabuilder.pooling.Poolable;
import java.util.List;
import java.rmi.Remote;
import java.rmi.RemoteException;

/**
 * The <code>WeibullDistRemote</code> class provides a Java RMI-compliant interface to 
 * the M-functions from the files:
 * <pre>
 *  /cs/local/generic/lib/pkg/matlab-7.10/toolbox/stats/wblcdf.m
 *  /cs/local/generic/lib/pkg/matlab-7.10/toolbox/stats/wblfit.m
 *  /cs/local/generic/lib/pkg/matlab-7.10/toolbox/stats/wblinv.m
 *  /cs/local/generic/lib/pkg/matlab-7.10/toolbox/stats/wblrnd.m
 * </pre>
 * The {@link #dispose} method <b>must</b> be called on a <code>WeibullDistRemote</code> 
 * instance when it is no longer needed to ensure that native resources allocated by this 
 * class are properly freed, and the server-side proxy is unexported.  (Failure to call 
 * dispose may result in server-side threads not being properly shut down, which often 
 * appears as a hang.)  
 *
 * This interface is designed to be used together with 
 * <code>com.mathworks.toolbox.javabuilder.remoting.RemoteProxy</code> to automatically 
 * generate RMI server proxy objects for instances of Weibull.WeibullDist.
 */
public interface WeibullDistRemote extends Poolable
{
    /**
     * Provides the standard interface for calling the <code>wblcdf</code> M-function 
     * with 5 input arguments.  
     *
     * Input arguments to standard interface methods may be passed as sub-classes of 
     * <code>com.mathworks.toolbox.javabuilder.MWArray</code>, or as arrays of any 
     * supported Java type (i.e. scalars and multidimensional arrays of any numeric, 
     * boolean, or character type, or String). Arguments passed as Java types are 
     * converted to MATLAB arrays according to default conversion rules.
     *
     * All inputs to this method must implement either Serializable (pass-by-value) or 
     * Remote (pass-by-reference) as per the RMI specification.
     *
     * M-documentation as provided by the author of the M function:
     * <pre>
     * %WBLCDF Weibull cumulative distribution function (cdf).
     * %   P = WBLCDF(X,A,B) returns the cdf of the Weibull distribution
     * %   with scale parameter A and shape parameter B, evaluated at the
     * %   values in X.  The size of P is the common size of the input arguments.
     * %   A scalar input functions as a constant matrix of the same size as the
     * %   other inputs.
     * %
     * %   Default values for A and B are 1 and 1, respectively.
     * %
     * %   [P,PLO,PUP] = WBLCDF(X,A,B,PCOV,ALPHA) produces confidence
     * %   bounds for P when the input parameters A and B are estimates.
     * %   PCOV is a 2-by-2 matrix containing the covariance matrix of the estimated
     * %   parameters.  ALPHA has a default value of 0.05, and specifies
     * %   100*(1-ALPHA)% confidence bounds.  PLO and PUP are arrays of the same
     * %   size as P containing the lower and upper confidence bounds.
     * %
     * %   See also CDF, WBLFIT, WBLINV, WBLLIKE, WBLPDF, WBLRND, WBLSTAT.
     * </pre>
     *
     * @param nargout Number of outputs to return.
     * @param rhs The inputs to the M function.
     *
     * @return Array of length nargout containing the function outputs. Outputs are 
     * returned as sub-classes of <code>com.mathworks.toolbox.javabuilder.MWArray</code>. 
     * Each output array should be freed by calling its <code>dispose()</code> method.
     *
     * @throws java.jmi.RemoteException An error has occurred during the function call or 
     * in communication with the server.
     */
    public Object[] wblcdf(int nargout, Object... rhs) throws RemoteException;
    /**
     * Provides the standard interface for calling the <code>wblfit</code> M-function 
     * with 5 input arguments.  
     *
     * Input arguments to standard interface methods may be passed as sub-classes of 
     * <code>com.mathworks.toolbox.javabuilder.MWArray</code>, or as arrays of any 
     * supported Java type (i.e. scalars and multidimensional arrays of any numeric, 
     * boolean, or character type, or String). Arguments passed as Java types are 
     * converted to MATLAB arrays according to default conversion rules.
     *
     * All inputs to this method must implement either Serializable (pass-by-value) or 
     * Remote (pass-by-reference) as per the RMI specification.
     *
     * M-documentation as provided by the author of the M function:
     * <pre>
     * %WBLFIT Parameter estimates and confidence intervals for Weibull data.
     * %   PARMHAT = WBLFIT(X) returns maximum likelihood estimates of the
     * %   parameters of the Weibull distribution given the data in X.  PARMHAT(1)
     * %   is the scale parameter, A, and PARMHAT(2) is the shape parameter, B.
     * %
     * %   [PARMHAT,PARMCI] = WBLFIT(X) returns 95% confidence intervals for the
     * %   parameter estimates.
     * %
     * %   [PARMHAT,PARMCI] = WBLFIT(X,ALPHA) returns 100(1-ALPHA) percent
     * %   confidence intervals for the parameter estimates.
     * %
     * %   [...] = WBLFIT(X,ALPHA,CENSORING) accepts a boolean vector of the same
     * %   size as X that is 1 for observations that are right-censored and 0 for
     * %   observations that are observed exactly.
     * %
     * %   [...] = WBLFIT(X,ALPHA,CENSORING,FREQ) accepts a frequency vector of
     * %   the same size as X.  FREQ typically contains integer frequencies for
     * %   the corresponding elements in X, but may contain any non-integer
     * %   non-negative values.
     * %
     * %   [...] = WBLFIT(X,ALPHA,CENSORING,FREQ,OPTIONS) specifies control
     * %   parameters for the iterative algorithm used to compute ML estimates.
     * %   This argument can be created by a call to STATSET.  See STATSET('wblfit')
     * %   for parameter names and default values.
     * %
     * %   Pass in [] for ALPHA, CENSORING, or FREQ to use their default values.
     * %
     * %   See also WBLCDF, WBLINV, WBLLIKE, WBLPDF, WBLRND, WBLSTAT, MLE,
     * %   STATSET.
     * </pre>
     *
     * @param nargout Number of outputs to return.
     * @param rhs The inputs to the M function.
     *
     * @return Array of length nargout containing the function outputs. Outputs are 
     * returned as sub-classes of <code>com.mathworks.toolbox.javabuilder.MWArray</code>. 
     * Each output array should be freed by calling its <code>dispose()</code> method.
     *
     * @throws java.jmi.RemoteException An error has occurred during the function call or 
     * in communication with the server.
     */
    public Object[] wblfit(int nargout, Object... rhs) throws RemoteException;
    /**
     * Provides the standard interface for calling the <code>wblinv</code> M-function 
     * with 5 input arguments.  
     *
     * Input arguments to standard interface methods may be passed as sub-classes of 
     * <code>com.mathworks.toolbox.javabuilder.MWArray</code>, or as arrays of any 
     * supported Java type (i.e. scalars and multidimensional arrays of any numeric, 
     * boolean, or character type, or String). Arguments passed as Java types are 
     * converted to MATLAB arrays according to default conversion rules.
     *
     * All inputs to this method must implement either Serializable (pass-by-value) or 
     * Remote (pass-by-reference) as per the RMI specification.
     *
     * M-documentation as provided by the author of the M function:
     * <pre>
     * %WBLINV Inverse of the Weibull cumulative distribution function (cdf).
     * %   X = WBLINV(P,A,B) returns the inverse cdf for a Weibull
     * %   distribution with scale parameter A and shape parameter B,
     * %   evaluated at the values in P.  The size of X is the common size of the
     * %   input arguments.  A scalar input functions as a constant matrix of the
     * %   same size as the other inputs.
     * %   
     * %   Default values for A and B are 1 and 1, respectively.
     * %
     * %   [X,XLO,XUP] = WBLINV(P,A,B,PCOV,ALPHA) produces confidence
     * %   bounds for X when the input parameters A and B are estimates.
     * %   PCOV is a 2-by-2 matrix containing the covariance matrix of the estimated
     * %   parameters.  ALPHA has a default value of 0.05, and specifies
     * %   100*(1-ALPHA)% confidence bounds.  XLO and XUP are arrays of the same
     * %   size as X containing the lower and upper confidence bounds.
     * %
     * %   See also WBLCDF, WBLFIT, WBLLIKE, WBLPDF, WBLRND, WBLSTAT, ICDF.
     * </pre>
     *
     * @param nargout Number of outputs to return.
     * @param rhs The inputs to the M function.
     *
     * @return Array of length nargout containing the function outputs. Outputs are 
     * returned as sub-classes of <code>com.mathworks.toolbox.javabuilder.MWArray</code>. 
     * Each output array should be freed by calling its <code>dispose()</code> method.
     *
     * @throws java.jmi.RemoteException An error has occurred during the function call or 
     * in communication with the server.
     */
    public Object[] wblinv(int nargout, Object... rhs) throws RemoteException;
    /**
     * Provides the standard interface for calling the <code>wblrnd</code> M-function 
     * with 3 input arguments.  
     *
     * Input arguments to standard interface methods may be passed as sub-classes of 
     * <code>com.mathworks.toolbox.javabuilder.MWArray</code>, or as arrays of any 
     * supported Java type (i.e. scalars and multidimensional arrays of any numeric, 
     * boolean, or character type, or String). Arguments passed as Java types are 
     * converted to MATLAB arrays according to default conversion rules.
     *
     * All inputs to this method must implement either Serializable (pass-by-value) or 
     * Remote (pass-by-reference) as per the RMI specification.
     *
     * M-documentation as provided by the author of the M function:
     * <pre>
     * %WBLRND Random arrays from the Weibull distribution.
     * %   R = WBLRND(A,B) returns an array of random numbers chosen from the
     * %   Weibull distribution with scale parameter A and shape parameter B.  The
     * %   size of R is the common size of A and B if both are arrays.  If either
     * %   parameter is a scalar, the size of R is the size of the other
     * %   parameter.
     * %
     * %   R = WBLRND(A,B,M,N,...) or  R = WBLRND(A,B,[M,N,...]) returns an
     * %   M-by-N-by-... array.
     * %
     * %   See also WBLCDF, WBLFIT, WBLINV, WBLLIKE, WBLPDF, WBLSTAT, RANDOM.
     * </pre>
     *
     * @param nargout Number of outputs to return.
     * @param rhs The inputs to the M function.
     *
     * @return Array of length nargout containing the function outputs. Outputs are 
     * returned as sub-classes of <code>com.mathworks.toolbox.javabuilder.MWArray</code>. 
     * Each output array should be freed by calling its <code>dispose()</code> method.
     *
     * @throws java.jmi.RemoteException An error has occurred during the function call or 
     * in communication with the server.
     */
    public Object[] wblrnd(int nargout, Object... rhs) throws RemoteException;
  
    /** Frees native resources associated with the remote server object */
    void dispose() throws RemoteException;
}
